//
//  Enemy.swift
//  古書横丁ものがたり — ゾンビ（敵）定義
//
//  古書街を荒らす「亡者（古書ゾンビ）」。呪われた本に憑かれた成れの果て、という
//  和ファンタジーの設定。フィールドで接触すると HP バトルになる。
//

import Foundation

/// 敵の種別（静的カタログ。セーブ対象ではない）。
struct EnemyType {
    let id: String
    let name: String
    let maxHP: Int
    /// 通常攻撃のダメージ幅。
    let atk: ClosedRange<Int>
    /// 大技のダメージ幅。
    let big: ClosedRange<Int>
    /// 大技を出す確率（0...10 のうち）。
    let bigChance: Int
    /// 撃破時に上がる食通（強さ）。
    let rewardShokutsu: Int
    /// 見た目の色合い（プレースホルダ・ドット絵用）。
    let tint: ZombieTint
}

/// ゾンビの色バリエーション。
enum ZombieTint {
    case pale   // 古書ゾンビ（青白い）
    case rotten // 装丁鬼（黒ずみ）
    case boss   // 製本主（赤黒い大物）
}

enum EnemyCatalog {
    static let all: [String: EnemyType] = [
        "z_weak": EnemyType(
            id: "z_weak", name: "古書ゾンビ", maxHP: 20,
            atk: 4...7, big: 8...11, bigChance: 1,
            rewardShokutsu: 0, tint: .pale
        ),
        "z_mid": EnemyType(
            id: "z_mid", name: "装丁鬼（そうていき）", maxHP: 34,
            atk: 5...9, big: 10...13, bigChance: 2,
            rewardShokutsu: 1, tint: .rotten
        ),
        "z_guard": EnemyType(
            id: "z_guard", name: "製本主（せいほんしゅ）", maxHP: 48,
            atk: 6...10, big: 12...16, bigChance: 3,
            rewardShokutsu: 1, tint: .boss
        ),
    ]

    static func type(_ id: String) -> EnemyType {
        all[id] ?? all["z_weak"]!
    }
}
