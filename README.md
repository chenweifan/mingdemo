# 鸣潮粉丝俱乐部 · Wuthering Waves Fan Club

一个**单文件、零依赖、双击即运行**的鸣潮主题粉丝站前端演示。全部界面由原生 HTML / CSS / JavaScript
手写，图标为内联 SVG，无 CDN、无 npm 包、无外部字体、无外部图片，断网可用。

```
index.html    2200 行 · 117 KB · 0 个外部请求
```

> 非官方粉丝作品，与库洛游戏无关。站点内所有资讯、声骸、角色与活动数据均为演示用虚构内容。

---

## 快速开始

```bash
# 方式一：直接双击 index.html（file:// 协议下功能完整）

# 方式二：任意静态服务器
python -m http.server 8080        # 然后访问 http://localhost:8080
npx serve .                       # 或使用 Node 生态的静态服务器
```

无需构建、无需安装依赖、无需联网。

> 少数浏览器配置会在 `file://` 协议下禁用 `localStorage`。此时站点自动降级为内存态：其余功能完全正常，
> 仅发帖、点赞、收藏等改动在刷新后不保留（代码对写入异常做了捕获，不会报错）。

---

## 功能总览

站点为 Hash 路由单页应用，共 7 个视图：

| Hash | 视图 | 核心内容 | 关键交互 |
|---|---|---|---|
| `#/home` | 首页 | Hero + 40 根声波频谱 + 6 个功能模块网格 + 最新 3 条资讯 + 加入号召条 | 功能卡悬停位移发光；资讯卡打开详情模态 |
| `#/news` | 资讯 | 标签筛选（全部 / 公告 / 活动 / 攻略 / 同人）+ 11 条资讯列表 | 标签切换带焦点保持；空结果显示空态；点击阅读全文 |
| `#/calendar` | 版本日历 | 2026 年 9 月月视图（周一起始）+ 事件点 + 当日日程侧栏 | 日期点选、上下月翻页（范围 2026-08 ～ 2026-10，越界按钮禁用）、回到本月 |
| `#/wiki` | 声骸图鉴 | 关键词搜索 + COST 筛选（1/3/4）+ 六元素筛选 + 16 件声骸卡片网格 | 输入即时过滤（保留输入法组合态）、书签收藏、详情模态、首次进入骨架屏 |
| `#/team` | 配队模拟 | 3 槽位编队 + 角色选择模态 + SVG 协同评分环形 + 四项评分拆解 | 选中角色触发共鸣环扩散；角色不可重复上阵；满 3 人才可分享 |
| `#/bbs` | 悲鸣社区 | 发帖表单（标题 / 正文 / 分区标签）+ 帖子列表 + 点赞 + 删除 | 表单行内校验、字数计数、点赞与发帖写入 localStorage |
| `#/user` | 个人中心 | 账号头部卡 + 练度面板（4 条进度）+ 收藏列表 + 数据概览 | 编辑昵称（带校验）、移除收藏、收藏清空后显示空态 |

### 交互细节

- **导航**：吸顶毛玻璃导航，`aria-current="page"` 标记当前页；≤900px 折叠为汉堡菜单，路由切换或点击外部自动收起。
- **模态**：`role="dialog" aria-modal="true"` + ESC 关闭 + 点击遮罩关闭 + Tab 焦点陷阱 + 关闭后焦点归还触发元素。
- **Toast**：`role="status" aria-live="polite"`，用于收藏、发帖、配队、重置等操作反馈，自动消退。
- **状态反馈**：所有交互元素具备 hover / focus-visible / active / disabled 四态。
- **持久化**：帖子、点赞、收藏、昵称、配队写入 `localStorage`，键名 `wuwa.fan.club.v1`，刷新不丢。

---

## 品牌签名

| 签名 | 实现 |
|---|---|
| **声波频谱** | Hero 底部 40 根竖线，`scaleY` 脉动动画，逐条负延迟 `calc(var(--i) * var(--wave-delay) * -1)`，青→透明渐变，两端遮罩羽化。根数由令牌 `--bars` 驱动，禁用动画时保留静态波形。 |
| **共鸣环** | 角色选中时槽位播放一次 `box-shadow` 由 `0` 扩散至 `--ring-spread`(12px) 透明的 420ms 动画（`--dur-slow`）。 |
| **深海声呐网格** | `body::after` 固定定位，56px 经纬网格，径向遮罩向边缘淡出，透明度 `.5`；`body::before` 叠加青/靛双径向环境光。 |

