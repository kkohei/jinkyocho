//
//  DuelModels.swift
//  古書横丁ものがたり — ターン制コマンド「対決」
//
//  v0 では開発が軽い「グルメ対決」だけを味見実装する。
//  「戦闘」を読み替えたターン制：プレイヤーと相手が交互に手を選び、
//  一品の完成度（スコア）を競う。
//

import Foundation

/// 対決の種別。v0 はグルメのみ稼働。
enum DuelKind: String, Codable {
    case gourmet  // グルメ対決
    case appraisal // 目利き対決（後続フェーズ）
}

/// グルメ対決で選べるコマンド。
enum GourmetCommand: String, CaseIterable, Identifiable, Codable {
    case ingredient // 食材：素材を吟味して土台を作る
    case recipe     // レシピ：構成を練って伸び幅を作る
    case cook       // 調理：火入れで一気に仕上げる

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ingredient: return "食材"
        case .recipe:     return "レシピ"
        case .cook:       return "調理"
        }
    }

    var hint: String {
        switch self {
        case .ingredient: return "素材を吟味（安定して加点）"
        case .recipe:     return "構成を練る（次の調理が伸びる）"
        case .cook:       return "火入れで仕上げ（レシピ後は大きく加点）"
        }
    }
}

/// 1ターンのログ行。
struct DuelLogLine: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isPlayer: Bool
}

/// 進行中のグルメ対決セッション。GameState から生成・参照される。
struct DuelSession: Identifiable, Equatable {
    let id = UUID()
    let kind: DuelKind
    let opponentName: String
    let title: String          // 例：「カレーで勝負！」
    let totalTurns: Int

    var turn: Int = 1
    var playerScore: Int = 0
    var opponentScore: Int = 0
    /// レシピ直後ボーナスの管理（プレイヤー）。
    var playerRecipePrimed: Bool = false
    var log: [DuelLogLine] = []
    var isFinished: Bool = false
    /// 勝敗結果（終了後にセット）。
    var didWin: Bool? = nil

    static func == (lhs: DuelSession, rhs: DuelSession) -> Bool {
        lhs.id == rhs.id &&
        lhs.turn == rhs.turn &&
        lhs.playerScore == rhs.playerScore &&
        lhs.opponentScore == rhs.opponentScore &&
        lhs.isFinished == rhs.isFinished &&
        lhs.log == rhs.log
    }
}
