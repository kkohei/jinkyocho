# 画像アセット投入リスト

生成したPNGを Xcode の **`Assets.xcassets`** にドラッグし、各 imageset の名前を
下表の「アセット名」に**正確に**リネームしてください（1文字でも違うと自動で拾われません）。
未投入の名前はコード描画のドット絵にフォールバックするので、無くても動きます。

> おすすめ：背景が白いまま入れてもOKですが、戦闘画面では敵が宙に浮く演出なので
> **背景透過PNG**（remove.bg 等で白を抜く）にするとよりキレイです。

## 戦闘モンスター（戦闘画面に大きく表示）

| 敵 | アセット名 | 強さ |
|---|---|---|
| 古書ゾンビ | `battle_zombie_pale` | 弱〜中 |
| 装丁鬼 | `battle_zombie_rotten` | 中 |
| 製本主（ボス） | `battle_zombie_boss` | ボス（占拠店の番人） |
| 魔導書コウモリ | `battle_bookbat` | 中 |
| 古書ゴーレム | `battle_bookgolem` | 中 |
| ラーメン丼の主 | `battle_ramenbowl` | 中 |
| ラーメン職人ゾンビ | `battle_ramenchef` | 中ボス |
| カレー鍋スライム | `battle_currypot` | 中 |
| ナンゴーレム | `battle_naangolem` | 中ボス |
| ほんスライム | `battle_honslime` | 雑魚 |
| しおりおばけ | `battle_bookmarkghost` | 雑魚 |
| インクこぞう | `battle_inkblob` | 雑魚 |
| ちびラーメン | `battle_babyramen` | 雑魚 |
| カレーまん | `battle_currybun` | 雑魚 |
| こぞんび | `battle_babyzombie` | 雑魚 |

## 戦闘背景

| 用途 | アセット名 |
|---|---|
| 戦闘画面の背景 | `battle_bg` |

## （任意）フィールドの見た目も差し替える場合

| 対象 | アセット名 |
|---|---|
| 道タイル / 壁タイル | `tile_road` / `tile_wall` |
| 店の入口 | `door_bookcafe` / `door_curry` / `door_weapon` / `door_grimoire` / `door_vacant` / `door_vacant_restored` |
| 看板猫 / 救出本 | `npc_cat` / `item_book` |
| フィールドのゾンビ | `zombie_pale` / `zombie_rotten` / `zombie_boss` |
| プレイヤー（各方向×2コマ） | `player_down_0` `player_down_1` `player_up_0` `player_up_1` `player_right_0` `player_right_1`（`player_left_*` は無ければ right を左右反転） |
