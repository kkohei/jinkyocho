//
//  Enemy.swift
//  古書横丁ものがたり — 敵（ゾンビ／亡者）定義
//
//  呪われた本に憑かれた亡者たち。フィールド接触＝固定戦、歩行中＝ランダム戦。
//  battleAsset に対応するPNGを Assets.xcassets に置くと戦闘画面で使われる
//  （未用意ならコード描画のゾンビにフォールバック）。
//

import Foundation

/// ゾンビの色バリエーション（コード描画フォールバック用）。
enum ZombieTint {
    case pale
    case rotten
    case boss
}

/// 敵の種別（静的カタログ。セーブ対象ではない）。
struct EnemyType {
    let id: String
    let name: String
    let maxHP: Int
    let atk: ClosedRange<Int>
    let big: ClosedRange<Int>
    let bigChance: Int          // 0...10 のうち大技を出す確率
    let rewardShokutsu: Int     // 撃破で上がる食通
    let rewardCoins: Int        // 撃破で得る古銭
    let tint: ZombieTint        // フォールバック色
    let battleAsset: String     // 戦闘画面に出す画像アセット名
}

enum EnemyCatalog {

    static let all: [String: EnemyType] = [

        // ── 既存（フィールド配置・進行の要）──
        "z_weak":  EnemyType(id: "z_weak",  name: "古書ゾンビ", maxHP: 20,
            atk: 4...7,  big: 8...11,  bigChance: 1, rewardShokutsu: 0, rewardCoins: 10, tint: .pale,   battleAsset: "battle_zombie_pale"),
        "z_mid":   EnemyType(id: "z_mid",   name: "装丁鬼（そうていき）", maxHP: 34,
            atk: 5...9,  big: 10...13, bigChance: 2, rewardShokutsu: 1, rewardCoins: 18, tint: .rotten, battleAsset: "battle_zombie_rotten"),
        "z_guard": EnemyType(id: "z_guard", name: "製本主（せいほんしゅ）", maxHP: 52,
            atk: 6...10, big: 13...17, bigChance: 3, rewardShokutsu: 2, rewardCoins: 40, tint: .boss,   battleAsset: "battle_zombie_boss"),

        // ── かわいい雑魚（弱）──
        "honslime":      EnemyType(id: "honslime",      name: "ほんスライム", maxHP: 12,
            atk: 2...4, big: 5...6, bigChance: 1, rewardShokutsu: 0, rewardCoins: 6,  tint: .pale, battleAsset: "battle_honslime"),
        "bookmarkghost": EnemyType(id: "bookmarkghost", name: "しおりおばけ", maxHP: 10,
            atk: 2...4, big: 5...7, bigChance: 1, rewardShokutsu: 0, rewardCoins: 7,  tint: .pale, battleAsset: "battle_bookmarkghost"),
        "inkblob":       EnemyType(id: "inkblob",       name: "インクこぞう", maxHP: 14,
            atk: 3...5, big: 6...8, bigChance: 1, rewardShokutsu: 0, rewardCoins: 8,  tint: .pale, battleAsset: "battle_inkblob"),
        "babyramen":     EnemyType(id: "babyramen",     name: "ちびラーメン", maxHP: 15,
            atk: 3...5, big: 6...8, bigChance: 1, rewardShokutsu: 0, rewardCoins: 9,  tint: .pale, battleAsset: "battle_babyramen"),
        "currybun":      EnemyType(id: "currybun",      name: "カレーまん", maxHP: 16,
            atk: 3...5, big: 6...8, bigChance: 1, rewardShokutsu: 0, rewardCoins: 9,  tint: .pale, battleAsset: "battle_currybun"),
        "babyzombie":    EnemyType(id: "babyzombie",    name: "こぞんび", maxHP: 13,
            atk: 2...4, big: 5...7, bigChance: 1, rewardShokutsu: 0, rewardCoins: 7,  tint: .pale, battleAsset: "battle_babyzombie"),

        // ── 食べ物・本の亡者（中）──
        "bookbat":   EnemyType(id: "bookbat",   name: "魔導書コウモリ", maxHP: 26,
            atk: 5...8,  big: 9...11,  bigChance: 2, rewardShokutsu: 1, rewardCoins: 15, tint: .rotten, battleAsset: "battle_bookbat"),
        "bookgolem": EnemyType(id: "bookgolem", name: "古書ゴーレム", maxHP: 40,
            atk: 6...9,  big: 11...13, bigChance: 2, rewardShokutsu: 1, rewardCoins: 20, tint: .rotten, battleAsset: "battle_bookgolem"),
        "ramenbowl": EnemyType(id: "ramenbowl", name: "ラーメン丼の主", maxHP: 30,
            atk: 5...8,  big: 10...12, bigChance: 2, rewardShokutsu: 1, rewardCoins: 16, tint: .rotten, battleAsset: "battle_ramenbowl"),
        "currypot":  EnemyType(id: "currypot",  name: "カレー鍋スライム", maxHP: 32,
            atk: 5...9,  big: 10...12, bigChance: 2, rewardShokutsu: 1, rewardCoins: 17, tint: .rotten, battleAsset: "battle_currypot"),

        // ── 中ボス級（強）──
        "ramenchef": EnemyType(id: "ramenchef", name: "ラーメン職人ゾンビ", maxHP: 44,
            atk: 6...10, big: 12...14, bigChance: 3, rewardShokutsu: 1, rewardCoins: 24, tint: .boss, battleAsset: "battle_ramenchef"),
        "naangolem": EnemyType(id: "naangolem", name: "ナンゴーレム", maxHP: 46,
            atk: 6...10, big: 12...15, bigChance: 3, rewardShokutsu: 1, rewardCoins: 26, tint: .boss, battleAsset: "battle_naangolem"),
    ]

    static func type(_ id: String) -> EnemyType {
        all[id] ?? all["z_weak"]!
    }

    /// ランダムエンカウントの抽選表（重みつき）。大ボス z_guard は固定戦のみで除外。
    private static let encounterTable: [(id: String, weight: Int)] = [
        ("honslime", 5), ("bookmarkghost", 5), ("inkblob", 4),
        ("babyramen", 4), ("currybun", 4), ("babyzombie", 5),
        ("z_weak", 3),
        ("bookbat", 3), ("ramenbowl", 3), ("currypot", 3),
        ("bookgolem", 2), ("z_mid", 2),
        ("ramenchef", 1), ("naangolem", 1),
    ]

    /// 重みに従って1体抽選する。
    static func randomEncounter() -> EnemyType {
        let total = encounterTable.reduce(0) { $0 + $1.weight }
        var roll = Int.random(in: 0..<total)
        for entry in encounterTable {
            if roll < entry.weight { return type(entry.id) }
            roll -= entry.weight
        }
        return type("honslime")
    }
}
