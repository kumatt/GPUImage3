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
    
    @IBAction func Save(_ sender: Any) {
        saveRenderTextureToPhotoLibrary()
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

extension FilterShowcaseWindowController {
    
    func saveCGImage(_ cgImage: CGImage) {
        // 创建 NSSavePanel 让用户选择保存路径
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "SavedImage.png"
        savePanel.allowedFileTypes = ["png"]
        
        savePanel.begin { result in
            guard result == .OK, let url = savePanel.url else {
                print("用户取消保存")
                return
            }
            
            // 指定图片类型为 PNG
            let imageType: CFString
            if #available(macOS 11.0, *) {
                imageType = UTType.png.identifier as CFString
            } else {
                imageType = kUTTypePNG
            }
            
            // 创建 CGImageDestination 对象
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, imageType, 1, nil) else {
                print("无法创建 CGImageDestination")
                return
            }
            
            // 将 CGImage 添加到 destination 中
            CGImageDestinationAddImage(destination, cgImage, nil)
            
            // 完成写入，保存图片
            if CGImageDestinationFinalize(destination) {
                print("图片保存成功，路径：\(url.path)")
            } else {
                print("图片保存失败")
            }
        }
    }
    
    // 假设 renderView 是你的 RenderView 实例
    // 假设 finalTexture 是从 RenderView 获取的 MTLTexture
    @objc func saveRenderTextureToPhotoLibrary() {
        FilterShowcaseWindowController.inputImage.processImage()
        guard let texture = filterView?.currentDrawable?.texture else {
            return
        }
        
        // 创建一个 CIImage
        // 使用 Core Image 转换图像，并应用方向调整
        let ciImage = CIImage(mtlTexture: texture, options: nil)!.oriented(.downMirrored)
        let context = CIContext(options: [kCIContextWorkingColorSpace: CGColorSpaceCreateDeviceRGB()])

        // 创建一个 CIContext
//        let context = CIContext()
        
        // 创建一个 CGImage
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to create CGImage")
            return
        }
        
        saveCGImage(cgImage)
//        // 将 CGImage 转换为 UIImage
//        let image = UIImage(cgImage: cgImage)
//
//        // 保存 UIImage 到相册
//        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

