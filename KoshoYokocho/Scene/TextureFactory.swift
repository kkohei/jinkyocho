//
//  TextureFactory.swift
//  古書横丁ものがたり — ドット絵テクスチャ生成（コード内蔵・外部画像なし）
//
//  文字列のドット絵（1文字＝1ピクセル）をパレットで色付けして描く DSL を中心に、
//  輪郭線＋陰影＋多色で 16bit JRPG 風の質感を目指す。全テクスチャ nearest。
//

import SpriteKit
import UIKit

enum TextureFactory {

    // MARK: - 共通パレット（1文字＝1色。' ' と '.' は透明）

    /// よく使う色。スプライトごとに必要な文字だけ使う。
    static let palette: [Character: UIColor] = [
        "X": hex(0x14111A),                 // 輪郭（ほぼ黒）
        // 肌
        "f": hex(0xF4C79C), "F": hex(0xD49A6C),
        // 髪
        "h": hex(0x4A3526), "H": hex(0x6B4E34),
        // 緑の上着
        "g": hex(0x3B7A4C), "G": hex(0x5DA86E), "d": hex(0x274F2E),
        // 革・ベルト
        "l": hex(0x6E4A28), "L": hex(0x8A6238),
        // 暗色（靴・影）
        "k": hex(0x2C2018),
        // 生成り・布
        "w": hex(0xECE3D0), "W": hex(0xFFFFFF),
        // 金
        "y": hex(0xD9B24A), "Y": hex(0xF0D27A),
        // 赤（本の表紙・ボス）
        "r": hex(0xB0392F), "R": hex(0xD65A4A),
        // 猫（橙）
        "o": hex(0xD98A3A), "O": hex(0xE8A85A),
        // ゾンビ（青白）
        "z": hex(0x7FA07A), "Z": hex(0x9CBF92), "v": hex(0x5C7A57),
        // 光る目
        "i": hex(0xE5483A),
    ]

    private static func hex(_ v: Int) -> UIColor {
        UIColor(red: CGFloat((v >> 16) & 0xFF) / 255,
                green: CGFloat((v >> 8) & 0xFF) / 255,
                blue: CGFloat(v & 0xFF) / 255, alpha: 1)
    }

    // MARK: - ドット絵レンダラ

