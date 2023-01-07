#version 450

layout(push_constant) uniform Push {
    vec4 OutputSize;
    vec4 OriginalSize;
    vec4 SourceSize;
    uint FrameCount;
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
layout(set = 0, binding = 2) uniform sampler2D Original;


void main() {
    const float scanline_offset = fract(vTexCoord.y * param.OriginalSize.y) - 0.5;
    
    FragColor = vec4(0.0, 0.0, 0.0, 1.0);
    const vec3 signal = texture(Source, vTexCoord).rgb;
    const vec3 orig = texture(Original, vTexCoord).rgb;
    for (int c = 0; c < 3; ++c) {
        if(abs(scanline_offset) < signal[c] * 0.4f) {
            FragColor[c] = signal[c];
        }
    }
}
