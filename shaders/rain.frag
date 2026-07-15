#version 450

// RainLayer - rain particle system
layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float intensity;
    int variant;
    float windSpeed;
    float transitionProgress;
    int particleLimit;
};

layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;

// ---- common functions ----
float hash1(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

vec2 hash2(float p) {
    vec2 r;
    r.x = hash1(p + 0.1);
    r.y = hash1(p + 0.2);
    return r;
}

void main() {
    vec2 uv = qt_TexCoord0;

    float tp = clamp(transitionProgress, 0.0, 1.0);
    float activeIntensity = intensity * tp;

    if (activeIntensity < 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    int maxDrops = int(float(particleLimit) * activeIntensity);
    vec3 rainColor = vec3(0.7, 0.75, 0.85);

    vec3 accum = vec3(0.0);
    float alpha = 0.0;

    for (int i = 0; i < 60; i++) {
        if (i >= maxDrops) break;

        float seed = float(i) * 13.7;
        vec2 pos = hash2(seed);

        float speed = mix(0.3, 0.8, hash1(seed + 0.3));
        float yOffset = fract(time * speed * 0.5 + seed * 0.7) - 0.5;
        float windOffset = time * windSpeed * 0.1 * hash1(seed + 0.4);

        pos.y += yOffset;
        pos.x += windOffset;
        pos.x = fract(pos.x + 1.0);

        vec2 delta = uv - pos;
        delta.y /= 0.15;

        float dist = length(delta);
        float dropAlpha = smoothstep(0.02, 0.0, dist) * 0.5;
        dropAlpha *= activeIntensity;
        alpha += dropAlpha;
        accum += rainColor * dropAlpha;
    }

    // lightning flash for thunderstorm variants
    if (variant == 1 || variant == 3) {
        float flash = sin(time * 3.0 + floor(time) * 7.0) * 0.5 + 0.5;
        flash = pow(flash, 8.0) * 0.3;
        accum += vec3(flash);
    }

    accum = clamp(accum, 0.0, 1.0);
    alpha = clamp(alpha, 0.0, 0.7);
    fragColor = vec4(accum, alpha) * qt_Opacity;
}
