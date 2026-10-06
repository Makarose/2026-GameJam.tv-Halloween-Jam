# AnyRenderer VFX — Free Samples v0.1.2 (Godot 4.2+)

by **Mothlight Studio** · **English** | [简体中文](#简体中文)

> **Minimum Godot version: 4.2** (standard build, no .NET). Passed our automated tests on all three
> renderers — **Compatibility**, **Mobile** and **Forward+** — on Linux with software rendering (see *What was tested*).

Five fully procedural effects (no textures needed, no screen/depth reads).
Designed for the Compatibility renderer (the renderer Godot uses for web exports). Not yet tested in a real browser, on mobile devices, or on Steam Deck.

| ID | Effect | Type | Scene / material (in `addons/anyrenderer_vfx/`) |
|---|---|---|---|
| SL01 | Energy Slash — sweeping melee crescent + sparks | 3D, unshaded additive | `effects/energy_slash.tscn`, `materials/m_energy_slash_*.tres` |
| GD01 | Shockwave Ring — ground slam / landing ring + debris | 3D, unshaded additive | `effects/shockwave_ring.tscn`, `materials/m_shockwave_*.tres` |
| MT01 | Dissolve Burn — burn-away material for any mesh (no UVs needed) | 3D, lit | `effects/dissolve_demo.tscn`, `materials/m_dissolve_*.tres` |
| PJ01 | Glow Orb — projectile / pickup / charge core + world-space trail | 3D billboard | `effects/glow_orb.tscn`, `materials/m_glow_orb_*.tres` |
| SP01–03 | Sprite Hit FX — hit flash, outline, dissolve for sprites | 2D `canvas_item` | `effects/sprite_hit_2d.tscn`, `materials/m_sprite_hit_2d.tres` |

Scripts (`scripts/`): `ArfxPlayer` (3D effect root), `ArfxPlayer2D` (2D effect root), `ArfxSpriteHit` (2D helper).
All class names are prefixed with `Arfx` so they will not clash with your own classes.

## Quick test (2 minutes)

1. Install Godot **4.2 or newer**.
2. Project Manager → **Import** → select this folder's `project.godot`. (Newer Godot may offer to upgrade the project file — that is fine.)
3. Press **F5**: the 3D showcase `demo/demo_3d.tscn`.
   Keys: `1` slash, `2` shockwave, `3` dissolve, `4` orb on/off (fades out), `F` one-shot slashes, `G` fire a projectile orb.
   The top-left label shows the Godot version and the renderer in use.
4. Open `addons/anyrenderer_vfx/demo/demo_2d.tscn`, press **F6** (`H` flash, `O` outline, `D` dissolve).
5. **Other renderers:** Project Settings → Rendering → Renderer → *Rendering Method* = `forward_plus`, `mobile` or `gl_compatibility`, restart the editor. The project ships set to `gl_compatibility` on purpose.

## Using the effects in your game

1. Copy the whole `addons/anyrenderer_vfx/` folder into your project **at the same path**
   (shaders `#include "res://addons/anyrenderer_vfx/shaders/fx_common.gdshaderinc"`). LICENSE and README copies are inside it.
2. Drag an effect scene into a level, or spawn it from code:

```gdscript
const SLASH := preload("res://addons/anyrenderer_vfx/effects/energy_slash.tscn")
const ORB := preload("res://addons/anyrenderer_vfx/effects/glow_orb.tscn")

func attack() -> void:
    # One-shot: plays once, then frees itself.
    var fx := ArfxPlayer.spawn(SLASH, get_tree().current_scene, $Weapon.global_transform)
    fx.finished.connect(func(): print("slash finished"))   # optional

func shoot() -> ArfxPlayer:
    # Persistent (one_shot = false): stays lit until you call stop().
    var orb := ArfxPlayer.spawn(ORB, get_tree().current_scene, $Muzzle.global_transform, false)
    return orb   # move it yourself; on hit: orb.stop()  -> fades out (0.3 s) and frees itself
```

**ArfxPlayer API** (`scripts/fx_player.gd`; `ArfxPlayer2D` in `fx_player_2d.gd` is the same with `Transform2D`)

| Member | Meaning |
|---|---|
| `spawn(scene, parent, xform, one_shot := true)` (static) | Instance under `parent` at global `xform` and play. `one_shot=false` = persistent until `stop()`. |
| `play()` / `stop(fade := -1.0)` | Restart from progress 0 / stop: progress → 1 (invisible) instantly or over `fade` s (default `stop_fade`). With `free_when_done` the node frees itself afterwards. |
| `duration`, `loop`, `loop_delay`, `autoplay`, `free_when_done` | Timing; `finished` signal fires at the end of each play-through. |
| `persistent`, `hold_progress`, `stop_fade` | Persistent mode holds at `hold_progress` until `stop()`. Glow Orb ships with `persistent = true`, `stop_fade = 0.3`. |
| `progress_curve`, `randomize_seed`, `get_progress()` | Optional time→progress remap, per-instance noise, current progress. |

Every effect follows one rule: **`progress` 0 = start, 1 = finished / invisible.**

- **Scale:** scale the node. Meshes and local-space particles follow automatically; for world-space particles (the orb trail) `ArfxPlayer` sets the particle size from the authored values × global scale — whether you scale before adding the node, pass a scaled transform to `spawn()`, or scale at runtime (applied on the next transform update, i.e. within one frame).
- **Colours / shape:** edit the ShaderMaterial on the mesh child, or duplicate a preset in `materials/` (`*_azure`, `*_crimson`, `*_fire`, `*_frost`, `*_ember`, `*_arcane`, `*_toxic`).
- **Many copies:** each instance makes its own lightweight copy of the material on `_ready`, so copies never animate in sync by accident.
- **Glow Orb limits:** placed in a level it stays lit (persistent). Spawned with the default `one_shot = true` it plays its 1.2 s grow-in/fade-out cycle once and frees itself — use `one_shot = false` for projectiles. `stop()` always fades it to invisible.
- **Dissolve on your own mesh:** set its *Material Override* to `materials/m_dissolve_ember.tres` and animate `progress` (0 = visible, 1 = gone), or make it a child of a node with `fx_player.gd`.
- **2D:** give a Sprite2D `materials/m_sprite_hit_2d.tres`, add a child `Node` with `scripts/fx_sprite_hit.gd` (class `ArfxSpriteHit`), then call `flash()`, `set_outline()`, `dissolve_out()` / `dissolve_in()`. Outlines need a few pixels of transparent padding. Or use the ready-made `effects/sprite_hit_2d.tscn` (`ArfxPlayer2D` with `param_curves`).

## Compatibility notes

- No screen/depth texture reads, no compute shaders, no GPU-particle sub-emitters/trails; particles are `CPUParticles3D/2D`.
- No `instance uniform` (Godot 4.2 Compatibility rejects it: "Uniform instances are not supported in gl_compatibility shaders") — per-instance material copies instead.
- **Built-in halo instead of post-process glow:** effects look glowing with `WorldEnvironment` glow off. Recommended: glow on for Forward+/Mobile if you like (`intensity` > 1 adds real bloom), **off on Compatibility** — Godot 4.2 Compatibility has no glow, and in our tests (4.3–4.7, software rendering) Compatibility glow brightened the whole background. The 3D demo does exactly this.
- Constant loop counts and 32-bit integer hashing, chosen with WebGL 2 and mobile GPUs in mind (not yet tested on them).

## What was tested (honest status)

Automated test matrix with the official Godot Linux builds, using **software rendering only** (Mesa llvmpipe for OpenGL, lavapipe for Vulkan, under Xvfb):

<!-- MATRIX:BEGIN -->
| Godot | Compatibility | Mobile | Forward+ |
|---|---|---|---|
| 4.2.2 | ✅ 5/5 | ✅ 5/5 | ✅ 5/5 |
| 4.3 | ✅ 5/5 | ✅ 5/5 | ✅ 5/5 |
| 4.4.1 | ✅ 5/5 | ✅ 5/5 | ✅ 5/5 |
| 4.5.2 | ✅ 5/5 | ✅ 5/5 | ✅ 5/5 |
| 4.6.3 | ✅ 5/5 | ✅ 5/5 | ✅ 5/5 |
| 4.7.2 | ✅ 5/5 | ✅ 5/5 | ✅ 5/5 |

(n/N = effects passing; generated 2026-10-06 by the maintainer test matrix)
<!-- MATRIX:END -->

✅ = every effect's shaders compiled and rendered with no shader or script errors, copies animated independently, one-shot instances freed themselves, `stop()` hid the effect, the persistent orb stayed alive until `stop()`, and 3D effects (meshes and particle size) scaled with their node in all three ways of scaling.
**Not yet tested:** real GPUs (NVIDIA/AMD/Intel/Apple), Windows, macOS, Android/iOS, HTML5 export in a real browser, Steam Deck hardware. Visuals differ slightly between renderers (tonemapping/glow).

## Folder layout

```
project.godot / icon.svg     demo project (opens the 3D demo; default renderer gl_compatibility)
README.md  LICENSE.txt  CHANGELOG.md
addons/anyrenderer_vfx/      <- the only folder you need to copy
  README.md  LICENSE.txt  CHANGELOG.md  THIRD_PARTY_NOTICES.txt
  shaders/    5 .gdshader + fx_common.gdshaderinc (shared noise/halo helpers)
  materials/  ShaderMaterial presets + additive spark material
  effects/    ready-to-use effect scenes (ArfxPlayer / ArfxPlayer2D roots)
  scripts/    fx_player.gd, fx_player_2d.gd, fx_sprite_hit.gd
  demo/       demo_3d.tscn/.gd, demo_2d.tscn/.gd
  textures/   demo_slime.png (original demo sprite)
```

## Licence, authorship & AI disclosure

© 2026 Mothlight Studio — see `LICENSE.txt` (use in any game, free or commercial; do not resell/redistribute the files themselves).
All code, the demo sprite and the icon were made for this pack; the code was **written with AI assistance**, reviewed for copied
third-party snippets (none known; common techniques such as value noise and fBm are used) and tested as described above.
Third-party code: none. Credit: the noise hash's mixing structure is inspired by MurmurHash3 fmix32 (public domain; our own constants) —
see `addons/anyrenderer_vfx/THIRD_PARTY_NOTICES.txt`. Changes: `CHANGELOG.md`.

---

<a id="简体中文"></a>
# AnyRenderer VFX —— 免费试用样品 v0.1.2（Godot 4.2+）

作者：**Mothlight Studio**

> **最低 Godot 版本：4.2**（标准版即可，不需要 .NET）。在 Linux 软件渲染下，三种渲染器
> **Compatibility（兼容模式）**、**Mobile**、**Forward+** 都通过了我们的自动测试（见"测试情况"）。

五个完全程序化的特效（不需要贴图，不读屏幕/深度纹理）。为 Compatibility 渲染器设计（Godot 网页导出用的就是它），尚未在真实浏览器、移动设备或 Steam Deck 上实测。

| ID | 特效 | 类型 | 场景 / 材质（位于 `addons/anyrenderer_vfx/`） |
|---|---|---|---|
| SL01 | 能量斩击 Energy Slash：近战弧形刀光 + 火花 | 3D，无光照叠加 | `effects/energy_slash.tscn`、`materials/m_energy_slash_*.tres` |
| GD01 | 冲击波环 Shockwave Ring：落地/重击地面波 + 碎屑 | 3D，无光照叠加 | `effects/shockwave_ring.tscn`、`materials/m_shockwave_*.tres` |
| MT01 | 溶解燃烧 Dissolve Burn：任意模型的燃烧消散材质（不需要 UV） | 3D，受光照 | `effects/dissolve_demo.tscn`、`materials/m_dissolve_*.tres` |
| PJ01 | 发光能量球 Glow Orb：弹道/拾取物/蓄力核心 + 世界坐标拖尾 | 3D 公告板 | `effects/glow_orb.tscn`、`materials/m_glow_orb_*.tres` |
| SP01–03 | 精灵受击特效 Sprite Hit FX：闪白、描边、溶解 | 2D `canvas_item` | `effects/sprite_hit_2d.tscn`、`materials/m_sprite_hit_2d.tres` |

脚本（`scripts/`）：`ArfxPlayer`（3D 特效根节点）、`ArfxPlayer2D`（2D 特效根节点）、`ArfxSpriteHit`（2D 辅助脚本）。类名统一加 `Arfx` 前缀，避免和你项目里的类重名。

## 快速测试（约 2 分钟）

1. 安装 Godot **4.2 或更新版本**。
2. 项目管理器 → **导入** → 选择本文件夹的 `project.godot`。（较新的 Godot 可能提示升级项目文件，确认即可。）
3. 按 **F5** 运行 3D 演示 `demo/demo_3d.tscn`。按键：`1` 斩击，`2` 冲击波，`3` 溶解，`4` 能量球开/关（淡出），`F` 一次性斩击，`G` 发射弹道能量球。左上角显示 Godot 版本和实际使用的渲染器。
4. 打开 `addons/anyrenderer_vfx/demo/demo_2d.tscn`，按 **F6**（`H` 闪白，`O` 描边，`D` 溶解）。
5. **切换渲染器：** 项目设置 → 渲染 → 渲染器 → *渲染方式* 改为 `forward_plus`、`mobile` 或 `gl_compatibility`，重启编辑器。本项目默认故意设为 `gl_compatibility`。

## 在你的游戏中使用

1. 把整个 `addons/anyrenderer_vfx/` 文件夹复制到你的项目，**路径保持不变**（着色器会 `#include` 公共文件）。文件夹里附带 LICENSE 和 README 副本。
2. 把特效场景拖进关卡，或用代码生成（示例见上方英文部分的代码块）：
   - `ArfxPlayer.spawn(场景, 父节点, 全局变换)`：一次性播放，播完自动释放；
   - `ArfxPlayer.spawn(场景, 父节点, 全局变换, false)`：持续型（弹道、光环），一直保持到调用 `stop()`，然后淡出并自动释放。

**ArfxPlayer 接口**（`ArfxPlayer2D` 相同，只是用 `Transform2D`）：`spawn(scene, parent, xform, one_shot := true)`；`play()`；`stop(fade := -1.0)`（progress 立即或在 fade 秒内变为 1 = 不可见，默认用 `stop_fade`）；`duration`、`loop`、`loop_delay`、`autoplay`、`free_when_done`；`persistent`、`hold_progress`、`stop_fade`；`progress_curve`、`randomize_seed`、`get_progress()`；信号 `finished`。

所有特效遵守同一规则：**`progress` 0 = 开始，1 = 结束/不可见。**

- **缩放：** 直接改节点的 scale。网格和本地坐标粒子自动跟随；世界坐标粒子（能量球拖尾）由 `ArfxPlayer` 按“原始值 × 全局缩放”设置粒子大小。先设 scale 再加入场景树、`spawn()` 传入带缩放的变换、运行中改 scale 三种方式都有效（运行中修改会在下一次变换更新时生效，即一帧之内）。
- **颜色/形状：** 修改子网格的 ShaderMaterial，或复制 `materials/` 里的预设。
- **同时播放多个：** 每个实例在 `_ready` 时复制一份轻量材质，多个实例不会意外同步。
- **Glow Orb 的用法和限制：** 放在关卡里默认持续发光；用默认的 `one_shot = true` 生成时，会完整播放 1.2 秒的“出现→淡出”然后释放，做弹道请传 `one_shot = false`。`stop()` 一定会把它淡出到不可见。
- **给自己的模型加溶解：** Material Override 设为 `materials/m_dissolve_ember.tres`，动画 `progress`（0 = 完整，1 = 消失）。
- **2D：** 给 Sprite2D 设置 `materials/m_sprite_hit_2d.tres`，加一个挂 `scripts/fx_sprite_hit.gd`（类 `ArfxSpriteHit`）的子 `Node`，调用 `flash()`、`set_outline()`、`dissolve_out()` / `dissolve_in()`。描边需要精灵四周留几像素透明边。也可以直接用 `effects/sprite_hit_2d.tscn`（`ArfxPlayer2D` + `param_curves`）。

## 兼容性说明

- 不读屏幕/深度纹理，不用计算着色器，不用 GPU 粒子子发射器/拖尾；粒子全部用 `CPUParticles3D/2D`。
- 不使用 `instance uniform`（Godot 4.2 兼容模式不支持），改用每实例材质副本。
- **自带光晕，不依赖后处理辉光：** 关闭 `WorldEnvironment` 辉光也能看出发光。建议：Forward+/Mobile 可按喜好开辉光（`intensity` > 1 会叠加真实泛光），**兼容模式关闭辉光**——4.2 兼容模式不支持辉光，我们测试中（4.3–4.7，软件渲染）兼容模式开辉光会把整个背景提亮。3D Demo 就是这样设置的。
- 循环次数固定，使用 32 位整数哈希，是按 WebGL 2 和移动 GPU 的限制设计的（尚未在这些平台实测）。

## 测试情况（如实说明）

使用官方 Godot Linux 版本自动跑测试矩阵，**只用了软件渲染**（OpenGL 用 Mesa llvmpipe，Vulkan 用 lavapipe，运行在 Xvfb 下），结果见上方英文部分的表格。
✅ = 每个特效的着色器编译和渲染无着色器或脚本错误，多实例互不影响，一次性特效自动释放，`stop()` 后隐藏，持续型能量球在 `stop()` 前一直存在，3D 特效（网格和粒子大小）在三种缩放方式下都随节点缩放。
**尚未测试：** 真实显卡（NVIDIA/AMD/Intel/Apple）、Windows、macOS、Android/iOS、真实浏览器中的 HTML5 导出、Steam Deck 实机。不同渲染器的画面略有差异（色调映射/辉光）。

## 授权、作者与 AI 声明

© 2026 Mothlight Studio，见 `LICENSE.txt`（可用于任何免费或商业游戏；禁止转售/再分发文件本身）。
所有代码、演示精灵图和图标均为本包制作；代码**在 AI 辅助下编写**，经检查未发现复制的第三方代码片段（使用了值噪声、fBm 等常见技术），并按上文方式实际测试。不含第三方代码；致谢：噪声哈希的混合结构参考了 MurmurHash3 fmix32（公有领域，常数为自选），见 `addons/anyrenderer_vfx/THIRD_PARTY_NOTICES.txt`。更新记录：`CHANGELOG.md`。
