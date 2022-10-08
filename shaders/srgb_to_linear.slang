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
layout(set = 0, binding = 1) uniform sampler2D Original;

float srgb_to_linear(float x) {
    return x <= 0.04045f ?
        x * 0.0773993808f : // = 1.0f / 12.92f
        pow((x + 0.055f) * 0.94786729857f, 2.4f); // 0.94786729857 = 1.0f / 1.055f
}

void main() {
    const vec4 s = texture(Original, vTexCoord);
    FragColor = vec4(srgb_to_linear(s[0]), srgb_to_linear(s[1]), srgb_to_linear(s[2]), 1.0f);
}
