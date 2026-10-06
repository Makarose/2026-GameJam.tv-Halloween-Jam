# Changelog — AnyRenderer VFX (by Mothlight Studio)

Minimum Godot version: **4.2**. Channels: `free-sample` (this package), `full-pack` (paid v1.0, upcoming).

## v0.1.2 — free sample (2026-10)

Bug fixes: particle size now follows node scale on screen too, and no leftover spark at the end of Energy Slash.

- **Sparks, debris and the orb trail now get bigger and smaller with the node.** The particle
  size values already followed the node scale, but the shared spark material
  (`materials/m_spark_additive.tres`, used by the Energy Slash sparks, the Shockwave Ring debris
  and the Glow Orb trail) had `billboard_keep_scale` off, so Godot drew every particle at the
  same size. It is now on. The spark quad size goes from 0.12 to 0.15 to keep the 1× look close
  to v0.1.1 (particles now also show their random 0.4–1.2 size variation; the average size stays 0.12).
- **No leftover spark at the end of Energy Slash.** With `billboard_keep_scale` off, a spark that had
  already finished was still drawn for a moment at the emitter (the single spark that flashed as the
  effect ended). The same change fixes it.
- No other changes.

## v0.1.1 — free sample (2026-10)

Documentation and demo fixes; no changes to the effects' look or API.

- **README: claims now match what was tested.** Removed the platform claims we had not
  tested (web, handheld and Steam Deck use). The effects are designed for the
  Compatibility renderer (the renderer Godot uses for web exports) but have not yet
  been tested in a real browser, on mobile devices or on Steam Deck.
- README / test notes now say "no shader or script errors" — the earlier wording was
  broader than what the tests check (environment messages such as audio-driver lines
  are filtered out by the test tools).
- Credit added: the noise hash's mixing structure is inspired by MurmurHash3 fmix32
  (public domain); see THIRD_PARTY_NOTICES.txt. No code was copied.
- 2D demo: the helper nodes are now named `ArfxSpriteHit` (they were still called `FxSpriteHit`).

## v0.1.0 — free sample (2026-10)

First public release of the free sample: 5 effects (Energy Slash, Shockwave Ring,
Dissolve Burn, Glow Orb, Sprite Hit FX 2D) for Godot 4.2+ on Compatibility,
Mobile and Forward+.

Changes since the internal preview build:

- **Class names now carry a prefix** to avoid clashes with your own classes:
  `FxPlayer` → `ArfxPlayer`, `FxSpriteHit` → `ArfxSpriteHit`, and the 2D player is `ArfxPlayer2D`.
  Script files keep their names (`scripts/fx_player.gd`, `fx_sprite_hit.gd`, `fx_player_2d.gd`).
- **Scaling fixed for world-space particles** (e.g. the Glow Orb trail): setting the
  scale before adding the node, passing a scaled transform to `spawn()`, and changing
  the scale at runtime all give the same result. Only particle size is compensated
  (Godot already scales emission position/velocity), always from the authored values.
- **`spawn(scene, parent, xform, one_shot := true)`**: pass `false` for projectiles and
  auras; they hold until you call `stop()`, then fade out and free themselves.
