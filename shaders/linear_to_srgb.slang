#version 450

layout(push_constant) uniform Push {
    vec4 OutputSize;
    vec4 OriginalSize;
    vec4 SourceSize;
    uint FrameCount;
    float OUTPUT_GAMMA;
} param;

layout(std140, set = 0, binding = 0) uniform UBO {
    mat4 MVP;
} global;

#pragma parameter OUTPUT_GAMMA "OUTPUT_GAMMA: Output gamma." 2.4 1.0 3.4 0.1

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

float linear_to_srgb(float x) {
    const float rel_gamma = 1.0f / param.OUTPUT_GAMMA;
    return x <= 0.0031308 ?
        x * 12.92f :
        1.055f * pow(x, rel_gamma) - 0.055f;
}

void main() {
    const vec4 s = texture(Source, vTexCoord);
    FragColor = vec4(linear_to_srgb(s[0]), linear_to_srgb(s[1]), linear_to_srgb(s[2]), 1.0f);
}
