# QML 动态天气背景 —— Canvas / Shader 实现方案

---

## 一、两种方案对比总览

| 维度 | **Canvas** | **ShaderEffect** |
|------|-----------|-----------------|
| 渲染位置 | CPU → 位图 → 上传 GPU | 直接在 GPU 上运行 [4] |
| 性能 | 粒子数多时（>500）明显下降 | 数千粒子无压力 |
| 开发难度 | ⭐⭐ 低，QML/JS 即可 | ⭐⭐⭐⭐ 高，需写 GLSL |
| 适合效果 | 少量粒子、简单渐变、雪/雨 | 全屏渐变、光线、云层、大量粒子 |
| Qt6 兼容 | ✅ 直接可用 | ✅ 支持，但 shader 需用 `.qsb` 格式 [6][19] |
| 推荐用途 | 快速原型、简单效果 | 生产级、复杂动态背景 |

> **我推測**：对于你的天气应用，**ShaderEffect 是更优选择**——天气背景需要持续运行且覆盖全窗口，GPU 渲染能保证 UI 响应不受影响。

---

## 二、架构设计

### 推荐分层结构

```
┌─────────────────────────────────────────────────────┐
│ ApplicationWindow                                   │
│                                                     │
│  Layer 0: WeatherBackground {                       │
│    id: bgLayer                                      │
│    // 根据 weatherCode 动态切换子组件                │
│                                                     │
│    Loader { id: bgLoader }  ← 动态加载对应 shader   │
│                                                     │
│    // 方案A: ShaderEffect (推荐)                     │
│    // 方案B: Canvas (备选，简单场景)                  │
│  }                                                  │
│                                                     │
│  Layer 1: 半透明遮罩 (可选，增强文字可读性)           │
│                                                     │
│  Layer 2: RowLayout {                               │
│    左侧面板 (Column)  │  右侧网格 (GridLayout)       │
│  }                                                  │
└─────────────────────────────────────────────────────┘
```

### 文件结构（推測）

```
qml/
├── main.qml                        # 主窗口
├── WeatherBackground.qml           # 背景容器 + Loader 调度
├── backgrounds/
│   ├── SunnyBackground.qml         # 晴天：暖色渐变 + 光线
│   ├── CloudyBackground.qml        # 阴天：灰色渐变 + 云层漂移
│   ├── RainBackground.qml          # 雨天：雨滴粒子
│   ├── SnowBackground.qml          # 雪天：雪花飘落
│   ├── NightBackground.qml         # 夜间：星空 + 暗色渐变
│   └── ThunderBackground.qml       # 雷暴：闪电闪烁
├── shaders/
│   ├── rain.frag                   # 雨滴 fragment shader
│   ├── snow.frag                   # 雪花 fragment shader
│   ├── clouds.frag                 # 云层漂移 shader
│   ├── sun_glow.frag              # 阳光光晕 shader
│   ├── stars.frag                 # 星空 shader
│   └── lightning.frag             # 闪电 shader
└── components/
    ├── SidePanel.qml              # 左侧选项面板
    └── WeatherGrid.qml            # 右侧天气网格
```

---

## 三、天气码 → 背景效果映射表

基于 WeatherAPI 的标准天气 code [1]：

```
天气 code    条件          背景效果              实现方式
──────────────────────────────────────────────────────────
1000        晴天/晴夜      暖色渐变+光晕/星空    ShaderEffect
1003        多云          灰白渐变+云层漂移     ShaderEffect
1006        阴天          深灰渐变+厚重云层     ShaderEffect
1009        Overcast      均匀灰色+暗沉        Rectangle渐变
1030        雾/霾         模糊+乳白渐变         ShaderEffect + blur
1063-1195   各种雨         雨滴下落+涟漪        ShaderEffect (粒子)
1066-1072   雨夹雪         雨+雪混合           ShaderEffect
1114-1117   雪/暴雪        雪花飘落             ShaderEffect
1087        雷暴           暗色+闪电闪烁        ShaderEffect
1135        雾凇           白色渐变+模糊        ShaderEffect
1210-1252   冻雨/雪粒      冰晶粒子             ShaderEffect
1273-1282   雷雨           雨+闪电混合          ShaderEffect 组合
```

