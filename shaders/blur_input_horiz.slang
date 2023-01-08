#version 450

#include "parameters.slang"
#include "blur_horiz.slang"

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

void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 1) uniform sampler2D Source;

void main() {
    blur_horiz(param.BLUR_WIDTH * param.OriginalSize.z, param.OVERSHOOT_STRENGTH,
               param.SourceSize.z, Source, vTexCoord, FragColor);

    // Prevent black point from being undercut.
    FragColor = max(0.1f * vec4(param.BLACK_POINT, param.BLACK_POINT, param.BLACK_POINT, 0.0f),
                    FragColor);
}
