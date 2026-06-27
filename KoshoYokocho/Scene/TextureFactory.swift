//
//  TextureFactory.swift
//  古書横丁ものがたり — プレースホルダのドット絵テクスチャ生成
//
//  v0 では画像素材を持たず、コードで 16x16 のドット絵を描く。
//  すべて filteringMode = .nearest にしてレトロな質感を出す。
//

import SpriteKit
import UIKit

enum TextureFactory {

    /// 小さなキャンバスに描いて nearest なテクスチャを返す。
    private static func make(_ pixels: Int = 16,
                             _ draw: (CGContext, CGFloat) -> Void) -> SKTexture {
        let size = CGSize(width: pixels, height: pixels)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { rctx in
            let cg = rctx.cgContext
            // UIGraphicsImageRenderer は左上原点(y下向き)。
            // 以降のドット絵コードは「y が大きいほど上」で描けるよう原点を左下へ反転する。
            cg.translateBy(x: 0, y: size.height)
            cg.scaleBy(x: 1, y: -1)
            draw(cg, CGFloat(pixels))
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }

    private static func fill(_ ctx: CGContext, _ color: UIColor, _ rect: CGRect) {
        ctx.setFillColor(color.cgColor)
        ctx.fill(rect)
    }

    // MARK: - タイル

    static func roadTile() -> SKTexture {
        make { ctx, s in
            fill(ctx, UIColor(red: 0.78, green: 0.71, blue: 0.55, alpha: 1), CGRect(x: 0, y: 0, width: s, height: s))
            // 石畳の目地
            fill(ctx, UIColor(red: 0.70, green: 0.63, blue: 0.47, alpha: 1), CGRect(x: 0, y: s/2, width: s, height: 1))
            fill(ctx, UIColor(red: 0.70, green: 0.63, blue: 0.47, alpha: 1), CGRect(x: s/2, y: 0, width: 1, height: s))
        }
    }

    static func wallTile() -> SKTexture {
        make { ctx, s in
            // 建物の壁＋窓
            fill(ctx, UIColor(red: 0.36, green: 0.26, blue: 0.22, alpha: 1), CGRect(x: 0, y: 0, width: s, height: s))
            fill(ctx, UIColor(red: 0.46, green: 0.34, blue: 0.28, alpha: 1), CGRect(x: 1, y: 1, width: s-2, height: s-2))
            fill(ctx, UIColor(red: 0.95, green: 0.83, blue: 0.45, alpha: 1), CGRect(x: 3, y: 3, width: 4, height: 4))
            fill(ctx, UIColor(red: 0.95, green: 0.83, blue: 0.45, alpha: 1), CGRect(x: 9, y: 3, width: 4, height: 4))
        }
    }

    // MARK: - 調べ対象

    /// 店の入口（暖簾風）。色でジャンルを示す。
    static func shopDoor(color: UIColor) -> SKTexture {
        make { ctx, s in
            fill(ctx, UIColor(red: 0.20, green: 0.14, blue: 0.12, alpha: 1), CGRect(x: 2, y: 0, width: s-4, height: s-2))
            // 暖簾
            fill(ctx, color, CGRect(x: 1, y: s-6, width: s-2, height: 5))
            fill(ctx, UIColor.white.withAlphaComponent(0.85), CGRect(x: s/2 - 1, y: s-6, width: 2, height: 5))
        }
    }

    static func vacantDoor() -> SKTexture {
        make { ctx, s in
            // シャッターの下りた空き店舗
            fill(ctx, UIColor(red: 0.30, green: 0.30, blue: 0.32, alpha: 1), CGRect(x: 2, y: 0, width: s-4, height: s-1))
            for i in stride(from: 1, to: Int(s)-1, by: 2) {
                fill(ctx, UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1), CGRect(x: 2, y: CGFloat(i), width: s-4, height: 1))
            }
        }
    }

    static func catNPC() -> SKTexture {
        make { ctx, s in
            let body = UIColor(red: 0.85, green: 0.62, blue: 0.30, alpha: 1)
            fill(ctx, body, CGRect(x: 4, y: 2, width: 8, height: 8))
            // 耳
            fill(ctx, body, CGRect(x: 4, y: 9, width: 2, height: 3))
            fill(ctx, body, CGRect(x: 10, y: 9, width: 2, height: 3))
            // 目
            fill(ctx, .black, CGRect(x: 6, y: 6, width: 1, height: 2))
            fill(ctx, .black, CGRect(x: 9, y: 6, width: 1, height: 2))
            // しっぽ
            fill(ctx, body, CGRect(x: 11, y: 2, width: 3, height: 1))
        }
    }

    static func bookPickup() -> SKTexture {
        make { ctx, s in
            fill(ctx, UIColor(red: 0.65, green: 0.20, blue: 0.22, alpha: 1), CGRect(x: 4, y: 3, width: 8, height: 10))
            fill(ctx, UIColor(red: 0.92, green: 0.88, blue: 0.78, alpha: 1), CGRect(x: 5, y: 4, width: 6, height: 8))
            fill(ctx, UIColor(red: 0.65, green: 0.20, blue: 0.22, alpha: 1), CGRect(x: 7, y: 4, width: 1, height: 8))
        }
    }

    // MARK: - プレイヤー（向き別 2フレーム）

    /// 向きとフレーム（0/1）でプレイヤーのドット絵を作る。
    static func playerTexture(facing: Facing, frame: Int) -> SKTexture {
        make { ctx, s in
            let skin = UIColor(red: 0.98, green: 0.82, blue: 0.66, alpha: 1)
            let hair = UIColor(red: 0.20, green: 0.16, blue: 0.14, alpha: 1)
            let cloth = UIColor(red: 0.30, green: 0.45, blue: 0.60, alpha: 1)
            let shoe = UIColor(red: 0.18, green: 0.16, blue: 0.16, alpha: 1)

            // 頭
            fill(ctx, hair, CGRect(x: 5, y: 10, width: 6, height: 4))
            fill(ctx, skin, CGRect(x: 5, y: 8, width: 6, height: 3))
            // 顔の向き（目）
            switch facing {
            case .down:
                fill(ctx, .black, CGRect(x: 6, y: 9, width: 1, height: 1))
                fill(ctx, .black, CGRect(x: 9, y: 9, width: 1, height: 1))
            case .up:
                break // 後ろ向きは目なし
            case .left:
                fill(ctx, .black, CGRect(x: 6, y: 9, width: 1, height: 1))
            case .right:
                fill(ctx, .black, CGRect(x: 9, y: 9, width: 1, height: 1))
            }
            // 胴
            fill(ctx, cloth, CGRect(x: 5, y: 4, width: 6, height: 5))
            // 脚（フレームで左右を入れ替えて歩行感）
            if frame == 0 {
                fill(ctx, shoe, CGRect(x: 5, y: 2, width: 2, height: 2))
                fill(ctx, shoe, CGRect(x: 9, y: 1, width: 2, height: 2))
            } else {
                fill(ctx, shoe, CGRect(x: 5, y: 1, width: 2, height: 2))
                fill(ctx, shoe, CGRect(x: 9, y: 2, width: 2, height: 2))
            }
        }
    }

    /// 向きごとの歩行アニメ（2フレーム）。
    static func walkFrames(facing: Facing) -> [SKTexture] {
        [playerTexture(facing: facing, frame: 0),
         playerTexture(facing: facing, frame: 1)]
    }
}