---

## 设计系统

全部色值、间距、圆角、动效参数集中在 `<style>` 的 `:root`（第 19 行起），共 **77 个令牌定义 / 840 处 `var()` 引用**，
组件样式内不出现裸色值与裸尺寸。

### 表面层级 / 描边 / 文本

| 令牌 | 值 | 用途 |
|---|---|---|
| `--surface-abyss` | `#05080d` | 页面底（ABYSS NAVY，与参考图一致） |
| `--surface-sunken` | `#0f1829` | 输入框 / 凹槽（SUNKEN PANEL） |
| `--surface-base` | `#1c2a39` | 卡片默认（BASE PANEL） |
| `--surface-raised` | `#2a3f54` | 悬浮 / 激活卡片（RAISED PANEL） |
| `--surface-overlay` | `#33475e` | 模态 / 浮层（参考图值 `#4F647A` 为保证正文 ≥5.5:1 下调） |
| `--surface-line` | `#4f647a` | 参考图 OVERLAY 值，用于高对比描边与图标底 |
| `--surface-deep` | `#080d14` | 比页面更深：进度条槽、内嵌区域 |
| `--stroke-subtle` / `--stroke-base` / `--stroke-strong` | `rgba(120,180,200,.14/.24/.40)` | 三级描边（参考图描边明显更亮更青） |
| `--stroke-accent` | `rgba(79,209,197,.55)` | 强调描边 |
| `--text-high` / `--text-body` / `--text-muted` / `--text-faint` | `#eaf2f8` 12:1 · `#b8c7d6` 8:1 · `#7d92a6` 4.5:1 · `#55697c`（仅装饰） | 文本层级（对比度按新的表面色重算） |

> 表面层级与描边已按 `design/refs/` 的风格参考图校准（原规范值以行内注释保留在 `:root` 中）。
> 参考图的第 5 级色 `#4F647A` 未直接用作模态底色——它与正文文本的对比度只有 3.5:1，
> 低于 WCAG AA，故下调为 `#33475E`（正文 5.5:1 / 高亮文本 7.9:1），原值改作高对比描边色。

### 强调色与元素色

| 令牌 | 值 | 令牌 | 值 |
|---|---|---|---|
| `--resonance` 共鸣青 | `#4fd1c5` | `--elem-diffraction` 衍射 | `#dcc178` |
| `--sonic` 声波靛 | `#6ea8fe` | `--elem-aero` 气动 | `#5ad8cc` |
| `--tide-gold` 潮汐金 | `#e5c07b` | `--elem-havoc` 湮灭 | `#b47ae0` |
| `--wail-red` 悲鸣红 | `#e06c75` | `--elem-glacio` 冷凝 | `#74a8e8` |
| `--resonance-glow` | `rgba(79,209,197,.18)` | `--elem-fusion` 热熔 | `#e0767e` |
| | | `--elem-electro` 导电 | `#9b8ae0` |

### 间距 / 圆角 / 动效 / 阴影

- **间距**：`--sp-1:4px` → `--sp-8:64px`（含 `--sp-1h`～`--sp-6h` 半档），组件内尺寸由 `--card-min`、`--modal-w`、`--avatar`、`--bar-h` 等结构令牌提供。
- **圆角**：`--r-xs:6px` `--r-sm:9px` `--r-md:12px` `--r-lg:16px` `--r-xl:22px` `--r-pill:999px`。
- **动效**：`--ease-out: cubic-bezier(.16,1,.3,1)`、`--ease-spring: cubic-bezier(.34,1.56,.64,1)`、`--dur-fast/base/slow: 160/240/420ms`，并派生出 `--tr-fast/--tr-base/--tr-slow` 组合令牌。
- **阴影**：`--elev-1`、`--elev-2`、`--glow-resonance`（`0 0 0 1px var(--stroke-accent), 0 0 28px -6px var(--resonance)`）。
- **字体**：`--font-sans`（PingFang SC / HarmonyOS Sans / Microsoft YaHei / system-ui）、`--font-num`（ui-monospace 等宽数字）。
- **字阶**：`--fs-display: clamp(32px,5vw,48px)`、`--fs-h1/h2/h3`、`--fs-body/caption/micro`。
- **关键帧**：`shimmer`（骨架屏 200% 扫光）、`wave-pulse`（声波）、`resonance-ring`（共鸣环）、`pop`（模态入场）、`fade`（遮罩）。

