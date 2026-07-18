#version 450

// [SnowLayer] — Snow particle system / 雪粒子系统
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

// [Common functions] / 常用函数
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

    int maxFlakes = int(float(particleLimit) * activeIntensity);
    vec3 snowColor = vec3(0.9, 0.92, 0.95);

    vec3 accum = vec3(0.0);
    float alpha = 0.0;

    for (int i = 0; i < 60; i++) {
        if (i >= maxFlakes) break;

        float seed = float(i) * 17.3;
        vec2 pos = hash2(seed);

        float speed = mix(0.1, 0.35, hash1(seed + 0.3));
        float sway = sin(time * 0.5 + seed * 3.0) * 0.02;
        float yOffset = fract(time * speed * 0.3 + seed * 0.5) - 0.5;

        pos.x += sway + windSpeed * 0.02;
        pos.y += yOffset;
        pos.x = fract(pos.x + 1.0);
        pos.y = fract(pos.y + 1.0);

        vec2 delta = uv - pos;
        float dist = length(delta);
        float size = mix(0.005, 0.015, hash1(seed + 0.4));
        float flakeAlpha = smoothstep(size * 2.0, 0.0, dist) * 0.7;
        flakeAlpha *= activeIntensity;
        alpha += flakeAlpha;
        accum += snowColor * flakeAlpha;
    }

    // sleet variant: blue tint
    if (variant == 1) {
        accum = mix(accum, vec3(0.6, 0.7, 0.85), 0.3);
    }

    accum = clamp(accum, 0.0, 1.0);
    alpha = clamp(alpha, 0.0, 0.6);
    fragColor = vec4(accum, alpha) * qt_Opacity;
}
