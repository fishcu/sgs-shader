#version 450

#include "common.inc"

layout(push_constant) uniform Push {
	vec4 OutputSize;
	vec4 OriginalSize;
	vec4 SourceSize;
	uint FrameCount;
    float BLUR_WIDTH;
    float OVERSHOOT_STRENGTH;
} param;

layout(std140, set = 0, binding = 0) uniform UBO {
   mat4 MVP;
} global;

#pragma parameter BLUR_WIDTH "BLUR_WIDTH: Horizontal blur in pixels" 0.25 0.0 4.0 0.05
#pragma parameter OVERSHOOT_STRENGTH "OVERSHOOT_STRENGTH: Overshooting & sharpening strength." 0.5 0.0 1.0 0.1

// More samples means fewer artifacts but decreased performance.
// The upper limit that does not crash RetroArch is 64.
#define _BLUR_KERNEL_SIZE 64

float gauss(float t, float sigma) {
    return exp(-t * t / (sigma * sigma + 1.e-8f));
}

float gauss_with_overshoot(float x, float main_sigma, float overshoot_strength) {
    return gauss(x, main_sigma) - gauss(x - main_sigma*0.8, main_sigma * 0.5) * overshoot_strength;
}

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 2) out vec4 blur_kernel[_BLUR_KERNEL_SIZE / 4];

void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;

    // Calculate kernel.
    // Sensible iteration radius is about 1.6 sigmas from the center.
    const vec2 source_to_output_scale = param.OutputSize.xy * param.SourceSize.zw;
    const float iteration_radius = 1.6f * param.BLUR_WIDTH;

    float kernel_sum = 0.0f;
    for(int i = 0; i < _BLUR_KERNEL_SIZE; ++i) {
        const float x = iteration_radius * (float(i) / (_BLUR_KERNEL_SIZE - 1) * 2.0f - 1.0f);
        // Invert the output index to have a simpler convolution iteration in the fragment shader.
        const int outer = (_BLUR_KERNEL_SIZE - i - 1) / 4;
        const int inner = (_BLUR_KERNEL_SIZE - i - 1) % 4;
        blur_kernel[outer][inner] = gauss_with_overshoot(x, param.BLUR_WIDTH, param.OVERSHOOT_STRENGTH);
        kernel_sum += blur_kernel[outer][inner];
    }

    if (kernel_sum > 1.e-8f) {
        for(int i = 0; i < _BLUR_KERNEL_SIZE; ++i) {
            const int outer = i / 4;
            const int inner = i % 4;
            blur_kernel[outer][inner] /= kernel_sum;
        }
    } else {
        // If kernel sum is near zero, set kernel to impulse (identity convolution)
        for(int i = 0; i < _BLUR_KERNEL_SIZE; ++i) {
            const int outer = i / 4;
            const int inner = i % 4;
            blur_kernel[outer][inner] = 0.0f;
        }
        const int idx = _BLUR_KERNEL_SIZE / 2;
        const int outer = idx / 4;
        const int inner = idx % 4;
        blur_kernel[outer][inner]  = 1.0f;
    }
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 2) flat in vec4 blur_kernel[_BLUR_KERNEL_SIZE / 4];
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 1) uniform sampler2D Source;

void main() {
    const vec2 source_to_output_scale = param.OutputSize.xy * param.SourceSize.zw;
    const float iteration_radius = 1.6f * param.BLUR_WIDTH;

    vec4 res = {0.0f, 0.0f, 0.0f, 1.0f};
    for(int i = 0; i < _BLUR_KERNEL_SIZE; ++i) {
        const float x = iteration_radius * (float(i) / (_BLUR_KERNEL_SIZE - 1) * 2.0f - 1.0f);
        const int outer = i / 4;
        const int inner = i % 4;
        res += texture(Source, vTexCoord + vec2(x * param.OriginalSize.z, 0.0f)) * blur_kernel[outer][inner];
    }
    
    FragColor = res;
}