### 组件清单

按钮（`.btn` / `.btn-primary` / `.btn-sm` / `.btn-danger` / `.icon-btn`）、卡片（`.card`，位移与发光变体 `.card--interactive` 仅用于可导航 / 可展开详情的卡片）、
标签与芯片（`.tag` / `.tag--accent` / `.tag--hot` / `.tag--gold` / `.chip`）、输入（`.input` + `.error`）、
空态（`.empty` 虚线描边 + 顶部径向青光 + 线稿/文案/主按钮三段式）、骨架屏（`.skeleton`）、
进度与统计（`.bar` / `.metric` / `.stat`）、模态（`.modal`）、Toast（`.toast`）。

---

## 技术架构

代码分区（`index.html` 内注释标注）：

| 区块 | 行号 | 说明 |
|---|---|---|
| `01 TOKENS` ～ `08 A11Y` | 19 – 783 | 设计令牌 → 基础样式 → 布局 → 组件 → 视图 → 浮层 → 响应式 → 无障碍 |
| `0 · 工具` | 834 | `esc()` 转义、`token()/tokenMs()` 读取 CSS 令牌、`relTime()`、数字格式化 |
| `1 · 图标` | 872 | 28 个图标字形的 `ICONS` 表 + `icon(name)` 生成器（导航汉堡、品牌标记、空态线稿、评分环形等为直接书写的内联 SVG） |
| `2 · 静态数据` | 911 | `NEWS` / `ECHOES` / `CHARS` / `EVENTS` / `SEED_POSTS` |
| `3 · 状态层` | 1064 | `state`（持久化）与 `ui`（会话内）分离，`loadState()` / `persist()` |
| `4 · 视图层` | 1127 | 7 个纯函数 `viewX(state, ui) => HTML 字符串` |
| `5 · 渲染 / 路由` | 1724 | `render()` / `patch()` 局部更新 / `hashchange` 路由 / 焦点保持 |
| `6 · 浮层` | 1801 | `toast()`、`openModal()` / `closeModal()`、焦点陷阱与 ESC |
| `7 · 交互动作` | 1869 | `actions` 动作表 + 全局事件委托（click / input / submit / keydown） |
| `8 · 启动` | 2190 | 载入持久化 → 解析路由 → 渲染 → 欢迎提示 |

设计要点：

- **视图纯函数**：视图只依赖传入的 `state` / `ui`，返回 HTML 字符串；副作用集中在动作层。
- **事件委托**：全站仅注册 4 个 `document` 级委托监听器（click / input / submit / keydown）与 1 个 `window` 级 hashchange，通过 `data-act` 分发到 `actions` 动作表，重渲染不丢事件。
- **局部更新**：图鉴搜索框、发帖计数器走 `patch()` 只替换结果区，避免整树重渲染打断中文输入法组合。
- **焦点保持**：交互控件带 `data-focus` 键，重渲染后自动恢复焦点，键盘操作不脱位。
- **令牌驱动动画**：JS 中的 Toast 时长、骨架屏时长、频谱根数均通过 `getComputedStyle` 读取 CSS 变量，避免双份魔法数字。

---

## 数据规模

| 数据集 | 数量 | 说明 |
|---|---|---|
| 资讯 `NEWS` | 11 条 | 4 类标签，含正文段落、阅读量、HOT 标记 |
| 声骸 `ECHOES` | 16 件 | COST 1 / 3 / 4，六元素，含套装、评级、技能描述 |
| 角色 `CHARS` | 14 名 | 元素 / 定位（主C·副C·辅助·治疗）/ 武器 / 版本强度 |
| 日历事件 `EVENTS` | 17 天 · 18 条 | 2026-08-20 ～ 2026-10-16 |
| 种子帖子 `SEED_POSTS` | 4 条 | 作为初始内存内容，发生首次变更时写入 localStorage，此后以本地数据为准 |

