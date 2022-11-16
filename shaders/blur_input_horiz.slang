#version 450

#include "parameters.inc"
#include "blur_horiz.slang.inc"

layout(push_constant) uniform Push {
    vec4 OutputSize;
    vec4 OriginalSize;
    vec4 SourceSize;
    uint FrameCount;
    float BLUR_WIDTH;
    float OVERSHOOT_STRENGTH;
    float BLACK_POINT;
} param;

layout(std140, set = 0, binding = 0) uniform UBO {
    mat4 MVP;
} global;

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 2) out vec4 blur_kernel[_BLUR_KERNEL_SIZE / 4];

void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;

    compute_blur_kernel(blur_kernel, param.BLUR_WIDTH, param.OVERSHOOT_STRENGTH);
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 2) flat in vec4 blur_kernel[_BLUR_KERNEL_SIZE / 4];
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 1) uniform sampler2D Source;

void main() {
    const float iteration_radius = 1.6f * param.BLUR_WIDTH;

    vec4 res = {0.0f, 0.0f, 0.0f, 1.0f};
    for(int i = 0; i < _BLUR_KERNEL_SIZE; ++i) {
        const float x = iteration_radius * (float(i) / (_BLUR_KERNEL_SIZE - 1) * 2.0f - 1.0f);
        const int outer = i / 4;
        const int inner = i % 4;
        res += texture(Source, vTexCoord + vec2(x * param.OriginalSize.z, 0.0f)) * blur_kernel[outer][inner];
    }

    res = max(0.1f * vec4(param.BLACK_POINT, param.BLACK_POINT, param.BLACK_POINT, 0.0f),
              res);
    
    FragColor = res;
}
