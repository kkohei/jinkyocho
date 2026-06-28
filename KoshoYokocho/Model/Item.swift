//
//  Item.swift
//  古書横丁ものがたり — 装備アイテム（武器・魔導書）
//
//  ゾンビ撃破で得た「古銭」で、武器屋・魔導書店から購入して装備する。
//  武器は通常攻撃力、魔導書は必殺「とっておき」を強化する。
//

import Foundation

/// 装備スロット。
enum EquipSlot: String, Codable {
    case weapon    // 武器（武器屋）
    case grimoire  // 魔導書（魔導書店）
}

/// 店で売っている装備品。
struct ShopItem: Identifiable {
    let id: String
    let name: String
    let slot: EquipSlot
    let price: Int
    /// 通常攻撃へのダメージ加算（武器）。
    let atkBonus: Int
    /// 必殺「とっておき」へのダメージ加算（魔導書）。
    let specialBonus: Int
    let desc: String
}

enum ItemCatalog {
    static let all: [String: ShopItem] = [
        // --- 武器（武器屋）---
        "w_bookmark": ShopItem(
            id: "w_bookmark", name: "鋼の栞（はがねのしおり）", slot: .weapon,
            price: 18, atkBonus: 3, specialBonus: 0,
            desc: "鋭く研いだ栞。攻撃 +3"
        ),
        "w_paperweight": ShopItem(
            id: "w_paperweight", name: "龍の文鎮（ぶんちん）", slot: .weapon,
            price: 45, atkBonus: 7, specialBonus: 0,
            desc: "ずっしり重い鉄塊。攻撃 +7"
        ),
        // --- 魔導書（魔導書店）---
        "g_fire": ShopItem(
            id: "g_fire", name: "火炎の魔導書", slot: .grimoire,
            price: 25, atkBonus: 0, specialBonus: 8,
            desc: "とっておきに炎を宿す。必殺 +8"
        ),
        "g_void": ShopItem(
            id: "g_void", name: "虚無の魔導書", slot: .grimoire,
            price: 60, atkBonus: 0, specialBonus: 16,
            desc: "頁の奥の虚無を放つ。必殺 +16"
        ),
    ]

    static func item(_ id: String) -> ShopItem? { all[id] }

    /// 指定スロットの商品一覧（価格順）。
    static func items(slot: EquipSlot) -> [ShopItem] {
        all.values.filter { $0.slot == slot }.sorted { $0.price < $1.price }
    }
}
