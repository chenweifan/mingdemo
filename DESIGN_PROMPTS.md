# 界面 UI 组件生图提示词包 · Design Prompt Pack

用于生成**风格基准图与组件规范图**，再据此校准 `index.html` 的视觉风格。
提示词严格对齐站点已落地的设计令牌（深海暗色 + 共鸣青），生成的图可以直接当作设计稿比对。

> **重要**：站点是单文件零依赖交付，生成图**不会**作为外链素材嵌入页面。
> 它们的用途是**风格基准**——配色、圆角、层次、光效强度、密度对齐后，改的是 CSS 令牌。

---

## 0 · 推荐工作流

```
① 先生成 01 主风格板  ──►  确认整体气质（不满意就只重跑这一张）
                             │
② 用风格板作为参考图  ──►  --sref（MJ）或 ControlNet/IP-Adapter（SD）锁定一致性
                             │
③ 批量生成 02–07 组件图  ──►  组件规范：按钮 / 卡片 / 表单 / 浮层 / 数据可视化
                             │
④ 按需生成 08–13 页面图  ──►  整页版式参考：Hero / 日历 / 配队 / 社区
                             │
⑤ 把图放进 design/refs/ ──►  Agent 用 read_image 读图，提取主色与质感参数，
                             回灌到 :root 令牌（见第 7 节映射表）
```

**一致性三条铁律**：同一段风格锚点、同一个 seed、同一张 `--sref` 参考图。
换主题时只改风格锚点，其余提示词不动。

---

## 1 · 通用风格锚点（Style Anchor）

所有提示词都必须拼接这一段。**它是整套图风格统一的唯一来源。**

### 英文（MJ / SD / Flux 用）

```
dark deep-sea sci-fi game UI design system, abyssal navy background
(#05080d to #1c2a39), faint 56px sonar grid with radial cyan glow fading to edges,
frosted glass panels with 1px cyan hairlines and a subtle specular highlight along the top edge,
soft outer glow, resonance cyan (#4fd1c5) primary accent, sonic indigo (#6ea8fe) secondary,
tide gold (#e5c07b) for highlights, rounded 16-22px corners, pill-shaped controls,
soundwave equalizer motif, concentric resonance rings, tabular numerals,
clean modern sans-serif, high contrast dark theme, crisp vector UI design sheet,
flat front view, orthographic, no perspective, no device mockup, no hands, no people
```

### 中文（即梦 / 豆包 / 文心 / 可灵 用）

```
深海科幻游戏 UI 设计系统，深渊藏青底色（#05080d 到 #1c2a39），
极淡的 56 像素声呐网格并向边缘径向淡出，磨砂玻璃质感面板配 1 像素青色发丝描边，
顶部一道高光，柔和外发光，共鸣青（#4fd1c5）为主强调色、声波靛（#6ea8fe）为次强调色、
潮汐金（#e5c07b）点级高光，16–22 像素圆角，胶囊形控件，声波频谱与同心共鸣环元素，
等宽对齐数字，现代无衬线字体，暗色高对比，矢量 UI 设计稿，正视角平面图，
无透视，无设备样机，无人物
```

### 通用负向提示词（Negative）

```
light theme, white background, pastel, photorealistic, 3d render, device mockup,
laptop screen, phone frame, perspective, isometric, drop shadow blur, cluttered,
low contrast, blurry, watermark, signature, gibberish text, distorted letters,
emoji, cartoon mascot, stock photo, people, hands, neon rainbow, oversaturated
```

---

## 2 · 基准层

### 01 · 主风格板 Style Board

**用途**：整套图的“母版”，后续所有图都用它做 `--sref` 参考。

| 参数 | 值 |
|---|---|
| 比例 | 16:9（`--ar 16:9`） |
| 画面 | 左侧色卡与材质条，中部 2–3 个代表组件（主按钮 / 玻璃卡片 / 评分环），右侧声波与网格纹样 |

```
[风格锚点] + UI style board / mood board layout, left column shows five stacked color
swatches (abyss navy, sunken panel, base panel, raised panel, overlay panel) with thin cyan
dividers, center shows one primary pill button with cyan-to-indigo gradient and one glass card
with corner bracket accents, right side shows a soundwave equalizer bar cluster and three
concentric resonance rings, thin annotation lines connecting elements, generous negative space,
designer spec sheet aesthetic --ar 16:9 --style raw --stylize 120
```

