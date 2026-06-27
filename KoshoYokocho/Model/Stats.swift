//
//  Stats.swift
//  古書横丁ものがたり — ステータス
//
//  レトロJRPGの能力値に相当する3本柱の数値。
//  教養(kyoyo) / 目利き(mekiki) / 食通(shokutsu)。
//

import Foundation

/// プレイヤーの能力値。対決の判定やフレーバーに使う。
struct Stats: Codable, Equatable {
    /// 教養：知識・推理に効く。
    var kyoyo: Int
    /// 目利き：真贋・価値の鑑定に効く（目利き対決）。
    var mekiki: Int
    /// 食通：味・調理の見極めに効く（グルメ対決）。
    var shokutsu: Int

    static let starting = Stats(kyoyo: 3, mekiki: 3, shokutsu: 3)

    /// 一時バフを加算した実効値を返す。
    func applying(_ buff: Buff?) -> Stats {
        guard let buff else { return self }
        return Stats(
            kyoyo: kyoyo + buff.kyoyoBonus,
            mekiki: mekiki + buff.mekikiBonus,
            shokutsu: shokutsu + buff.shokutsuBonus
        )
    }
}

/// 食べると得られる探索バフ。残り時間で自然消滅する。
struct Buff: Codable, Equatable, Identifiable {
    var id: String
    /// 表示名（例：「老舗カレーの活力」）。
    var name: String
    /// 由来となった料理名。
    var source: String
    var kyoyoBonus: Int
    var mekikiBonus: Int
    var shokutsuBonus: Int
    /// 残り効果秒数。0以下で消滅。
    var remaining: TimeInterval
    /// バフ全体の長さ（ゲージ表示用）。
    var duration: TimeInterval

    var progress: Double {
        guard duration > 0 else { return 0 }
        return max(0, min(1, remaining / duration))
    }
}