> ⚠️ 以上映射是我基于常识的**推測**，具体可根据你的审美偏好调整。

---

## 四、核心实现：ShaderEffect 方案（Qt6）

### 4.0 Qt6 ShaderEffect 基础模板

Qt6 中 `vertexShader` 和 `fragmentShader` 属性变为 URL，指向 `.qsb` 或内联 shader 文件 [6]。ShaderEffect 会自动将 QML 属性映射为 GLSL 中的 `uniform` 变量 [4]。

```qml
// Qt6 ShaderEffect 基础写法
ShaderEffect {
    id: effect
    anchors.fill: parent
  
    // QML 属性自动成为 shader 的 uniform
    property real time: 0
    property real intensity: 1.0
    property color skyTop: "#4a90d9"
    property color skyBottom: "#87ceeb"
  
    // Qt6: shader 以文件 URL 方式引用
    fragmentShader: "qrc:/shaders/clouds.frag"
  
    // 驱动动画
    NumberAnimation on time {
        from: 0; to: 1000
        duration: 1000000
        loops: Animation.Infinite
    }
}
```

### 4.1 晴天（Sunny）—— 暖色渐变 + 动态光晕

```glsl
// shaders/sun_glow.frag
#version 440

layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;

layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    vec4 skyTop;      // 天空顶部颜色，如 #4A90D9
    vec4 skyBottom;   // 天空底部颜色，如 #F5A623（暖金色）
    float sunAngle;   // 太阳角度（影响光线方向）
} ubuf;

// 2D 噪声函数（用于云朵效果）
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

void main() {
    vec2 uv = qt_TexCoord0;
  
    // 垂直渐变：上蓝下暖金
    vec3 gradient = mix(ubuf.skyBottom.rgb, ubuf.skyTop.rgb, uv.y);
  
    // 太阳光晕（右上角）
    float sunDist = distance(uv, vec2(0.75, 0.25));
    float glow = exp(-sunDist * 4.0) * 0.6;
    vec3 sunColor = vec3(1.0, 0.9, 0.5) * glow;
  
    // 动态光线（随时间旋转）
    float angle = ubuf.time * 0.05;
    vec2 lightDir = vec2(cos(angle), sin(angle));
    float lightRay = smoothstep(0.0, 1.0, 
        dot(uv - vec2(0.5), lightDir) * 2.0) * 0.08;
  
    // 轻微云朵噪点
    float cloud = noise(uv * 8.0 + ubuf.time * 0.02) * 0.03;
  
    vec3 finalColor = gradient + sunColor + vec3(lightRay) + cloud;
    fragColor = vec4(finalColor, 1.0) * ubuf.qt_Opacity;
}
```

### 4.2 雨天（Rain）—— 纯 Shader 雨滴粒子

```glsl
// shaders/rain.frag
#version 440

layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;

layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float intensity;  // 雨强度 (0.0 ~ 1.0)，控制雨滴密度
    vec4 skyColor;    // 阴天背景色
} ubuf;

// 哈希函数生成伪随机
float hash(float n) { return fract(sin(n) * 43758.5453123); }

// 雨滴函数：返回该像素是否为雨滴
float raindrop(vec2 uv, float id, float t) {
    float seed = hash(id);
  
    // 每条雨滴的水平偏移
    float x = mod(seed * 6.28318, 1.0);
  
    // 雨滴垂直位置（循环下落）
    float speed = mix(0.3, 0.8, seed);
    float y = fract(seed * 3.14159 + t * speed);
  
    // 雨滴位置
    vec2 dropPos = vec2(x, y);
  
    // 与当前像素的距离
    float dist = abs(uv.x - dropPos.x) * 200.0;
    float vertDist = abs(uv.y - dropPos.y);
  
    // 雨滴形状：细长 + 尾部淡出
    float tail = smoothstep(0.0, 0.03, vertDist) * 0.7;
    float body = 1.0 - smoothstep(0.0, 0.002, dist);
    float head = 1.0 - smoothstep(0.0, 0.003, 
        distance(uv, dropPos) * 10.0);
  
    return max(body * tail, head * 0.5);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec3 bg = ubuf.skyColor.rgb;  // 深灰色阴天背景
  
    float rain = 0.0;
    int dropCount = int(mix(8.0, 30.0, ubuf.intensity));
  
    for (int i = 0; i < 30; i++) {
        if (i >= dropCount) break;
        rain += raindrop(uv, float(i) + floor(ubuf.time * 0.5), ubuf.time);
    }
  
    rain = clamp(rain, 0.0, 1.0);
  
    // 雨滴颜色：浅灰白
    vec3 rainColor = mix(bg, vec3(0.8, 0.85, 0.9), rain);
  
    fragColor = vec4(rainColor, 1.0) * ubuf.qt_Opacity;
}
```

