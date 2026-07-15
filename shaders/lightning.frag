#version 450

// LightningLayer — 全屏间歇闪电闪烁
layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float lightningProb;
};

layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;

void main() {
    if (lightningProb <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    // 每 3 秒一个 epoch，用 hash 决定是否闪光
    float epoch = floor(time / 3.0);
    float epochTime = fract(time / 3.0);  // 0~1

    // hash 决定触发时刻
    float h = fract(sin(epoch * 127.1 + 311.7) * 43758.5453);
    float triggerTime = h;  // 0~1，与 epochTime 对齐

    float flash = 0.0;

    // 第一闪
    float dt = epochTime - triggerTime;
    if (dt > 0.0 && dt < 0.15) {
        flash = exp(-dt * 30.0);
    }

    // 第二闪 (200ms 后，按 epochTime 归一化)
    float dt2 = epochTime - (triggerTime + 0.2 / 3.0);
    if (dt2 > 0.0 && dt2 < 0.1) {
        flash = max(flash, exp(-dt2 * 40.0));
    }

    float brightness = flash * 1.5 * lightningProb;
    vec3 flashColor = vec3(1.0, 0.95, 0.9) * brightness;
    float alpha = clamp(brightness, 0.0, 0.6);
    fragColor = vec4(flashColor * alpha, alpha) * qt_Opacity;
}
