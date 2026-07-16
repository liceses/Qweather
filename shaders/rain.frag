#version 450

// RainLayer - grid-based rain with density control + exposure compensation
layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float intensity;
    int variant;
    float windSpeed;
    float transitionProgress;
    int particleLimit;
    float exposure;
};

layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;

float sdEllipse(vec2 p, vec2 r) {
    return (length(p / r) - 1.0) * min(r.x, r.y);
}

float hash1(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

void main() {
    vec2 uv = qt_TexCoord0;

    float tp = clamp(transitionProgress, 0.0, 1.0);
    float activeIntensity = intensity * tp;

    if (activeIntensity < 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    vec3 rainColor = mix(vec3(0.85, 0.87, 0.92), vec3(0.45, 0.48, 0.52), clamp(exposure * 0.5, 0.0, 1.0));
    float accum = 0.0;
    float depth = 0.6 + 0.4 * uv.y;
    float tilt = windSpeed * 0.04;
    vec2 tuv = uv;
    tuv.y = 1.0 - tuv.y;
    tuv.x += tilt * (0.5 - tuv.y);
    vec2 suv = (tuv - 0.5) * vec2(2.0, 1.0);

    float density = 0.10 + 0.90 * activeIntensity;
    float expComp = clamp(exposure * 0.8, 0.6, 3.0);

    for (float l = 0.0; l < 12.0; l++) {
        float scale = 8.0 + l * 0.7;
        vec2 layerUV = suv * scale;

        float cellIDx = floor(layerUV.x);
        float localX = fract(layerUV.x) - 0.5;

        if (hash1(cellIDx + l * 7.3) > density) continue;

        float cellOff     = fract(324.6 * sin(46.7 * cellIDx + l));
        float n_cellOff   = fract(324.6 * sin(46.7 * (cellIDx + 1.0) + l));

        float hOff = 0.6 * (cellOff - 0.5);
        float n_hOff = 0.6 * (n_cellOff - 0.5);

        float dropSpeed = (0.4 + 0.6 * activeIntensity) * (0.6 + 0.9 * cellOff);
        float fallProg     = fract(time * dropSpeed + cellOff);
        float n_fallProg   = fract(time * dropSpeed + n_cellOff);

        float viewHalf = scale * 0.5;
        float fallHeight = viewHalf * 0.98;
        float rainfallBottom = -viewHalf * 0.98;
        float yVal   = fallHeight - (fallHeight - rainfallBottom) * fallProg;
        float n_yVal = fallHeight - (fallHeight - rainfallBottom) * n_fallProg;

        float groundDist = uv.y;

        float drop1 = sdEllipse(
            vec2(localX - n_hOff, layerUV.y - n_yVal),
            vec2(0.025 * depth, 0.15 * depth * (0.6 + 0.4 * fallProg))
        );
        float drop2 = sdEllipse(
            vec2(localX - hOff, layerUV.y - yVal) - vec2(-1.0, 0.0),
            vec2(0.025 * depth, 0.15 * depth * (0.6 + 0.4 * fallProg))
        );

        float drop = min(drop1, drop2);
        float w = 0.003;
        float dropAlpha = smoothstep(w, -w, drop) * 0.25 * activeIntensity * expComp;
        accum += dropAlpha;

        if (n_yVal < rainfallBottom + 1.5 && groundDist < 0.3) {
            float rippleSize = (rainfallBottom + 1.5 - n_yVal) / 1.5;
            vec2 rp = vec2(localX - n_hOff, layerUV.y - rainfallBottom);
            float ripple = sdEllipse(rp, vec2(0.5 * rippleSize, 0.2 * rippleSize));
            float rAlpha = smoothstep(0.01, -0.01, ripple) * 0.08 * rippleSize * activeIntensity * expComp;
            accum += rAlpha;
        }
    }

    accum = clamp(accum, 0.0, 0.5);
    fragColor = vec4(rainColor * accum, accum) * qt_Opacity;
}
