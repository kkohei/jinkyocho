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
    /// 体力（戦闘間で持続。0 になると喫茶店へ戻される）。
    var hp: Int
    var maxHP: Int
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

    var hpRatio: Double { maxHP > 0 ? Double(hp) / Double(maxHP) : 0 }

    static let baseMaxHP = 30

    static func newGame(spawn: CGPoint) -> PlayerData {
        PlayerData(
            name: "あるじ",
            stats: .starting,
            hp: baseMaxHP,
            maxHP: baseMaxHP,
            x: spawn.x,
            y: spawn.y,
            facing: .down,
            buff: nil
        )
    }
}
