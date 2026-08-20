# @deepseek-ai/dsh-client-ui-brand-memorybear

[English](README.md) | 中文

本包用 MemoryBear 的标识与文字标填充 `sidebar.brand.mark`、`sidebar.brand.name` 和 `conversation.hero.brand.mark`。注册是无条件的：该条目由 MemoryBear patch 覆盖层挂载，因此它出现在组合树中本身就是部署方的决定。上游的官方 occupant 以构建产物 profile 自我门控，所以两个包永远不会同时注册。

三个占位者通过嵌套的 `slots.inject()` 作为一组声明感知注册安装。因此无论该包的条目先于还是后于侧边栏和会话声明方激活，它都能工作；任一声明折叠时会撤回全部占位者，HMR 期间不会留下混合品牌。它不保留运行时状态。node 半边是空的 Loader seat；浏览器标题仍属于本包之外的构建环境事项。

## 模型体验

无，因为本包只贡献浏览器呈现；这里没有任何内容进入模型请求。

#### KV Cache 影响

无；本包既不组装也不发送 provider 请求。

## 已知限制与暂缓事项

- **本包只提供一组 occupant** —— 其他呈现应由占用相同 slot 的另一个 Cordis 包提供。
- **浏览器标题与图标相互独立** —— `DSH_CLIENT_TITLE` 在构建期选择标题文字；标签页图标与 web manifest 是由 profile 的 public 目录提供的静态文件。两者都不经过 UI slot。
- **标识配色是固定的，不随主题变化** —— 头部在两种主题下都是深色；深色背景下靠红色眼镜和白色口罩承担辨识，而不是轮廓。
- **描摹出的几何数据存在两处** —— `Brand.tsx` 与 `deploy/memorybear/public/favicon.svg` 以两种格式保存同一份路径数据；改形状必须同时改两边。
