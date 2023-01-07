#version 450

#include "parameters.inc"

#pragma name ScanlineSignal

layout(push_constant) uniform Push {
    vec4 OutputSize;
    vec4 OriginalSize;
    vec4 SourceSize;
    uint FrameCount;
    float EROSION_WIDTH;
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
    FragColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);
    const float radius = param.EROSION_WIDTH * param.SourceSize.z * 0.5f;
    for(float sample_x = vTexCoord.x - radius; sample_x <= vTexCoord.x + radius; sample_x += param.OutputSize.z) {
        FragColor = min(FragColor, texture(Source, vec2(sample_x, vTexCoord.y)));
    }
}
