#version 450

#include "parameters.slang"

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
    const float rel_gamma = 1.0 / param.OUTPUT_GAMMA;
    return x <= 0.0031308 ?
        x * 12.92 :
        1.055f * pow(x, rel_gamma) - 0.055;
}

void main() {
    const vec4 s = texture(Source, vTexCoord);
    FragColor = vec4(linear_to_srgb(s[0]), linear_to_srgb(s[1]), linear_to_srgb(s[2]), 1.0);

    // Extra debug overlay
    const float slider_y_pos = 0.35f;
    const float slider_x_min = 0.4f;
    const float slider_x_max = 0.6f;

    if (dist_to_segment(vTexCoord, vec2(slider_x_min, slider_y_pos), vec2(slider_x_max, slider_y_pos)) < 0.005) {
        FragColor = vec4(1.0, 1.0, 1.0, 1.0);
    }
    if (dist_to_segment(vTexCoord, vec2(slider_x_min, slider_y_pos), vec2(slider_x_max, slider_y_pos)) < 0.002) {
        FragColor = vec4(0.0, 0.0, 0.0, 1.0);
    }

    const float slider_x_pos = mix(slider_x_min, slider_x_max, frame_number_to_slider(float(param.FrameCount)));
    const float slider_y_size = 0.015;
    if (dist_to_segment(vTexCoord, vec2(slider_x_pos, slider_y_pos - slider_y_size), vec2(slider_x_pos, slider_y_pos + slider_y_size)) < 0.01) {
        FragColor = vec4(0.0, 0.0, 0.0, 1.0);
    }
    if (dist_to_segment(vTexCoord, vec2(slider_x_pos, slider_y_pos - slider_y_size), vec2(slider_x_pos, slider_y_pos + slider_y_size)) < 0.007) {
        FragColor = vec4(0.7, 0.7, 0.7, 1.0);
    }
}
