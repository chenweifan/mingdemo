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

## 放好之后怎么用

让 Agent 读取这些图（它具备图像读取能力），它会：

1. 提取主色与层级色，替换 `:root` 中的 `--surface-*`、`--resonance`、`--sonic`、`--tide-gold`；
2. 对照圆角、玻璃透明度、发丝高光、外发光强度，调整 `--r-lg`、`--glass`、`--hairline`、`--glow-resonance`；
3. 对照信息密度与节奏，调整 `--sp-*`、`--card-min`、`--enter-dur`；
4. 跑一遍回归：令牌完整性、7 个路由渲染、无障碍与「零外部依赖」约束。

映射关系详见 `DESIGN_PROMPTS.md` 第 7 节「从图到代码：映射表」。
