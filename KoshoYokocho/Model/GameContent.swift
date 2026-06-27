//
//  GameContent.swift
//  古書横丁ものがたり — 初期コンテンツ定義
//
//  新規ゲーム時の店舗・図鑑データなど、静的な「素材」をまとめる。
//

import Foundation

enum GameContent {

    /// 新規ゲームの店舗一覧。
    static func initialShops() -> [Shop] {
        [
            Shop(
                id: "shop_bookcafe",
                displayName: "古書喫茶 ねこのしっぽ",
                kind: .bookCafe,
                isRestored: true,
                restoredName: nil,
                restoreHint: nil
            ),
            Shop(
                id: "shop_curry",
                displayName: "老舗カレー 莫迦楼（ばかろう）",
                kind: .curry,
                isRestored: true,
                restoredName: nil,
                restoreHint: nil
            ),
            Shop(
                id: "shop_vacant",
                displayName: "空き店舗",
                kind: .vacant,
                isRestored: false,
                restoredName: "甘味処 みかづき堂",
                restoreHint: "カレー屋のグルメ対決に勝つと再生できそうだ。"
            ),
        ]
    }

    /// 図鑑の全エントリ（未収集状態）。
    static func allBooks() -> [BookEntry] {
        [
            BookEntry(
                id: "book_neko",
                title: "看板猫奇譚",
                author: "夜雀 庵",
                era: "大正末・私家版",
                value: 1200,
                isCollected: false
            ),
            BookEntry(
                id: "book_curry",
                title: "横丁カレー譜",
                author: "莫迦楼 主人",
                era: "昭和初期・復刻",
                value: 800,
                isCollected: false
            ),
            BookEntry(
                id: "book_map",
                title: "古地図にみる横丁",
                author: "編者不詳",
                era: "明治・木版",
                value: 3000,
                isCollected: false
            ),
        ]
    }

    // MARK: - バフ定義

    /// 老舗カレーを食べたときの探索バフ。
    static func curryBuff() -> Buff {
        Buff(
            id: "buff_curry",
            name: "老舗カレーの活力",
            source: "莫迦楼スペシャルカレー",
            kyoyoBonus: 0,
            mekikiBonus: 1,
            shokutsuBonus: 2,
            remaining: 90,
            duration: 90
        )
    }

    /// 珈琲（喫茶）の小休止バフ。
    static func coffeeBuff() -> Buff {
        Buff(
            id: "buff_coffee",
            name: "一杯の珈琲",
            source: "本日の珈琲",
            kyoyoBonus: 2,
            mekikiBonus: 1,
            shokutsuBonus: 0,
            remaining: 120,
            duration: 120
        )
    }
}
