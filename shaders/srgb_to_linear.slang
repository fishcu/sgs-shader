#version 450

#include "parameters.slang"

layout(push_constant) uniform Push {
    vec4 OutputSize;
    vec4 OriginalSize;
    vec4 SourceSize;
    uint FrameCount;
    float BLACK_POINT;
}
param;

layout(std140, set = 0, binding = 0) uniform UBO {
    mat4 MVP;
}
global;

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
layout(set = 0, binding = 1) uniform sampler2D Original;

float srgb_to_linear(float x) {
    return x <= 0.04045 ? x * 0.0773993808 :           // = 1.0 / 12.92
               pow((x + 0.055) * 0.94786729857, 2.4);  // 0.94786729857 = 1.0 / 1.055
}

void main() {
    const vec4 s = texture(Original, vTexCoord);
    const float output_range = 1.0 - 0.1 * param.BLACK_POINT;
    FragColor = vec4(0.1 * param.BLACK_POINT + srgb_to_linear(s[0]) * output_range,
                     0.1 * param.BLACK_POINT + srgb_to_linear(s[1]) * output_range,
                     0.1 * param.BLACK_POINT + srgb_to_linear(s[2]) * output_range, 1.0);
}