---

## 3 · 组件层（核心交付）

### 02 · 组件总表 Component Sheet

| 参数 | 值 |
|---|---|
| 比例 | 3:2 |
| 必含 | 按钮 4 态、芯片/标签、输入框、卡片、进度条、标签徽章 |

```
[风格锚点] + UI component sheet, neatly arranged grid with thin cyan separator lines and small
labels, includes: a pill button in default / hover / active / disabled states, a cyan-to-indigo
gradient primary button, filter chips in default and selected (cyan glow) states, small tags in
cyan / red / gold variants, one text input in default and focused state with a 3px cyan focus ring,
one glass card with top hairline highlight, a slim gradient progress bar, a synergy score ring with
tick marks, organized in labeled rows, flat front view --ar 3:2 --style raw --stylize 100
```

### 03 · 按钮四态特写 Button States

```
[风格锚点] + close-up study of pill-shaped UI buttons on dark navy glass panel, four states in a
row with small captions: default (dark panel, 1px muted cyan border), hover (raised panel, cyan
border and cyan text, soft glow), active (pressed, scaled down, brighter cyan), disabled (dimmed,
low contrast, no glow), plus one large primary button with cyan-to-indigo 135-degree gradient and
dark teal text, crisp edges, high detail --ar 1:1 --style raw --stylize 100
```

### 04 · 卡片族 Cards

```
[风格锚点] + four UI cards arranged 2x2 on abyss navy, each with 16-22px rounded corners, 1px
cyan hairline on top edge, glass surface: (1) plain content card, (2) hovered card lifted 2px with
cyan glow ring and a diagonal light sweep, (3) card with a corner bracket accent in the top-right,
(4) element-themed card with a soft colored aura at the bottom (cyan, gold, violet, blue variants),
thin inner separators, minimal placeholder text lines --ar 1:1 --style raw --stylize 100
```

### 05 · 表单与校验 Forms

```
[风格锚点] + form component study on dark navy: a sunken input field with 1px subtle border and
placeholder text, the same field focused with cyan border plus 3px soft cyan outer glow ring, an
error state with red (#e06c75) border and red glow plus a small red helper line with warning icon,
a multi-line textarea with a character counter in the corner, toggle chips for category selection,
clean vertical stacking with generous spacing --ar 1:1 --style raw --stylize 100
```

### 06 · 浮层：模态 / Toast / 骨架屏 / 空态

```
[风格锚点] + overlay components floating over a dimmed blurred backdrop: a centered modal dialog
with 22px radius, overlay panel color, strong elevation shadow, cyan gradient hairline along its
top edge and a close icon; a stack of two pill toasts at the bottom with a check icon in a tinted
circle; a skeleton placeholder card with a shimmer sweep; an empty state panel with dashed border,
a faint radial cyan glow at the top, a thin-line sonar illustration, one line of text and a primary
button, layout arranged as a design sheet --ar 3:2 --style raw --stylize 110
```

### 07 · 数据可视化 Data Viz

```
[风格锚点] + dark UI data visualization set: a slim gradient progress bar at 30/70/92 percent with
tabular numerals beside it, a large synergy score ring with dashed tick marks, cyan-to-indigo
gradient arc, glowing stroke and a big number in the center, a pentagon radar chart with 3
concentric grid rings, translucent cyan filled area and cyan dots on each axis, small stat blocks
with big numeric values and uppercase micro labels, all aligned on a baseline grid
--ar 1:1 --style raw --stylize 110
```

---

## 4 · 页面层（版式参考）

### 08 · 声骸图鉴卡网格 Codex Grid

```
[风格锚点] + dark game codex grid of 6 collectible cards on abyss navy, each card: element-tinted
radial aura rising from the bottom, a slowly rotating dashed rune ring behind a large centered
glyph, a small cost badge in the top-left, a bookmark icon button in the top-right, title row with
a small colored element tag, a slim rating bar with a gold number, muted body text lines,
element colors cycling cyan / gold / violet / blue / red / lilac --ar 16:9 --style raw --stylize 110
```

### 09 · Hero 主视觉 Hero Section