    /// 文字列の行（rows[0] が最上段）を 1文字=1px で描画して UIImage を返す。
    private static func render(_ rows: [String],
                              _ pal: [Character: UIColor]) -> UIImage {
        let h = rows.count
        let w = rows.map { $0.count }.max() ?? 1
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: format)
        return renderer.image { c in
            let ctx = c.cgContext
            for (ry, row) in rows.enumerated() {
                for (cx, ch) in row.enumerated() {
                    guard let color = pal[ch] else { continue }   // 未定義/空白は透明
                    ctx.setFillColor(color.cgColor)
                    ctx.fill(CGRect(x: cx, y: ry, width: 1, height: 1))
                }
            }
        }
    }

    /// ドット絵 → nearest テクスチャ。flipH で左右反転。
    private static func tex(_ rows: [String],
                           _ pal: [Character: UIColor] = palette,
                           flipH: Bool = false) -> SKTexture {
        let rr = flipH ? rows.map { String($0.reversed()) } : rows
        let t = SKTexture(image: render(rr, pal))
        t.filteringMode = .nearest
        return t
    }

    /// 手続き的に描く小さなキャンバス（タイル・暖簾用）。左下原点（y上向き）。
    private static func proc(_ pixels: Int, _ draw: (CGContext, Int) -> Void) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: pixels, height: pixels))
        let image = renderer.image { rctx in
            let ctx = rctx.cgContext
            ctx.translateBy(x: 0, y: CGFloat(pixels))
            ctx.scaleBy(x: 1, y: -1)
            draw(ctx, pixels)
        }
        let t = SKTexture(image: image)
        t.filteringMode = .nearest
        return t
    }

    private static func px(_ ctx: CGContext, _ c: Int, _ x: Int, _ y: Int, _ w: Int = 1, _ h: Int = 1) {
        ctx.setFillColor(hex(c).cgColor)
        ctx.fill(CGRect(x: x, y: y, width: w, height: h))
    }

    // MARK: - タイル（陰影つき）

    static func roadTile() -> SKTexture {
        proc(16) { ctx, _ in
            px(ctx, 0xA8966A, 0, 0, 16, 16)                 // 目地（暗）
            // 2×2 の大きめの石畳。各石に上ハイライト・下シャドウ。
            let cells = [(1, 1), (8, 1), (1, 8), (8, 8)]
            for (x, y) in cells {
                px(ctx, 0xCDBB90, x, y, 6, 6)               // 石
                px(ctx, 0xE0D2A8, x, y + 5, 6, 1)           // 上ハイライト
                px(ctx, 0xB39C6E, x, y, 6, 1)               // 下シャドウ
                px(ctx, 0xE0D2A8, x, y + 1, 1, 4)           // 左ハイライト
            }
        }
    }

    static func wallTile() -> SKTexture {
        proc(16) { ctx, _ in
            px(ctx, 0xB86B4A, 0, 0, 16, 16)                 // 壁（テラコッタ）
            // レンガの目地（横線）
            for y in stride(from: 2, to: 12, by: 3) {
                px(ctx, 0x8A4E34, 0, y, 16, 1)
            }
            // 縦の目地を互い違いに
            for y in stride(from: 2, to: 12, by: 6) {
                px(ctx, 0x8A4E34, 5, y, 1, 3)
                px(ctx, 0x8A4E34, 11, y, 1, 3)
            }
            // 屋根の庇（上部）
            px(ctx, 0x5E3324, 0, 12, 16, 4)
            px(ctx, 0x7A4632, 0, 14, 16, 1)
            px(ctx, 0x3A2018, 0, 11, 16, 1)
            // 灯のともる窓
            px(ctx, 0x2A1A12, 4, 3, 8, 7)                   // 窓枠
            px(ctx, 0xF2D27A, 5, 4, 6, 5)                   // 灯り
            px(ctx, 0x2A1A12, 8, 4, 1, 5)                   // 桟・縦
            px(ctx, 0x2A1A12, 5, 6, 6, 1)                   // 桟・横
        }
    }

    // MARK: - 店の入口（暖簾＋木戸）

    static func shopDoor(color: UIColor) -> SKTexture {
        proc(16) { ctx, _ in
            // 木戸
            px(ctx, 0x6E4A28, 3, 0, 10, 12)
            px(ctx, 0x5A3A20, 3, 0, 10, 1)
            for x in stride(from: 5, to: 13, by: 3) { px(ctx, 0x5A3A20, x, 1, 1, 10) }
            px(ctx, 0xD9B24A, 11, 5, 1, 2)                  // 取っ手
            // 暖簾（指定色）
            var rc = CGFloat(0), gc = CGFloat(0), bc = CGFloat(0), a = CGFloat(0)
            color.getRed(&rc, green: &gc, blue: &bc, alpha: &a)
            ctx.setFillColor(color.cgColor)
            ctx.fill(CGRect(x: 1, y: 11, width: 14, height: 4))
            ctx.setFillColor(UIColor(red: rc * 0.7, green: gc * 0.7, blue: bc * 0.7, alpha: 1).cgColor)
            ctx.fill(CGRect(x: 1, y: 11, width: 14, height: 1)) // 裾の陰
            px(ctx, 0xF4ECD8, 7, 11, 2, 4)                  // 白い割れ目
            px(ctx, 0x2A1A12, 1, 15, 14, 1)                 // 竿
        }
    }

    static func vacantDoor() -> SKTexture {
        proc(16) { ctx, _ in
            px(ctx, 0x4A4A4E, 2, 0, 12, 15)                 // シャッター
            for y in stride(from: 1, to: 15, by: 2) {
                px(ctx, 0x35353A, 2, y, 12, 1)
            }
            // 打ちつけた板（×）
            px(ctx, 0x6E4A28, 2, 2, 12, 2)
            px(ctx, 0x6E4A28, 2, 10, 12, 2)
            px(ctx, 0x3A2418, 3, 3, 10, 1)
        }
    }

    // MARK: - 住人・拾得物（ドット絵）

    static func catNPC() -> SKTexture {
        tex([
            "                ",
            "   X        X   ",
            "   XX      XX   ",
            "   XoX    XoX   ",
            "   XooooooooX   ",
            "   XoOooooOoX   ",
            "   XoXooooXoX   ",
            "   XooowwoooX   ",
            "   XooooooooX   ",
            "    XooooooX    ",
            "    XooooooX    ",
            "   XooooooooX X ",
            "   XooooooooXXX ",
            "   XooooooooX X ",
            "   XwooooowX    ",
            "    XX    XX    ",
        ])
    }

    static func bookPickup() -> SKTexture {
        tex([
            "                ",
            "                ",
            "    XXXXXXXX    ",
            "   XrrrrrrrrX   ",
            "   XRrrrrrrXy   ",
            "   XrwwwwwrXy   ",
            "   XrwwwwwrXy   ",
            "   XrwwwwwrXy   ",
            "   XrwwwwwrXy   ",
            "   XrwwwwwrXy   ",
            "   XRrrrrrrX    ",
            "    XXXXXXXX    ",
            "                ",
            "                ",
            "                ",
            "                ",
        ])
    }

    // MARK: - ゾンビ（青白／黒ずみ／ボス）

    private static let zombieRows: [String] = [
        "                ",
        "     XXXXX      ",
        "    XzzzzzX     ",
        "    XzvvvzX     ",
        "    XiZ ZiX     ",
        "    XzzzzzX     ",
        "    XzXXXzX     ",
        "   XzzzzzzzX    ",
        " XXzzzzzzzzXX   ",
        "Xz XzzzzzzzX zX ",
        "Xz XzzzzzzzX zX ",
        "   XzzzzzzzX    ",
        "   XzvvvvzX     ",
        "   Xz   zX      ",
        "  XkX   XkX     ",
        "                ",
    ]

    /// ボスは角を生やす。
    private static let bossExtraRows: [String] = [
        "                ",
        "  y  XXXXX  y   ",
        "  yyXzzzzzXyy   ",
    ]

    private static func zombiePalette(_ tint: ZombieTint) -> [Character: UIColor] {
        var p = palette
        switch tint {
        case .pale:
            p["z"] = hex(0x7FA07A); p["Z"] = hex(0x9CBF92); p["v"] = hex(0x5C7A57)
        case .rotten:
            p["z"] = hex(0x7A7A4E); p["Z"] = hex(0x9A9A66); p["v"] = hex(0x53533A)
        case .boss:
            p["z"] = hex(0x9A3F3A); p["Z"] = hex(0xBF5A50); p["v"] = hex(0x6E2C28)
        }
        return p
    }

    private static func zombieArt(_ tint: ZombieTint) -> [String] {
        guard tint == .boss else { return zombieRows }
        // 上3行を角つきに差し替え。
        var rows = zombieRows
        rows[0] = bossExtraRows[0]
        rows[1] = bossExtraRows[1]
        rows[2] = bossExtraRows[2]
        return rows
    }

    static func zombie(tint: ZombieTint) -> SKTexture {
        tex(zombieArt(tint), zombiePalette(tint))
    }

    /// 戦闘画面に大きく出す敵の絵（SwiftUI 用 UIImage）。
    static func zombieImage(tint: ZombieTint) -> UIImage {
        render(zombieArt(tint), zombiePalette(tint))
    }

    // MARK: - プレイヤー（4方向・歩行2フレーム）

    // 頭＋胴（13行）。脚3行を後付けする。
    private static let bodyDown: [String] = [
        "                ",
        "     XXXXXX     ",
        "    XhhHHhhX    ",
        "    XhffffhX    ",
        "    XffffffX    ",
        "    XfXffXfX    ",
        "    XffffffX    ",
        "    XFffffFX    ",
        "    XwwwwwwX    ",
        "   XGgggggGX    ",
        "  XGgggggggGX   ",
        "   XgggggggX    ",
        "   XllllllX     ",
    ]

    private static let bodyUp: [String] = [
        "                ",
        "     XXXXXX     ",
        "    XhhHHhhX    ",
        "    XhhhhhhX    ",
        "    XhhhhhhX    ",
        "    XhhhhhhX    ",
        "    XhhhhhhX    ",
        "    XhhhhhhX    ",
        "    XwwwwwwX    ",
        "   XGgggggGX    ",
        "  XGgggggggGX   ",
        "   XgggggggX    ",
        "   XllllllX     ",
    ]

    private static let bodyRight: [String] = [
        "                ",
        "     XXXXXX     ",
        "    XhhhhhhX    ",
        "    XhfffffX    ",
        "    XffffffX    ",
        "    XffXfffX    ",
        "    XffffffX    ",
        "    XFffffX     ",
        "    XwwwwwwX    ",
        "   XGgggggGX    ",
        "   XgggggggX    ",
        "   XgggggggX    ",
        "   XllllllX     ",
    ]

    // 脚（3行）。frame で左右を入れ替えて歩行感。
    private static let legsA: [String] = [
        "   Xgg  ggX     ",
        "   Xk    kX     ",
        "   Xkk  kkX     ",
    ]
    private static let legsB: [String] = [
        "   Xgg  ggX     ",
        "    Xk  kX      ",
        "    Xkkkk X     ",
    ]

    static func playerTexture(facing: Facing, frame: Int) -> SKTexture {
        let legs = frame == 0 ? legsA : legsB
        switch facing {
        case .down:  return tex(bodyDown + legs)
        case .up:    return tex(bodyUp + legs)
        case .right: return tex(bodyRight + legs)
        case .left:  return tex(bodyRight + legs, flipH: true)
        }
    }

    static func walkFrames(facing: Facing) -> [SKTexture] {
        [playerTexture(facing: facing, frame: 0),
         playerTexture(facing: facing, frame: 1)]
    }
}
