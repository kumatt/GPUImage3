//
//  FishEyeFilter.swift
//  GPUImage
//
//  Created by kumatt on 2025/2/25.
//

public class FishEyeFilter: BasicOperation {
    public var strength: Float = 1.0 { didSet { uniformSettings["strength"] = strength } }

    public init() {
        super.init(fragmentFunctionName: "fisheyeFragment", numberOfInputs: 1)

        ({ strength = 1.0 })()
    }
}
