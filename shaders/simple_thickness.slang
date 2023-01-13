#version 450

// clang-format off
#pragma parameter MIN_THICKNESS "Scanline thickness of dark pixels." 0.3 0.0 1.0 0.05
#pragma parameter MAX_THICKNESS "Scanline thickness of bright pixels." 0.9 0.0 1.4 0.05
#pragma parameter V_SHARP "Vertical sharpness of the scanline" 0.5 0.0 1.0 0.05
#pragma parameter H_SHARP "Horizontal sharpness of pixel transitions." 0.5 0.0 1.0 0.05
// clang-format on

layout(push_constant) uniform Push {
    vec4 OutputSize;
    vec4 SourceSize;
    uint FrameCount;
    float MIN_THICKNESS;
    float MAX_THICKNESS;
    float V_SHARP;
    float H_SHARP;
}
param;

layout(std140, set = 0, binding = 0) uniform UBO { mat4 MVP; }
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
layout(set = 0, binding = 1) uniform sampler2D Source;
layout(set = 0, binding = 2) uniform sampler2D Original;

float gain(float x, float k) {
    x = clamp(x, 0.0, 1.0);
    const float s = sign(x - 0.5);
    const float o = (1.0 + s) / 2.0;
    return o - 0.5 * s * pow(2.0 * (o - s * x), k);
}

float aa(float x) { return clamp(x * 10.0f, 0.0f, 1.0f); }

void main() {
    float eff_v_sharp = 5.0f + 100.0f * param.V_SHARP * param.V_SHARP;

    float src_x_int;
    const float src_x_fract = modf(vTexCoord.x * param.SourceSize.x, src_x_int);

    float src_y_int;
    const float src_y_fract = modf(vTexCoord.y * param.SourceSize.y, src_y_int);

    FragColor = vec4(0.0, 0.0, 0.0, 1.0);
    // const float src_x_fract_shf =
    //     clamp((src_x_fract - 0.5f) * 1.0f, -0.5f, 0.5f);
    // const float src_x =
    //     src_x_int + clamp(sign(src_x_fract_shf) *
    //                           pow(abs(src_x_fract_shf) * 2.0f, 0.5f) * 0.5f,
    //                       -0.5f, 0.5f);
    // const float src_x = src_x_int + clamp(src_x_fract_shf * 2.0f, -0.5f,
    // 0.5f);
    // const float src_x =
    //     src_x_int + sign(src_x_fract_shf) *
    //                     sqrt(-src_x_fract_shf * src_x_fract_shf +
    //                          sign(src_x_fract_shf) * src_x_fract_shf) + 1.0f;
    // const float src_x =
    //     src_x_int + smoothstep(-0.5f, 0.5f, src_x_fract_shf * 1.0f) + 0.5f;
    const float src_x =
        src_x_int + gain(src_x_fract, mix(1.5f, 10.0f, param.H_SHARP)) + 0.5f;

    const vec3 signal =
        texture(Source, vec2(src_x * param.SourceSize.z,
                             (src_y_int + 0.5f) * param.SourceSize.w))
            .rgb;
    // for (int c = 0; c < 3; ++c) {
    //     if (abs(src_y_fract - 0.5f) < signal[c] * 0.4f) {
    //         FragColor[c] = signal[c];
    //     }
    // }
    for (int c = 0; c < 3; ++c) {
        FragColor[c] =
            mix(0.0f, signal[c],
                clamp(eff_v_sharp * ((mix(param.MIN_THICKNESS,
                                          param.MAX_THICKNESS, signal[c]) *
                                      0.5f) -
                                     abs(src_y_fract - 0.5f)),
                      0.0f, 1.0f));
    }
}
