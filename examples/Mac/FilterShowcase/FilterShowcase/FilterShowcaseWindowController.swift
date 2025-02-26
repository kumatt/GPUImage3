import AVFoundation
import Cocoa
import GPUImage
import Combine

let blendImageName = "Lambeau.jpg"

class FilterShowcaseWindowController: NSWindowController {
    
    static var inputImage: PictureInput = PictureInput(imageName: "WID-small")
    static var blendImage: PictureInput = PictureInput(imageName: blendImageName)
    static var blendImageOrigin = NSImage(named: NSImage.Name(rawValue: blendImageName))

    @IBOutlet var filterView: RenderView!

    @IBOutlet weak var filterSlider: NSSlider!


    @IBOutlet weak var backCoverView: NSImageView!
    @IBOutlet weak var filterValueLabel: NSTextField!
    @objc dynamic var currentSliderValue: Float = 0.5 {
        willSet(newSliderValue) {
            switch currentFilterOperation!.sliderConfiguration {
            case .enabled: currentFilterOperation!.updateBasedOnSliderValue(newSliderValue)
                FilterShowcaseWindowController.inputImage.processImage()
                filterValueLabel.stringValue = "\(newSliderValue)"
            case .disabled: break
            }
        }
    }

    var currentFilterOperation: FilterOperationInterface?
//    var videoCamera: Camera!

    var currentlySelectedRow = 1
    
    var cancellables = Set<AnyCancellable>()

    override func windowDidLoad() {
        super.windowDidLoad()
        backCoverView.image = FilterShowcaseWindowController.blendImageOrigin
        let imageDropView = ImageDropView()
        imageDropView.frame = filterView.bounds
        filterView.addSubview(imageDropView)
        imageDropView.$image.sink {[weak self] image in
            guard let self, let image, let width = window?.frame.width else { return }
            
            if let filterView {
                filterView.bounds = CGRect(origin: .zero, size: CGSize(width: 500, height: 500 / image.size.width * image.size.height))
            }

            FilterShowcaseWindowController.inputImage.removeAllTargets()
            FilterShowcaseWindowController.inputImage = PictureInput(image: image)
            changeSelectedRow(currentlySelectedRow)
            FilterShowcaseWindowController.inputImage.processImage()
        }
        .store(in: &cancellables)
        
        let backImageDropView = ImageDropView()
        backImageDropView.frame = backCoverView.bounds
        backCoverView.addSubview(backImageDropView)
        backImageDropView.$image.sink {[weak self] image in
            guard let self, let image, let width = window?.frame.width else { return }
            
            if let filterView {
                filterView.bounds = CGRect(origin: .zero, size: CGSize(width: 500, height: 500 / image.size.width * image.size.height))
            }

            FilterShowcaseWindowController.blendImage.removeAllTargets()
            FilterShowcaseWindowController.blendImage = PictureInput(image: image)
            FilterShowcaseWindowController.blendImageOrigin = image
            backCoverView.image = image
            changeSelectedRow(currentlySelectedRow)
            FilterShowcaseWindowController.inputImage.processImage()
        }
        .store(in: &cancellables)

//        do {
//            videoCamera = try Camera(sessionPreset: .hd1280x720, location: .frontFacing)
//            videoCamera.runBenchmark = true
//            videoCamera.startCapture()
//        } catch {
//            fatalError("Couldn't initialize camera with error: \(error)")
//        }
        self.changeSelectedRow(0)
    }

    func changeSelectedRow(_ row: Int) {
//        guard currentlySelectedRow != row else { return }
        currentlySelectedRow = row

        // Clean up everything from the previous filter selection first
        //        videoCamera.stopCapture()
//        videoCamera.removeAllTargets()
        FilterShowcaseWindowController.inputImage.removeAllTargets()
        currentFilterOperation?.filter.removeAllTargets()
        currentFilterOperation?.secondInput?.removeAllTargets()

        currentFilterOperation = filterOperations[row]
        switch currentFilterOperation!.filterOperationType {
        case .singleInput:
            FilterShowcaseWindowController.inputImage.addTarget((currentFilterOperation!.filter))
//            videoCamera.addTarget((currentFilterOperation!.filter))
            currentFilterOperation!.filter.addTarget(filterView!)
        case .blend:
            FilterShowcaseWindowController.blendImage.removeAllTargets()
            FilterShowcaseWindowController.inputImage.addTarget((currentFilterOperation!.filter))
//            videoCamera.addTarget((currentFilterOperation!.filter))
            FilterShowcaseWindowController.blendImage.addTarget((currentFilterOperation!.filter))
            currentFilterOperation!.filter.addTarget(filterView!)
            FilterShowcaseWindowController.blendImage.processImage()
        case let .custom(filterSetupFunction: setupFunction):
            break
//            currentFilterOperation!.configureCustomFilter(
//                setupFunction(videoCamera!, currentFilterOperation!.filter, filterView!))
        }

        switch currentFilterOperation!.sliderConfiguration {
        case .disabled:
            filterSlider.isEnabled = false
        //                case let .Enabled(minimumValue, initialValue, maximumValue, filterSliderCallback):
        case let .enabled(minimumValue, maximumValue, initialValue):
            filterSlider.minValue = Double(minimumValue)
            filterSlider.maxValue = Double(maximumValue)
            filterSlider.isEnabled = true
            currentSliderValue = initialValue
        }

        FilterShowcaseWindowController.inputImage.processImage()
//        videoCamera.startCapture()
    }

    // MARK: -
    // MARK: Table view delegate and datasource methods

    @objc func numberOfRowsInTableView(_ aTableView: NSTableView!) -> Int {
        return filterOperations.count
    }

    @objc func tableView(
        _ aTableView: NSTableView!, objectValueForTableColumn aTableColumn: NSTableColumn!,
        row rowIndex: Int
    ) -> AnyObject! {
        let filterInList: FilterOperationInterface = filterOperations[rowIndex]
        return filterInList.listName as NSString
    }

    @objc func tableViewSelectionDidChange(_ aNotification: Notification!) {
        if let currentTableView = aNotification.object as? NSTableView {
            let rowIndex = currentTableView.selectedRow
            self.changeSelectedRow(rowIndex)
        }
    }
}
