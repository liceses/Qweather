#version 450

// [FogLayer] — Fog / haze / sand overlay / 雾 / 霾 / 沙尘叠加
layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float intensity;
    int variant;
    float windSpeed;
    float transitionProgress;
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

float noise2D(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash1(i.x + i.y * 57.0);
    float b = hash1(i.x + 1.0 + i.y * 57.0);
    float c = hash1(i.x + (i.y + 1.0) * 57.0);
    float d = hash1(i.x + 1.0 + (i.y + 1.0) * 57.0);
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void main() {
    vec2 uv = qt_TexCoord0;

    float tp = clamp(transitionProgress, 0.0, 1.0);
    float fogAlpha = intensity * tp;

    if (fogAlpha < 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    // variant: 0=fog(milky), 1=haze(yellow-grey), 2=sand(brown)
    vec3 fogColor;
    if (variant == 0) {
        fogColor = vec3(0.85, 0.85, 0.88);
    } else if (variant == 1) {
        fogColor = vec3(0.6, 0.55, 0.45);
    } else {
        fogColor = vec3(0.5, 0.4, 0.25);
    }

    // sand: add grain noise
    if (variant == 2) {
        vec2 noiseUV = uv * 10.0 + time * 0.02;
        float grain = noise2D(noiseUV) * 0.15;
        fogColor += vec3(grain * 0.5, grain * 0.3, 0.0);
    }

    // thicker near horizon
    float horizonFade = 1.0 - abs(uv.y - 0.5) * 1.2;
    fogAlpha *= mix(1.0, 1.5, max(0.0, horizonFade));

    // thicker at bottom
    float heightFade = 1.0 - uv.y * 0.5;
    fogAlpha *= heightFade;

    fogAlpha = clamp(fogAlpha, 0.0, 0.85);
    fragColor = vec4(fogColor * fogAlpha, fogAlpha) * qt_Opacity;
}