```
[风格锚点] + website hero section, left aligned headline in large light type with a cyan-to-indigo
gradient on part of the text, a small pill badge above it with a pulsing cyan dot, one short
paragraph, two pill buttons (gradient primary + outline), a row of four numeric stats separated by
thin vertical gradient dividers, at the bottom edge a 40-bar soundwave equalizer in cyan fading to
transparent, background has two large blurred cyan and indigo light orbs and three concentric
pulsing resonance rings on the right, dramatic but clean --ar 16:9 --style raw --stylize 130
```

### 10 · 版本日历 Calendar

```
[风格锚点] + dark month calendar UI, 7-column grid of day cells with 12px radius on sunken panels,
weekend days slightly dimmer, days with events marked by a 2px cyan-to-indigo bar along the top edge
and up to three small colored dots (cyan / gold / indigo / violet by category), the selected day
highlighted with a bright cyan border and outer glow, a right side panel listing that day's schedule
as rows with a monospace time column and a small category tag, month title in monospace numerals
with round icon buttons for previous / next --ar 3:2 --style raw --stylize 110
```

### 11 · 配队模拟 Team Builder

```
[风格锚点] + dark game team builder UI, three large empty slot cards in a row with dashed cyan
borders and a plus icon, one slot filled with a circular avatar, character name, role tag and a
small power number, a right side score panel with a large synergy ring, four labeled metric bars
underneath and a verdict line, at the bottom a hint list with small check icons, one share button
disabled in a muted state, one resonance ring ripple effect on the filled slot
--ar 16:9 --style raw --stylize 110
```

### 12 · 社区帖子流 Community Feed

```
[风格锚点] + dark community forum UI, a composer card with title input, textarea and category
chips plus a small character counter and a gradient submit button, below it a vertical list of post
cards each with a 2px colored accent bar on the left edge (cyan / gold / indigo / violet by
category), a small circular avatar, author name, relative timestamp with a tiny clock icon, a
category tag on the right, post title and two lines of body text, a like button with a heart icon
and tabular count, clean spacing --ar 16:9 --style raw --stylize 110
```

### 13 · 吸顶导航 Sticky Nav

```
[风格锚点] + slim sticky top navigation bar, 62px height, translucent dark glass with backdrop
blur, left side a small square logo mark with a soundwave glyph plus two-line wordmark, center a
row of seven text links where the active one is a cyan pill with soft glow and the others are muted,
right side a small gradient primary button and a hamburger icon, a faint cyan gradient scan line
running along the bottom edge of the bar --ar 21:9 --style raw --stylize 100
```

---

## 5 · 图标层

### 14 · 图标集 Icon Set

```
[风格锚点] + UI icon set, 24x24 grid, 1.6px stroke weight, rounded caps and joins, consistent
optical sizing, monochrome light cyan on dark navy tiles with 9px radius, icons: home, news,
calendar, layered stack, three users, chat bubble, single user, close, search, star, bookmark, plus,
trash, heart, arrow right, sparkle, check, chevron left, chevron right, share, edit pen, eye,
shield, bar chart, warning triangle, refresh, clock, soundwave, arranged in a neat 7x4 grid
--ar 1:1 --style raw --stylize 90
```

---

## 6 · 参数与平台建议

| 平台 | 关键参数 |
|---|---|
| **Midjourney v6.1** | `--ar <比例> --style raw --stylize 100~130 --v 6.1`；一致性：`--sref <01号图URL> --sw 80`；同批次固定 `--seed` |
| **Flux / SDXL** | 1024×1024 或 1344×768；Flux：steps 28–32、guidance 3.5–4.5；SDXL：steps 30、CFG 6.5–7.5、DPM++ 2M Karras；可加 UI/design 类 LoRA（权重 0.5–0.7） |
| **即梦 / 豆包 / 文心** | 直接用中文锚点 + 中文提示词；比例选 16:9 / 3:2 / 1:1；风格选「设计稿 / 扁平矢量 / 3D 免」；关掉「写实」 |
| **可灵 / 混元** | 提示词末尾补「矢量 UI 设计稿，正视角，无透视，无样机」 |

**出图比例建议**：组件特写用 1:1，组件总表 3:2，整页版式 16:9，导航条 21:9。