### 4.3 雪天（Snow）—— 飘落雪花

```glsl
// shaders/snow.frag
#version 440

layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;

layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float intensity;   // 雪强度
    vec4 skyTop;       // 上色
    vec4 skyBottom;    // 下色
} ubuf;

float hash12(vec2 p) {
    float h = dot(p, vec2(127.1, 311.7));
    return fract(sin(h) * 43758.5453);
}

// 雪花
float snowflake(vec2 uv, float id, float t, float wind) {
    float seed = hash12(vec2(id, 0.0));
  
    // 水平摆动（模拟风吹）
    float sway = sin(t * 0.8 + seed * 6.28) * 0.03 * wind;
    float x = mod(seed + sway, 1.0);
  
    // 垂直下落 + 左右摆动
    float speed = mix(0.1, 0.3, seed);
    float y = fract(seed * 6.28 + t * speed);
  
    vec2 pos = vec2(x, y);
    float dist = distance(uv, pos);
  
    // 雪花大小随机
    float size = mix(0.003, 0.012, hash12(vec2(id, 1.0)));
    float alpha = 1.0 - smoothstep(0.0, size, dist);
  
    // 边缘柔和的圆形
    return alpha * smoothstep(size, size * 0.5, dist);
}

void main() {
    vec2 uv = qt_TexCoord0;
  
    // 渐变背景
    vec3 bg = mix(ubuf.skyBottom.rgb, ubuf.skyTop.rgb, uv.y);
  
    float snow = 0.0;
    int count = int(mix(15.0, 50.0, ubuf.intensity));
  
    for (int i = 0; i < 50; i++) {
        if (i >= count) break;
        snow += snowflake(uv, float(i), ubuf.time, 0.5);
    }
  
    snow = clamp(snow, 0.0, 1.0);
    vec3 color = mix(bg, vec3(0.95), snow);
  
    fragColor = vec4(color, 1.0) * ubuf.qt_Opacity;
}
```

### 4.4 夜间（Night）—— 星空

```glsl
// shaders/stars.frag
#version 440

layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;

layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
} ubuf;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }

void main() {
    vec2 uv = qt_TexCoord0;
  
    // 深蓝到黑的夜空渐变
    vec3 skyTop = vec3(0.02, 0.02, 0.15);
    vec3 skyBottom = vec3(0.05, 0.05, 0.2);
    vec3 bg = mix(skyTop, skyBottom, 1.0 - uv.y);
  
    // 星空
    float stars = 0.0;
    for (int i = 0; i < 40; i++) {
        vec2 starPos = vec2(
            hash(vec2(float(i), 0.0)),
            hash(vec2(float(i), 1.0))
        );
        float twinkle = sin(ubuf.time * 2.0 + float(i)) * 0.5 + 0.5;
        float dist = distance(uv, starPos);
        float glow = exp(-dist * 40.0) * twinkle * 0.8;
        stars += glow;
    }
  
    vec3 color = bg + vec3(stars * 0.9, stars * 0.85, stars);
    fragColor = vec4(color, 1.0) * ubuf.qt_Opacity;
}
```

---

## 五、核心实现：Canvas 备选方案

对于简单效果或不支持 ShaderEffect 的后端，Canvas 是可靠的备选：

