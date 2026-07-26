# Godot Hex Map

Godot 4.6 六边形地图编辑器与示例工程。概念对齐 [Catlike Coding — Hex Map](https://catlikecoding.com/unity/tutorials/hex-map/)，用 GDScript 重写网格、分块、地形特征与编辑器插件。

由 [老李游戏学院](https://github.com/LiGameAcademy) 维护，配套课程见星球专栏《从零手搓六边形网格系统》。

## 功能概览

- 六边形坐标与分块网格（`HexCoordinates` / `HexGrid` / `HexGridChunk`）
- 海拔、水体、河流、道路与地形特征
- Texture2DArray 地形纹理与自定义着色器
- 编辑器插件 **HexMapEditor**：Dock 面板、视口绘制、新建/存档地图、撤销重做

## 环境要求

- [Godot 4.6](https://godotengine.org/)（Forward+）
- Windows / macOS / Linux

## 快速开始

1. 克隆本仓库：

```bash
git clone https://github.com/LiGameAcademy/godot_hex_map.git
```

2. 用 Godot 4.6 打开项目根目录（含 `project.godot`）
3. 确认 **Project → Project Settings → Plugins** 中已启用 `HexMapEditor`
4. 运行主场景 `scenes/main.tscn`，或在编辑器中选中场景里的 `HexGrid` 使用插件面板编辑地图

## 目录结构

```text
godot_hex_map/
├── addons/hex_map_editor/   # 编辑器插件（核心脚本 / UI / 示例资源）
├── prefabs/                 # 城墙、桥梁、植物等特征预制体
├── scenes/                  # 主场景入口
├── docs/                    # 设计草稿
└── project.godot
```

插件内主要类型：

| 类型 | 职责 |
|------|------|
| `HexGrid` | 整图入口，管理 chunk 与单元格 |
| `HexGridChunk` | 分块 Mesh 更新 |
| `HexCell` | 单格数据（海拔、水、河/路等） |
| `HexMapEditor` | 编辑逻辑层 |
| `HexMapEditorPanel` | 编辑 UI 表现层 |

## 作为插件复用

将 `addons/hex_map_editor/` 复制到你的 Godot 4.6 工程，并在项目设置中启用插件即可。示例地形纹理与着色器位于 `addons/hex_map_editor/examples/`。

## 许可协议

本项目以 [MIT License](LICENSE) 发布。

教程思路参考 Catlike Coding Hex Map；实现与资源归本仓库作者所有，与原文 Unity 工程无直接代码复用关系。

## 相关链接

- [Catlike Coding — Hex Map](https://catlikecoding.com/unity/tutorials/hex-map/)
- [老李游戏学院 · 知识星球](https://wx.zsxq.com/group/28885154818841)
- [B 站频道](https://space.bilibili.com/8618918)
