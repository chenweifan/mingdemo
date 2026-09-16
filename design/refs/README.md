# design/refs · 风格参考图目录

把 `DESIGN_PROMPTS.md` 生成的图放在这里，用于校准 `index.html` 的视觉风格。

## 命名约定

```
01-style-board.png          主风格板（同时作为其余图的 --sref 参考）
02-component-sheet.png      组件总表
03-buttons.png              按钮四态
04-cards.png                卡片族
05-forms.png                表单与校验
06-overlays.png             模态 / Toast / 骨架屏 / 空态
07-dataviz.png              进度条 / 评分环 / 雷达图
08-codex-grid.png           声骸图鉴卡网格
09-hero.png                 Hero 主视觉
10-calendar.png             版本日历
11-team-builder.png         配队模拟
12-community.png            社区帖子流
13-nav.png                  吸顶导航
14-icons.png                图标集
```

## 用途与边界

- 这些图是**设计基准**，用来比对配色、圆角、层次、光效强度与信息密度，
  **不会**作为外链素材嵌入页面——站点保持单文件零依赖交付。
- 图里的中文文字必然是错的，忽略即可；只参考颜色、形状、间距与光影。
- 图片本体不入库（见根目录 `.gitignore`），只保留本说明与命名约定。

## 已应用的调整（2026-09-16）

14 张参考图已全部读图并回灌到 `index.html`：

| 参考图 | 提取到的特征 | 落地方式 |
|---|---|---|
| 01 风格板 | 5 级面板色阶 `#05080D / #0F1829 / #1C2A39 / #2A3F54 / #4F647A`、霓虹光晕按钮、圆形图标按钮、宽字距大写标签 | 重写 `--surface-*` 五档与 `--stroke-*` 三级；`.icon-btn` 改圆形；`--ls-caps .08em → .16em`；主按钮加外发光 |
| 02 组件总表 | 组件密度与圆角尺度 | `--r-lg 16→18px`、`--r-xl 22→26px`；`--fs-display` 上限 48→54px |
| 04 卡片族 | 左上「三竖条」仪表标记、更大角标、悬停强青光晕与斜向高光 | `.card::before` 改为「顶部发丝线 + 三竖条」双层背景；`--corner-size 15→22px`；`--sheen` 亮度 .075→.15 |
| 06 浮层 | 双行 Toast（图标徽章 + 标题 + 说明 + 时间戳 + 关闭，按语义着色）、青色虚线空态 | `toast()` 重构为语义化结构，新增 success/info/warn 三色与关闭动作；空态改 `--stroke-accent` 虚线 |
| 07 数据可视化 | 胶囊进度条（标签在条内、大号数值在右）、带点状外环与中心三层文字的评分仪表、顶点带底衬的雷达标签、图标+标签+数值统计块 | 新增 `.pbar / .segs / .ring__dots / .stat--icon`；`progressMetric()` 与团队评分拆解改用 `.pbar`；雷达标签加 `paint-order` 底衬 |
| 08 图鉴卡 | 元素色描边与光晕、COST 元素色胶囊、圆形符印（虚线圈 + 刻度环 + 中央字形）、分段评级 + 元素色大号数字、底部响应纹、修长卡型 | `echoCard()` 重写为符印卡；新增 `.echo__sigil / .segs / .echo__wave`；`.grid--echo` 收窄列宽得到修长比例 |
| 09 Hero | 白+渐变双行大标题、深色胶囊眉标 + 呼吸点、同心环 + 十字辐条 + 亮心、青顶蓝底声波 + 亮基线 | 标题加粗至 700；`.eyebrow` 改深色底 + 外发光；环组新增辐条与 `r-core` 亮心；声波 40→72 根、渐变改 `--wave-top/--wave-bottom` 并补底部基线；数据字号提升至 `--fs-2xl` |
| 13 导航 | 悬浮胶囊条 + 青描边与外发光、圆角方形 Logo 磁贴、竖分隔线、激活项指示点、圆形汉堡 | `.nav` 改为透明容器 + `.nav__inner` 胶囊；新增品牌分隔线与激活指示点；窄屏下拉改为圆角浮层 |

**未直接采纳的一处**：参考图把 `#4F647A` 标为 OVERLAY PANEL，但该色与正文文本对比度仅 3.5:1（低于 WCAG AA）。
故模态底色下调为 `#33475E`（正文 5.5:1、高亮文本 7.9:1），`#4F647A` 改作高对比描边色 `--surface-line`。

## 渲染截图 `shots/`

`shots/` 存放站点的实拍截图，用于 README 预览与改版前后对比。采集方式：

```powershell
msedge --headless=new --disable-gpu --hide-scrollbars --disable-http-cache `
       --user-data-dir=<临时目录> --window-size=1200,900 --virtual-time-budget=4500 `
       --screenshot=design/refs/shots/01-home.png `
       "file:///C:/source/mingdemo/index.html#/home"
```

**采集注意（踩过的坑）**：headless Chromium 在 Windows 下存在约 **518 CSS px 的最小窗口宽度**，
`--window-size=390` 会被钳制到 518，而截图只截窗口宽度——于是页面按 518 排版、图片只显示 390，
右侧被裁掉，**看起来像布局溢出，实际是采集伪影**。判断是否真的溢出应看
`document.documentElement.scrollWidth > window.innerWidth`，而不是看截图边缘。
因该钳制，`08-narrow-518.png` 记录的是 518px 视口（覆盖 ≤680 断点）；**≤460 断点尚未实拍验证**。

页面本身在 518 / 746 / 1166 三个视口下均无横向溢出（已用注入探针实测 `scrollWidth` 与元素盒模型）。

## 后续迭代

换图后重复同一流程即可：新图放进本目录 → 读图 → 按 `DESIGN_PROMPTS.md` 第 7 节的映射表换算令牌 →
跑回归（令牌完整性、7 路由渲染、交互链路、无障碍与零外部依赖约束）。