**文字处理**：AI 生图的中文几乎必错。建议让图里只出现**占位文本块**（灰色短线），
真实文案由页面渲染——提示词中已用 `placeholder text lines` / `muted body text lines` 表达这一点。

---

## 7 · 从图到代码：映射表

生成图后，按这张表把视觉特征换算成令牌。这是「用图优化界面风格」的落地方式。

| 图中特征 | 对应令牌 / 类 | 调整方式 |
|---|---|---|
| 背景基色与层级差 | `--surface-abyss / sunken / base / raised / overlay` | 吸管取色后替换，保持 5 档明度递增 |
| 主强调色、次强调色 | `--resonance` / `--sonic` | 替换色值，同步更新 `--resonance-glow` 的 rgba |
| 点级高光色（数字、套装名） | `--tide-gold` | 替换色值 |
| 卡片圆角与内边距 | `--r-lg` / `--sp-4` / `--card-min` | 按图中圆角半径与卡片密度调整 |
| 玻璃面板透明度 | `--glass` / `--nav-bg` / `--blur` | 图中越透则降 alpha、升 `--blur` |
| 顶部发丝高光 | `--hairline` / `--hairline-v` | 调整中段 `--stroke-strong` 的透明度 |
| 外发光强度 | `--glow-resonance` / `--halo-soft` / `--resonance-glow` | 图中光晕越强则放大扩散半径或提高 alpha |
| 悬停位移与扫光 | `--enter-y` / `--sheen` / `--sheen-w` | 对齐图中悬停态的位移量与高光宽度 |
| 网格密度 | `--grid-size` / `--grid-opacity` | 数图中网格间距，改这两个值 |
| 元素色环 | `--elem-*`（6 个） | 逐个吸管取色替换 |
| 评分环刻度与粗细 | `--tick` / `--bw-2` / `.ring__bar` 的 `stroke-width` | 对齐图中刻度间距与环宽 |
| 按钮胶囊半径 | `--r-pill` | 若图中为圆角矩形则改 `--r-md` |
| 入场节奏 | `--enter-dur` / `--enter-step` | 按图中动效暗示调整时长与逐条延迟 |

**取图方式**：把生成图放到仓库的 `design/refs/` 目录（建议命名 `01-style-board.png`、
`02-component-sheet.png` …），然后让 Agent 读取——它会用图像读取能力提取主色与质感，
按上表回灌到 `:root`，并跑一遍回归（令牌完整性、7 路由渲染、无障碍与零外部依赖约束）。

---

## 8 · 提示词速查（可直接复制）

按顺序复制粘贴即可，`[风格锚点]` 替换为第 1 节的英文整段：

| # | 名称 | 比例 | 提示词主体 |
|---|---|---|---|
| 01 | 主风格板 | 16:9 | `UI style board / mood board layout, ...` |
| 02 | 组件总表 | 3:2 | `UI component sheet, neatly arranged grid ...` |
| 03 | 按钮四态 | 1:1 | `close-up study of pill-shaped UI buttons ...` |
| 04 | 卡片族 | 1:1 | `four UI cards arranged 2x2 ...` |
| 05 | 表单与校验 | 1:1 | `form component study on dark navy ...` |
| 06 | 浮层组件 | 3:2 | `overlay components floating over a dimmed blurred backdrop ...` |
| 07 | 数据可视化 | 1:1 | `dark UI data visualization set ...` |
| 08 | 图鉴卡网格 | 16:9 | `dark game codex grid of 6 collectible cards ...` |
| 09 | Hero 主视觉 | 16:9 | `website hero section, left aligned headline ...` |
| 10 | 版本日历 | 3:2 | `dark month calendar UI, 7-column grid ...` |
| 11 | 配队模拟 | 16:9 | `dark game team builder UI, three large empty slot cards ...` |
| 12 | 社区帖子流 | 16:9 | `dark community forum UI, a composer card ...` |
| 13 | 吸顶导航 | 21:9 | `slim sticky top navigation bar, 62px height ...` |
| 14 | 图标集 | 1:1 | `UI icon set, 24x24 grid, 1.6px stroke weight ...` |

完整提示词见第 2–5 节，每节标题下即为可直接使用的整段文本。
