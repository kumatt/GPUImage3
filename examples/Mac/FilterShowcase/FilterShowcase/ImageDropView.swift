import Cocoa
import Combine

@available(macOS 10.15, *)
class ImageDropView: NSView {
    
    @Published var image: NSImage?
    
    // MARK: - 初始化
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.registerForDraggedTypes([.fileURL, .tiff])
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.registerForDraggedTypes([.fileURL, .tiff])
    }
    
    // MARK: - NSDraggingDestination 方法
    
    // 当拖拽进入视图时调用
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        // 这里可以做进一步判断，比如检查拖入文件是否为图片
        return .copy
    }
    
    // 拖拽操作真正进行时调用
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard()
        
        // 优先尝试读取文件 URL（比如从 Finder 拖入）
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let fileURL = urls.first {
            // 检查文件扩展名或使用 UTType 判断是否为图片
            if ["png", "jpg", "jpeg", "tiff", "heic"].contains(fileURL.pathExtension.lowercased()),
               let image = NSImage(contentsOf: fileURL) {
                // 处理或显示图片
                print("获取到拖入的图片：\(image)")
                self.image = image
                return true
            }
        }
        
        // 如果拖入的是图片数据（例如从其他应用拖拽）
        if let tiffData = pasteboard.data(forType: .tiff),
           let image = NSImage(data: tiffData) {
            self.image = image
            return true
        }
        
        return false
    }
    
    // 可选：完成拖拽操作后调用
    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        // 可在此做一些清理或动画效果
    }
}
