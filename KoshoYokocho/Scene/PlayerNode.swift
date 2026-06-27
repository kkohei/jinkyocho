//
//  PlayerNode.swift
//  古書横丁ものがたり — プレイヤースプライト＋歩行アニメ
//

import SpriteKit

final class PlayerNode: SKSpriteNode {

    private var currentFacing: Facing = .down
    private var isWalking = false
    private let walkActionKey = "walk"

    /// 当たり判定に使う半径（タイルより少し小さく）。
    let collisionRadius: CGFloat = YokochoMap.tileSize * 0.32

    init() {
        let tex = TextureFactory.playerTexture(facing: .down, frame: 0)
        super.init(texture: tex, color: .clear, size: CGSize(width: YokochoMap.tileSize,
                                                             height: YokochoMap.tileSize))
        zPosition = 50
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// 向きと歩行状態を更新し、必要ならアニメを切り替える。
    func update(facing: Facing, moving: Bool) {
        let facingChanged = facing != currentFacing
        currentFacing = facing

        if moving {
            if !isWalking || facingChanged {
                isWalking = true
                removeAction(forKey: walkActionKey)
                let frames = TextureFactory.walkFrames(facing: facing)
                let anim = SKAction.animate(with: frames, timePerFrame: 0.18, resize: false, restore: false)
                run(SKAction.repeatForever(anim), withKey: walkActionKey)
            }
        } else {
            if isWalking || facingChanged {
                isWalking = false
                removeAction(forKey: walkActionKey)
                texture = TextureFactory.playerTexture(facing: facing, frame: 0)
            }
        }
    }
}
