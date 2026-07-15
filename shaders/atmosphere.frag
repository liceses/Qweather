#version 450

// AtmosphereLayer — twilight 散射色调 + 曝光控制
layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    float time;
    vec4 zenithColor;
    vec4 horizonColor;
    vec4 ambientColor;
    float exposure;
    float twilightFactor;
};

layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;

void main() {
    vec2 uv = qt_TexCoord0;

    // 基于 Y 坐标的渐变叠加
    float horizonBlend = pow(uv.y, 0.7);

    // 天顶到地平线颜色渐变（半透明覆盖）
    vec3 zenith = zenithColor.rgb;
    vec3 horizon = horizonColor.rgb;

    vec3 atmosColor = mix(zenith, horizon, horizonBlend);

    // twilight 因子增强暖色
    if (twilightFactor > 0.01) {
        vec3 twilightTint = vec3(1.0, 0.6, 0.3) * twilightFactor * 0.15;
        atmosColor += twilightTint;
    }

    // 环境光混合
    atmosColor = mix(atmosColor, ambientColor.rgb, 0.1);

    // 曝光调整
    atmosColor *= exposure;

    // 输出为半透明叠加层
    float alpha = 0.3;
    fragColor = vec4(atmosColor * alpha, alpha) * qt_Opacity;
}
