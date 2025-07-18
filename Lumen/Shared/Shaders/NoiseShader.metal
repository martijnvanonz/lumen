#include <metal_stdlib>
using namespace metal;

/// Animated noise shader for gradient background
/// Creates subtle animated noise texture that blends with the gradient
[[ stitchable ]]
half4 noiseShader(float2 position, half4 color, float2 size, float time) {
    // Normalize position to UV coordinates (0-1)
    float2 uv = position / size;
    
    // Create animated noise using time-based offset (subtle but visible)
    float2 animatedUV = uv + time * 0.1;
    
    // Generate pseudo-random noise using dot product and sine
    float noise = fract(sin(dot(animatedUV, float2(12.9898, 78.233))) * 43758.5453);
    
    // Add some variation with multiple octaves for more organic look
    float noise2 = fract(sin(dot(animatedUV * 2.0, float2(93.9898, 67.345))) * 23421.631);
    float noise3 = fract(sin(dot(animatedUV * 4.0, float2(41.2345, 89.123))) * 15739.428);
    
    // Combine noise octaves with different weights
    float finalNoise = noise * 0.5 + noise2 * 0.3 + noise3 * 0.2;
    
    // Return grayscale noise value
    return half4(finalNoise, finalNoise, finalNoise, 1.0);
}
