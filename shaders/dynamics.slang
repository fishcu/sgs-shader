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

vec2 f(in vec2 state, float u, float pos_gain, float neg_gain, float damping) {
    // external force
    float F = u - state.x;
    if (F > 0.0f) {
        F *= pos_gain;
    } else {
        F *= neg_gain;
    }
    // Return derivative of state.
    return vec2(state.y, F - damping * state.y);
}

void main() {
    const vec2 inv_source_to_output_scale = param.OutputSize.zw * param.SourceSize.xy;

    const float pos_gain = 700.0;
    const float neg_gain = 3000.0;
    const float damping = 40.0f;

    // output signal and "velocity" of output signal to simulate momentum
    vec2 state[3] = {{0.0f, 0.0f}, {0.0f, 0.0f}, {0.0f, 0.0f}}; 

    const float num_steps = 120.0f;
    const float dt = 0.01f;
    const float perc_of_sampled_screen = 0.4f;
    for (float t = 0.0; t <= num_steps; t += 1.0f) {
    // for (int i=0; i < 4000; ++i) {
        vec3 signal = texture(Source, vec2(mix(vTexCoord.x - perc_of_sampled_screen, vTexCoord.x, t / num_steps), vTexCoord.y)).rgb;
        for (int c = 0; c < 3; ++c) {
            // state[c] += f(state[c], signal[c], pos_gain, neg_gain, damping) * dt;
            // Midpoint-ish algorithm (assume signal does not change between t and t + dt/2).
            const vec2 state_mid = state[c] + f(state[c], signal[c], pos_gain, neg_gain, damping) * dt * 0.5f;
            state[c] += f(state_mid, signal[c], pos_gain, neg_gain, damping) * dt;
        }
    }

    FragColor = vec4(state[0][0], state[1][0], state[2][0], 1.0);
}
