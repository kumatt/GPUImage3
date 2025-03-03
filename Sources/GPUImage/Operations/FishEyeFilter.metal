#include <metal_stdlib>
#include "OperationShaderTypes.h"
using namespace metal;

typedef struct
{
    float strength;
} FisheyeFragmentUniform;

// 片段着色器 - 实现鱼眼效果
fragment float4 fisheyeFragment(TwoInputVertexIO fragmentInput [[stage_in]],
                               texture2d<float> inputTexture [[texture(0)]],
                               constant FisheyeFragmentUniform &uniform [[buffer(1)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    // 将纹理坐标归一化到 [-1, 1] 范围，中心为 (0,0)
    float2 normalizedCoord = fragmentInput.textureCoordinate * 2.0 - 1.0;
    
    // 计算到中心的距离
    float r = length(normalizedCoord);
    
    // 应用鱼眼变形
    float theta = atan2(normalizedCoord.y, normalizedCoord.x);
    float radius = pow(r, uniform.strength);
    
    // 确保不超出边界
    radius = min(radius, 1.0);
    
    // 转换回笛卡尔坐标
    float2 distortedCoord;
    distortedCoord.x = radius * cos(theta);
    distortedCoord.y = radius * sin(theta);
    
    // 转换回纹理坐标 [0, 1]
    distortedCoord = (distortedCoord + 1.0) * 0.5;
    
    // 采样纹理
    if (distortedCoord.x >= 0.0 && distortedCoord.x <= 1.0 &&
        distortedCoord.y >= 0.0 && distortedCoord.y <= 1.0) {
        return inputTexture.sample(textureSampler, distortedCoord);
    } else {
        // 边缘处理 - 显示黑色
        return float4(0, 0, 0, 1);
    }
}