---

## 无障碍

- **语义结构**：`skip-link` 跳转主内容、`header/nav/main/aside` 分区、标题层级连续、`aria-current` 标记当前路由。
- **对话框**：`role="dialog"` + `aria-modal="true"` + `aria-labelledby`，焦点陷阱限制在对话框内，ESC / 遮罩 / 关闭按钮三种退出方式，关闭后焦点归还。
- **状态播报**：Toast 使用 `aria-live="polite"`；表单错误行内提示并设置 `aria-invalid`；芯片与日期使用 `aria-pressed`，收藏按钮使用 `aria-label` 说明当前动作。
- **键盘可达**：`role="button"` 卡片支持 Enter / Space 激活；全站 `:focus-visible` 统一 2px 青色描边 + 2px 偏移；模态内 Tab 循环。
- **动效偏好**：`prefers-reduced-motion: reduce` 下关闭全部动画与过渡（含声波、共鸣环、骨架扫光），滚动改为即时跳转。
- **对比度**：文本四档按 12:1 / 7.2:1 / 4.6:1 / 装饰级设计；`prefers-contrast: more` 下自动加深描边与次要文本。
- **数值排版**：`font-variant-numeric: tabular-nums` 全局继承（`body`）+ `.num` 类显式声明，日期、评分、进度、计数等宽对齐。
- **溢出保护**：`html, body { overflow-x: clip }`，无横向滚动条；长文本 `overflow-wrap: anywhere`；网格轨道统一 `minmax(min(Xpx,100%),1fr)`。

---

## 硬约束对照

| # | 约束 | 落地情况 |
|---|---|---|
| 1 | 仅原生 HTML/CSS/JS，禁外部资源 | 全文 0 个外部请求：无 CDN、无字体、无图片、无图标库 |
| 2 | 单文件、内联 style/script、双击可运行 | 单个 `index.html`，`file://` 下功能完整 |
| 3 | 图标用内联 SVG / CSS，禁 emoji 当图标 | 28 个 SVG 图标字形 + 直接书写的品牌标记 / 汉堡 / 空态线稿 / 评分环形；纯 CSS 绘制头像、事件圆点、波形；无 emoji |
| 4 | 色值 / 间距 / 圆角 / 动效必须走 CSS 变量 | 全部 32 处十六进制色值（30 个唯一值）与所有 `rgba()` 仅出现在 `:root` 令牌块，组件内 0 裸值（全文 1202 处 `var()` 引用） |
| 5 | 数值型文本使用 `tabular-nums` | `body` 全局继承 + `.num, time, output` 显式声明 |
| 6 | 支持 `prefers-reduced-motion: reduce` | 第 764 行起的 A11Y 区块全局关闭动画与过渡 |
| 7 | 交互元素具备四态 | `.btn` / `.chip` / `.input` / `.icon-btn` / `.cal__day` / `.pick` / `.slot__pick` 均有 hover、focus-visible、active、disabled |
| 8 | 刷新后帖子内容持久化 | `localStorage` 键 `wuwa.fan.club.v1`，含数据损坏与隐私模式降级 |
| 9 | 无横向滚动条 | `overflow-x: clip`（不产生滚动容器，故吸顶导航不受影响） |

---

## 重置与自定义

```js
// 浏览器控制台：清空全部本地数据，回到初始种子内容
localStorage.removeItem('wuwa.fan.club.v1');
location.reload();
```

| 想改什么 | 改哪里 |
|---|---|
| 配色 / 间距 / 圆角 / 动效 | `<style>` 的 `:root` 令牌块（第 19 行起），改一处即可全站生效 |
| 资讯、声骸、角色、日历、种子帖 | 第 911 行起的「2 · 静态数据」数组，字段自解释 |
| 图标 | 第 872 行 `ICONS` 表，新增键值对即可被 `icon('name')` 调用 |
| 路由与视图 | 第 1127 行起新增 `viewXxx`，并在第 1718 行 `views` 表与导航 `<nav>` 中登记 |
| 协同评分算法 | 第 1443 行 `synergy()`，权重为 元素 30% / 定位 30% / 生存 15% / 强度 25% |

