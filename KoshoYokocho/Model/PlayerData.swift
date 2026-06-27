//
//  PlayerData.swift
//  古書横丁ものがたり — プレイヤー永続データ
//

import CoreGraphics
import Foundation

/// 向き。歩行アニメ・調べる方向に使う。
enum Facing: String, Codable, CaseIterable {
    case down, up, left, right

    /// 単位ベクトル（SpriteKit座標系：上が +y）。
    var vector: CGVector {
        switch self {
        case .down:  return CGVector(dx: 0, dy: -1)
        case .up:    return CGVector(dx: 0, dy: 1)
        case .left:  return CGVector(dx: -1, dy: 0)
        case .right: return CGVector(dx: 1, dy: 0)
        }
    }
}

/// セーブ対象となるプレイヤー情報。座標はワールド（ポイント）座標で保持する。
struct PlayerData: Codable, Equatable {
    var name: String
    var stats: Stats
    /// ワールド座標（シーン上の位置）。
    var x: CGFloat
    var y: CGFloat
    var facing: Facing
    /// 現在有効な探索バフ（無ければ nil）。
    var buff: Buff?

    var position: CGPoint {
        get { CGPoint(x: x, y: y) }
        set { x = newValue.x; y = newValue.y }
    }

    static func newGame(spawn: CGPoint) -> PlayerData {
        PlayerData(
            name: "あるじ",
            stats: .starting,
            x: spawn.x,
            y: spawn.y,
            facing: .down,
            buff: nil
        )
    }
}
