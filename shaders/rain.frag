#version 450

// RainLayer - grid-based rain with neighbor checking (adapted from Shadertoy)
// 仅 X 方向划分网格，每条竖带一条雨丝，邻格检测保证水平移动连续
layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float intensity;
    int variant;
    float windSpeed;
    float transitionProgress;
    int particleLimit;  // unused
};

layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;

// 椭圆 SDF (Inigo Quilez)
float sdEllipse(vec2 p, vec2 r) {
    return (length(p / r) - 1.0) * min(r.x, r.y);
}

void main() {
    vec2 uv = qt_TexCoord0;

    float tp = clamp(transitionProgress, 0.0, 1.0);
    float activeIntensity = intensity * tp;

    if (activeIntensity < 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    vec3 rainColor = vec3(0.72, 0.74, 0.78);
    float accum = 0.0;

    // 景深：下部更亮
    float depth = 0.6 + 0.4 * uv.y;

    // 风向倾斜
    float tilt = windSpeed * 0.04;
    vec2 tuv = uv;
    tuv.y = 1.0 - tuv.y;                  // Qt Y↓ → Shadertoy Y↑
    tuv.x += tilt * (0.5 - tuv.y);        // 风向倾斜

    // 转换到 Shadertoy 坐标系 [-0.5, 0.5]
    vec2 suv = (tuv - 0.5) * vec2(2.0, 1.0);

    // 多层雨（参考 Shadertoy: 10 层）
    for (float l = 0.0; l < 12.0; l++) {
        float scale = 8.0 + l * 0.7;
        vec2 layerUV = suv * scale;

        // 仅 X 方向网格
        float cellIDx = floor(layerUV.x);
        float localX = fract(layerUV.x) - 0.5;
        // Y 连续，不做网格

        // 当前格和邻格的随机偏移
        float cellOff     = fract(324.6 * sin(46.7 * cellIDx + l));
        float n_cellOff   = fract(324.6 * sin(46.7 * (cellIDx + 1.0) + l));

        // X 偏移（雨丝水平位置）
        float hOff = 0.6 * (cellOff - 0.5);
        float n_hOff = 0.6 * (n_cellOff - 0.5);

        // 下落进度
        float dropSpeed = 0.8 + 0.7 * cellOff;
        float fallProg     = fract(time * dropSpeed + cellOff);
        float n_fallProg   = fract(time * (0.8 + 0.7 * n_cellOff) + n_cellOff);

        // 雨丝在 Y 方向的位置（适配当前层的坐标范围）
        float viewHalf = scale * 0.5;
        float fallHeight = viewHalf * 0.98;
        float rainfallBottom = -viewHalf * 0.98;
        float yVal   = fallHeight - (fallHeight - rainfallBottom) * fallProg;
        float n_yVal = fallHeight - (fallHeight - rainfallBottom) * n_fallProg;

        // 当前像素到屏幕底部的距离（用于涟漪）
        float groundDist = uv.y;

        // 椭圆雨滴 SDF（当前格 + 邻格）
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
        float dropAlpha = smoothstep(w, -w, drop) * 0.25 * activeIntensity;
        accum += dropAlpha;

        // 落地涟漪：雨丝到底部时扩散
        if (n_yVal < rainfallBottom + 1.5 && groundDist < 0.3) {
            float rippleSize = (rainfallBottom + 1.5 - n_yVal) / 1.5;
            vec2 rp = vec2(localX - n_hOff, layerUV.y - rainfallBottom);
            float ripple = sdEllipse(rp, vec2(0.5 * rippleSize, 0.2 * rippleSize));
            float rAlpha = smoothstep(0.01, -0.01, ripple) * 0.08 * rippleSize * activeIntensity;
            accum += rAlpha;
        }
    }

    accum = clamp(accum, 0.0, 0.5);
    fragColor = vec4(rainColor * accum, accum) * qt_Opacity;
}