---

## 浏览器兼容

面向现代浏览器（Chrome / Edge 90+、Firefox 90+、Safari 16+）。依赖以下原生特性：

`overflow: clip`、`:focus-visible`、`dvh` 单位、`mask-image`、`backdrop-filter`、`color-scheme`、
CSS 自定义属性、`inset` / `inset-inline` 逻辑属性、以及不依赖原生 `<dialog>` 的自实现 `role="dialog"` 模态。

IE 及旧版内核不支持，不做兼容。

---

## 已知取舍

1. **媒体查询断点无法引用 `var()`** —— CSS 规范限制（自定义属性不能用于媒体查询条件）。断点值以 `--bp-lg/md/sm/xs` 令牌在第 133 行文档化，实际书写为字面量（980 / 900 / 680 / 460px）。
2. **未引入 favicon 与 `theme-color`** —— 二者必须写死色值，与「色值仅存在于令牌」冲突，故有意舍弃，以保证全文档零裸色值。
3. **角色与声骸无立绘** —— 受「无外部图片」约束，改用元素色渐变 + 首字缩写生成头像与声骸图形。
4. **频谱振幅为数据驱动** —— `--i` / `--h` 内联在波形元素上（伪随机振幅），属数据参数；动画时长、延迟步长、渐变仍全部来自令牌。
5. **骨架屏为演示性质** —— 图鉴首次进入加载 620ms（令牌 `--skeleton-ms`）以展示加载态，无真实网络请求。

---

## 验收清单

打开页面后可按下列步骤逐项核对：

- [ ] 双击 `index.html`，首页 Hero 出现声波脉动；缩放窗口至 375px 宽，无横向滚动条
- [ ] 依次点击 7 个导航项，地址栏 hash 变化、当前项高亮、页面回到顶部
- [ ] `#/wiki` 输入「凶鹭」即时过滤出 1 条；点「重置」后选 COST 4 + 冷凝，命中「鸣钟之龟」；点其书签图标后到 `#/user`，收藏列表出现该条目
- [ ] `#/team` 选满 3 名角色，观察槽位共鸣环扩散与环形评分动画；清空后分享按钮变为禁用
- [ ] `#/bbs` 空标题提交看到红色错误态；正常发帖后刷新页面，帖子仍在
- [ ] 打开任一资讯详情，按 ESC 关闭、再点遮罩关闭；用 Tab 确认焦点不会跑出对话框
- [ ] 系统开启「减少动态效果」后刷新，声波、扫光、共鸣环与过渡全部静止
- [ ] 控制台执行 `localStorage.removeItem('wuwa.fan.club.v1')` 后刷新，回到初始种子数据

---

## 目录结构

```
mingdemo/
├── index.html              # 站点全部内容（HTML + CSS + JS 内联，单文件交付）
├── README.md               # 本文档
├── DESIGN_PROMPTS.md       # 界面 UI 组件生图提示词包（风格基准图 → 回灌 CSS 的完整工作流）
├── PUSH_TO_GITHUB.md       # 本机 GitHub 加速链路（Watt Toolkit）的推送指南与故障排查对照表
├── .gitignore              # 忽略 dist-artifacts/ 与参考图本体
├── design/refs/            # 风格参考图放置目录（含命名约定，图片不入库）
└── tools/
    └── push-github.ps1     # 推送加固脚本：环境探测 → 连通性预检 → 加固参数推送 → 失败自动 bundle 兜底
```

站点本身仍是**单文件零依赖**：`index.html` 之外的文件都只是开发与运维辅助，不参与页面运行，
单独拷走 `index.html` 即可完整使用。仓库不含构建步骤、依赖清单与自动化测试。

### 界面风格的迭代方式

视觉语言的调整有两条路径：

1. **直接改令牌**：配色、圆角、间距、光效全部由 `:root` 的令牌驱动，改一处即全站生效；
2. **用参考图校准**：按 `DESIGN_PROMPTS.md` 生成风格板与组件图，放入 `design/refs/`，
   再按该文档第 7 节的映射表把图中特征换算成令牌值（配色、玻璃透明度、发丝高光、发光半径、信息密度）。

