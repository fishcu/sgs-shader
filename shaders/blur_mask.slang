#version 450

#include "parameters.inc"
#include "blur_horiz.slang.inc"

layout(push_constant) uniform Push {
    vec4 OutputSize;
    vec4 OriginalSize;
    vec4 SourceSize;
    uint FrameCount;
    float MASK_PATTERN_SIZE;
    float MASK_FINENESS;
    float MASK_BLUR;
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

    const int num_mask_groups = int(mix(1, int(param.MASK_PATTERN_SIZE) / 2, param.MASK_FINENESS));
    const float average_group_width = param.MASK_PATTERN_SIZE / num_mask_groups;
    compute_blur_kernel(blur_kernel, param.MASK_BLUR * average_group_width, 0.0f);
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 2) flat in vec4 blur_kernel[_BLUR_KERNEL_SIZE / 4];
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 1) uniform sampler2D Source;

void main() {
    const int num_mask_groups = int(mix(1, int(param.MASK_PATTERN_SIZE) / 2, param.MASK_FINENESS));
    const float average_group_width = param.MASK_PATTERN_SIZE / num_mask_groups;
    const float iteration_radius = 1.6f * param.MASK_BLUR * average_group_width;

    vec4 res = {0.0f, 0.0f, 0.0f, 1.0f};
    for(int i = 0; i < _BLUR_KERNEL_SIZE; ++i) {
        const float x = iteration_radius * (float(i) / (_BLUR_KERNEL_SIZE - 1) * 2.0f - 1.0f);
        const int outer = i / 4;
        const int inner = i % 4;
        res += texture(Source, vTexCoord + vec2(x * param.SourceSize.z, 0.0f)) * blur_kernel[outer][inner];
    }
    
    FragColor = res;
}
