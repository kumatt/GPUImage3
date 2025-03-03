public class MultiplyBlendAndOpacity: BasicOperation {
    
    public var opacity: Float = 1 {
        didSet {
            uniformSettings["opacity"] = opacity
        }
    }

    public init() {
        super.init(fragmentFunctionName: "multiplyBlendAndOpacityFragment", numberOfInputs: 2)
    }
}
