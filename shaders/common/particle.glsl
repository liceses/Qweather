// particle.glsl — 粒子通用函数（雨/雪/雹）
#ifndef PARTICLE_GLSL
#define PARTICLE_GLSL

// 雨滴: 位置 → 拉长的线段
void rainDrop(vec2 uv, vec2 pos, float length, float width, float time, float seed, inout float alpha) {
    vec2 offset = uv - pos;
    // 雨丝沿 Y 轴拉长
    float distX = abs(offset.x);
    float distY = abs(offset.y);
    if (distX < width && distY < length * 0.5) {
        float fade = 1.0 - (distY / (length * 0.5));
        alpha += fade * (1.0 - distX / width);
    }
}

// 雪花: 位置 → 圆形 + 摇摆
void snowFlake(vec2 uv, vec2 pos, float size, float time, float seed, inout float alpha) {
    vec2 offset = uv - pos;
    float dist = length(offset);
    if (dist < size) {
        float fade = 1.0 - (dist / size);
        alpha += fade * 0.8;
    }
}

// 冰雹: 位置 → 小方形
void hailDrop(vec2 uv, vec2 pos, float size, float time, float seed, inout float alpha) {
    vec2 offset = abs(uv - pos);
    if (offset.x < size && offset.y < size) {
        alpha += 0.9;
    }
}

#endif