```qml
// backgrounds/RainCanvas.qml
Canvas {
    id: canvas
    anchors.fill: parent
  
    property real time: 0
    property real intensity: 0.5
    property int dropCount: 100
  
    // 存储雨滴状态
    property var drops: []
  
    Component.onCompleted: {
        for (var i = 0; i < 100; i++) {
            drops.push({
                x: Math.random(),
                y: Math.random(),
                speed: 0.003 + Math.random() * 0.007,
                length: 0.02 + Math.random() * 0.04,
                opacity: 0.3 + Math.random() * 0.5
            });
        }
    }
  
    // 动画循环
    Timer {
        interval: 16  // ~60 FPS
        running: true
        repeat: true
        onTriggered: {
            canvas.time += 0.016;
            // 更新雨滴位置
            for (var i = 0; i < canvas.drops.length; i++) {
                var d = canvas.drops[i];
                d.y += d.speed;
                if (d.y > 1.05) {
                    d.y = -0.05;
                    d.x = Math.random();
                }
            }
            canvas.requestPaint();
        }
    }
  
    onPaint: {
        var ctx = getContext("2d");
        var w = width, h = height;
      
        // 背景
        var gradient = ctx.createLinearGradient(0, 0, 0, h);
        gradient.addColorStop(0, "#2c3e50");
        gradient.addColorStop(1, "#4a6670");
        ctx.fillStyle = gradient;
        ctx.fillRect(0, 0, w, h);
      
        // 绘制雨滴
        ctx.strokeStyle = "rgba(200, 210, 220, 0.6)";
        ctx.lineWidth = 1;
      
        for (var i = 0; i < drops.length; i++) {
            var d = drops[i];
            var x = d.x * w;
            var y = d.y * h;
          
            ctx.globalAlpha = d.opacity;
            ctx.beginPath();
            ctx.moveTo(x, y);
            ctx.lineTo(x - 2, y + d.length * h);  // 斜线雨滴
            ctx.stroke();
        }
        ctx.globalAlpha = 1.0;
    }
}
```

> ⚠️ Canvas 在 100+ 粒子时性能可接受，但不建议超过 200 个。对于更密集的效果应使用 ShaderEffect。

---

## 六、背景切换机制（WeatherBackground.qml）

```qml
// WeatherBackground.qml —— 核心调度器
import QtQuick

Item {
    id: root
    anchors.fill: parent
  
    // 天气数据
    property int weatherCode: 1000       // 天气代码
    property bool isDay: true            // 是否白天
    property real transitionDuration: 800  // 过渡动画时长 ms
  
    // 当前活跃背景
    property Item currentBackground: null
  
    // 天气码到组件的映射
    function backgroundForCode(code, day) {
        if (!day) return "qrc:/qml/backgrounds/NightBackground.qml";
      
        // 晴天类
        if (code === 1000) return "qrc:/qml/backgrounds/SunnyBackground.qml";
      
        // 多云类
        if (code >= 1003 && code <= 1030) 
            return "qrc:/qml/backgrounds/CloudyBackground.qml";
      
        // 雨类
        if ((code >= 1063 && code <= 1201) || 
            (code >= 1240 && code <= 1246))
            return "qrc:/qml/backgrounds/RainBackground.qml";
      
        // 雪类
        if ((code >= 1114 && code <= 1117) || 
            (code >= 1210 && code <= 1225))
            return "qrc:/qml/backgrounds/SnowBackground.qml";
      
        // 雷暴
        if (code >= 1087 && code <= 1087)
            return "qrc:/qml/backgrounds/ThunderBackground.qml";
      
        // 默认多云
        return "qrc:/qml/backgrounds/CloudyBackground.qml";
    }
  
    // 双层 Loader 实现淡入淡出过渡
    Loader {
        id: loaderOld
        anchors.fill: parent
        opacity: 0
      
        Behavior on opacity {
            NumberAnimation { duration: root.transitionDuration }
        }
    }
  
    Loader {
        id: loaderNew
        anchors.fill: parent
        source: backgroundForCode(root.weatherCode, root.isDay)
      
        onLoaded: {
            root.currentBackground = item;
        }
    }
  
    // 监听天气变化，触发过渡
    onWeatherCodeChanged: switchBackground()
    onIsDayChanged: switchBackground()
  
    function switchBackground() {
        var newSource = backgroundForCode(weatherCode, isDay);
        if (loaderNew.source === newSource) return;
      
        // 移到旧层
        loaderOld.source = loaderNew.source;
        loaderOld.opacity = 1;
      
        // 加载新背景
        loaderNew.source = "";
        loaderNew.source = newSource;
      
        // 淡出旧层
        loaderOld.opacity = 0;
    }
}
```

