#version 450

#include "parameters.slang"
#include "blur_horiz.slang"

layout(push_constant) uniform Push {
    vec4 OutputSize;
    vec4 OriginalSize;
    vec4 SourceSize;
    uint FrameCount;
    float MASK_STRENGTH;
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

void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 1) uniform sampler2D Source;

void main() {
    const float num_mask_groups = floor(mix(1, int(param.MASK_PATTERN_SIZE) / 2, param.MASK_FINENESS));
    const float average_group_width = param.MASK_PATTERN_SIZE / num_mask_groups;
    blur_horiz(param.MASK_BLUR * average_group_width * param.OutputSize.z, 0.0f,
               param.SourceSize.z, Source, vTexCoord, FragColor);
}