- **`stop(fade := -1.0)`**: progress goes to 1 (= invisible for every effect) instantly
  or over `fade` seconds (default: the scene's `stop_fade`).
- **Glow Orb**: lifecycle redesigned (grow in → full → fade out), persistent by default
  when placed in a level; no longer stays at full brightness after `stop()`.
- **No seam** at the 9 o'clock position of Shockwave Ring and Glow Orb (angle noise is now periodic).
- **Noise hash rewritten** as our own integer hash (no third-party code; see THIRD_PARTY_NOTICES.txt).
- Softer arc ends on Energy Slash (no straight halo edge).
- 3D demo: WorldEnvironment glow is switched off on Compatibility (Godot 4.3+ glow
  brightened the whole background there); effects keep their built-in halo.
  New keys: `4` orb on/off with fade, `G` fires a projectile orb.
- 2D: `ArfxSpriteHit.dissolve_out()/dissolve_in()` interrupt each other cleanly;
  demo no longer leaks a Tween on exit in Godot 4.2. New effect scene
  `effects/sprite_hit_2d.tscn` (`ArfxPlayer2D`).
- Package: LICENSE, README, CHANGELOG and THIRD_PARTY_NOTICES are also inside
  `addons/anyrenderer_vfx/`; maintainer tools and preview images are no longer in the download.

---

# 更新日志（中文）

最低 Godot 版本：**4.2**。渠道：`free-sample`（本包）、`full-pack`（付费 v1.0，即将推出）。

## v0.1.2 —— 免费样品（2026-10）

缺陷修复：粒子在画面上的大小现在也会随节点缩放；Energy Slash 结尾不再残留火花。

- **火花、碎屑和能量球拖尾现在随节点变大变小：** 粒子大小的数值本来就随节点缩放，但共用的火花材质（`materials/m_spark_additive.tres`，用于 Energy Slash 火花、Shockwave Ring 碎屑和 Glow Orb 拖尾）没有开启 `billboard_keep_scale`，Godot 会把所有粒子画成同样大小。现已开启。火花面片尺寸从 0.12 改为 0.15，使 1× 观感与 v0.1.1 接近（粒子现在也会显示 0.4–1.2 的随机大小差异，平均大小仍为 0.12）。
- **Energy Slash 结尾不再残留火花：** `billboard_keep_scale` 关闭时，已经结束的火花仍会在发射点被画出一瞬间（特效结束时闪一下的那颗火花）。同一处修改已修复。
- 没有其他改动。

## v0.1.1 —— 免费样品（2026-10）

文档和演示修正，特效外观和接口没有变化。

- **README 的说法与实际测试一致：** 删除了没有实测过的平台说法（网页、掌机、Steam Deck）。特效为 Compatibility 渲染器设计（Godot 网页导出用的就是它），但尚未在真实浏览器、移动设备或 Steam Deck 上实测。
- README / 测试说明改为"无着色器或脚本错误"——之前的措辞比测试实际检查的范围更宽（声卡驱动等环境信息由测试工具过滤）。
- 新增致谢：噪声哈希的混合结构参考了 MurmurHash3 fmix32（公有领域），见 THIRD_PARTY_NOTICES.txt；未复制代码。
- 2D 演示：辅助节点改名为 `ArfxSpriteHit`（之前仍叫 `FxSpriteHit`）。

## v0.1.0 —— 免费样品（2026-10）

- **类名加前缀**，避免与你项目里的类重名：`FxPlayer` → `ArfxPlayer`、`FxSpriteHit` → `ArfxSpriteHit`，2D 播放器为 `ArfxPlayer2D`。脚本文件名不变。
- **修复世界坐标粒子的缩放**（如 Glow Orb 拖尾）：先设 scale 再加入场景树、`spawn()` 传入带缩放的变换、运行中改 scale，三种方式结果一致。只补偿粒子大小（引擎已处理发射位置和速度），并且总是基于原始值计算。
- **`spawn(scene, parent, xform, one_shot := true)`**：弹道/光环类传 `false`，会一直保持到调用 `stop()`，然后淡出并自动释放。
- **`stop(fade := -1.0)`**：progress 立即或在 `fade` 秒内变为 1（所有特效 1 = 不可见）。
- **Glow Orb**：生命周期改为“出现 → 全亮 → 淡出”，放在关卡里默认持续存在；`stop()` 后不再保持全亮。
- **Shockwave Ring 和 Glow Orb 9 点钟方向的接缝已修复**（角向噪声改为周期性）。
- **噪声哈希改为自写的整数哈希**（不含第三方代码）。
- Energy Slash 弧线两端更柔和。
- 3D Demo：兼容模式下关闭 WorldEnvironment 辉光（4.3+ 兼容模式开辉光会整体提亮背景），特效自带光晕。新按键：`4` 能量球开/关（淡出），`G` 发射弹道能量球。
- 2D：`dissolve_out()/dissolve_in()` 可互相打断；4.2 下 demo 退出不再泄漏 Tween。新增特效场景 `effects/sprite_hit_2d.tscn`（`ArfxPlayer2D`）。
- 打包：`addons/anyrenderer_vfx/` 内也附带 LICENSE、README、CHANGELOG、THIRD_PARTY_NOTICES；下载包不再包含维护工具和预览图。