---

## 七、ShaderEffect 使用注意事项（Qt6 特有问题）

### 7.1 Qt5 → Qt6 变化

Qt6 中 ShaderEffect 发生了重大变化 [19]：

| Qt5 | Qt6 |
|-----|-----|
| `fragmentShader: "..."` 内联 GLSL | `fragmentShader: "file.frag"` 引用文件 URL [6] |
| 直接写 GLSL | 需通过 `qsb` 工具编译为 `.qsb` [9] |
| 内置 QtGraphicalEffects | 已移除，需用 Ergosign/qml-shader-effects 替代 [9] |
| `property var source` | 使用 `sampler2D` 在 binding 1 [6] |

### 7.2 qsb 编译流程

```bash
# 将 GLSL 编译为 Qt Shader Baker 格式
qsb --glsl "430" -o rain.frag.qsb rain.frag
qsb --glsl "430" -o snow.frag.qsb snow.frag
qsb --hlsl 50 -o rain.frag.qsb rain.frag    # Windows/D3D
qsb --msl 20 -o rain.frag.qsb rain.frag     # macOS/Metal
```

然后在 QML 中引用 `.qsb` 文件：
```qml
fragmentShader: "qrc:/shaders/rain.frag.qsb"
```

### 7.3 运行时回退

```qml
ShaderEffect {
    id: shader
    anchors.fill: parent
    fragmentShader: "qrc:/shaders/rain.frag.qsb"
  
    // 如果 shader 不支持，回退到纯色
    status: ShaderEffect.Error ? fallback.visible = true : fallback.visible = false
}

Rectangle {
    id: fallback
    anchors.fill: parent
    visible: false
    gradient: Gradient {
        GradientStop { position: 0; color: "#2c3e50" }
        GradientStop { position: 1; color: "#4a6670" }
    }
}
```

---

## 八、推荐实现路径

```
阶段1 (1-2天)                阶段2 (3-5天)              阶段3 (2-3天)
┌─────────────────┐    ┌─────────────────────┐    ┌─────────────────┐
│ Rectangle 渐变   │ →  │ Canvas 粒子效果      │ →  │ ShaderEffect    │
│ 纯色/渐变背景    │    │ RainBackground      │    │ GPU 全效果      │
│ (立即可用)      │    │ SnowBackground      │    │ 雨/雪/星空/光晕 │
│                 │    │ (回退方案)           │    │ (最终方案)      │
└─────────────────┘    └─────────────────────┘    └─────────────────┘
```

> **我推測**的路径：先用 Rectangle 渐变快速搭建骨架 → 再用 Canvas 实现粒子逻辑验证 → 最后将粒子逻辑移植到 GLSL 获得 GPU 性能。这样可以保证每个阶段都有可用的视觉效果。

---

## 九、关键参考资源

| 资源 | 用途 |
|------|------|
| [Qt6 ShaderEffect 文档](https://doc.qt.io/qt-6/qml-qtquick-shadereffect.html) [6] | ShaderEffect API 参考 |
| [Ergosign/qml-shader-effects](https://github.com/Ergosign/qml-shader-effects) [9] | Qt6 预置 shader 效果库（MIT） |
| [Woboq GPU Drawing](https://woboq.com/blog/gpu-drawing-using-shadereffects-in-qtquick.html) [4] | ShaderEffect 原理详解 |
| [QML Book Ch.11](https://qmlbook.github.io/ch11-shaders/shaders.html) [5] | GLSL 入门教程 |
| [basysKom Qt5→Qt6 迁移](https://www.basyskom.de/en/qt-6-how-to-port-shader-effects-from-qt-5) [19] | Shader 迁移指南 |
| [Cyanilux Rain Effects](https://www.cyanilux.com/tutorials/rain-effects-breakdown) [11] | 雨天效果设计思路 |
| [Rain Shader Live Demo](https://rain-shader.nordicbeaver.io/) [10] | 玻璃雨滴效果参考 |

---

需要我进一步展开某个具体的 shader（比如带闪电的雷暴效果、或者云层漂移的 Perlin Noise 实现）吗？