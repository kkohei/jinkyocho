//
//  DuelModels.swift
//  古書横丁ものがたり — ターン制コマンド「対決」
//
//  v0 はグルメ対決のみ稼働。ドラクエ風の HP バトルとして実装する：
//  お互いの「自信（HP）」を削り合い、先に相手の自信を 0 にした方が勝ち。
//

import Foundation

/// 対決の種別。v0 はグルメのみ。
enum DuelKind: String, Codable {
    case gourmet   // グルメ対決
    case appraisal // 目利き対決（後続フェーズ）
}

/// バトルコマンド（ドラクエ風）。
enum BattleCommand: String, CaseIterable, Identifiable, Codable {
    case attack   // たたかう：自慢の一皿で削る
    case special  // とっておき：気合を使って大ダメージ
    case defend   // ととのえる：被ダメ軽減＋気合回復

    var id: String { rawValue }

    var label: String {
        switch self {
        case .attack:  return "たたかう"
        case .special: return "とっておき"
        case .defend:  return "ととのえる"
        }
    }

    var hint: String {
        switch self {
        case .attack:  return "自慢の一皿を出す（食通でダメージ）"
        case .special: return "気合4を使う必殺の逸品（大ダメージ）"
        case .defend:  return "味をととのえる（次の被ダメ半減・気合+3）"
        }
    }

    /// 必殺に必要な気合。
    static let specialCost = 4
}

/// 1ターンのログ行。
struct DuelLogLine: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isPlayer: Bool
}

/// 進行中の戦闘（ゾンビとの HP バトル）。GameState から生成・参照される。
struct DuelSession: Identifiable, Equatable {
    let id = UUID()
    let kind: DuelKind
    /// 敵（ゾンビ）の表示名。
    let opponentName: String
    let title: String
    /// 倒したときに消す対象の placement id（フィールド上のゾンビ）。
    let enemyPlacementID: String
    /// 戦闘画面に出す敵の見た目。
    let enemyTint: ZombieTint

    // 体力（HP）
    var playerHP: Int
    var playerMaxHP: Int
    var enemyHP: Int
    var enemyMaxHP: Int

    // 気合（必殺の燃料）
    var playerKiai: Int
    var playerMaxKiai: Int

    // 敵の攻撃パラメータ
    var enemyAtkLow: Int
    var enemyAtkHigh: Int
    var enemyBigLow: Int
    var enemyBigHigh: Int
    var enemyBigChance: Int
    var enemyRewardShokutsu: Int
    var enemyRewardCoins: Int

    var turn: Int = 1
    /// このターン、プレイヤーが「ととのえる」で防御中か。
    var playerDefending: Bool = false

    var log: [DuelLogLine] = []
    var isFinished: Bool = false
    /// 勝敗結果（終了後にセット）。
    var didWin: Bool? = nil

    var playerHPRatio: Double { playerMaxHP > 0 ? Double(playerHP) / Double(playerMaxHP) : 0 }
    var enemyHPRatio: Double { enemyMaxHP > 0 ? Double(enemyHP) / Double(enemyMaxHP) : 0 }
    var canUseSpecial: Bool { playerKiai >= BattleCommand.specialCost && !isFinished }

    /// プレイヤーの現在ステータスとゾンビから戦闘を生成する。
    static func versus(enemy: EnemyType, placementID: String,
                       playerHP: Int, playerMaxHP: Int,
                       playerKiai: Int, playerMaxKiai: Int) -> DuelSession {
        DuelSession(
            kind: .gourmet,
            opponentName: enemy.name,
            title: "ゾンビ襲来！",
            enemyPlacementID: placementID,
            enemyTint: enemy.tint,
            playerHP: playerHP, playerMaxHP: playerMaxHP,
            enemyHP: enemy.maxHP, enemyMaxHP: enemy.maxHP,
            playerKiai: playerKiai, playerMaxKiai: playerMaxKiai,
            enemyAtkLow: enemy.atk.lowerBound, enemyAtkHigh: enemy.atk.upperBound,
            enemyBigLow: enemy.big.lowerBound, enemyBigHigh: enemy.big.upperBound,
            enemyBigChance: enemy.bigChance,
            enemyRewardShokutsu: enemy.rewardShokutsu,
            enemyRewardCoins: enemy.rewardCoins
        )
    }
}
