float signal_to_thickness(float signal, float min_radius, float max_radius, float gamma) {
    return mix(min_radius, max_radius,
        signal > 1.0 ? signal : pow(signal, gamma));
}
