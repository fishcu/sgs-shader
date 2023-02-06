// Assume that the value of the kernel vanishes around that point.
#define _ITERATION_SIGMA_MULTIPLIER 1.6
// Slightly supersample the input to avoid jittering for small sigmas
#define _ITERATION_STEP_SUPERSAMPLE 0.4

float gauss(float t, float sigma) {
    return exp(-t * t / (sigma * sigma + 1.e-8f));
}

float gauss_with_overshoot(float x, float sigma, float overshoot_strength) {
    return gauss(x, sigma) - gauss(x - sigma * 0.8, sigma * 0.5) * overshoot_strength;
}

void blur_horiz(in float sigma, in float overshoot_strength, in float pixel_width,
                in sampler2D source, in vec2 tex_coord, inout vec4 res) {
    const float radius = _ITERATION_SIGMA_MULTIPLIER * sigma;

    res = vec4(vec3(0.0), 1.0);
    float sum = 0.0;
    for (float dx = -radius; dx <= radius; dx += pixel_width * _ITERATION_STEP_SUPERSAMPLE) {
        const float w = gauss_with_overshoot(-dx, sigma, overshoot_strength);
        res += texture(source, vec2(tex_coord.x + dx, tex_coord.y)) * w;
        sum += w;
    }
    res /= sum;
}
