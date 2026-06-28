//
//  Shop.swift
//  古書横丁ものがたり — 店舗モデル
//
//  発展（空き店舗の再生）はメイン進行の中核。
//

import Foundation

/// 店舗の種別。
enum ShopKind: String, Codable {
    case bookCafe   // 自分の古書喫茶（安全地帯・セーブ地点）
    case curry      // 生き残りのカレー屋（腹ごしらえ＝回復＋バフ）
    case weapon     // 武器屋（武器を購入）
    case grimoire   // 魔導書店（魔導書を購入）
    case vacant     // 占拠された店（ボス撃破で復興）
}

/// 横丁の一軒。
struct Shop: Codable, Identifiable, Equatable {
    var id: String
    var displayName: String
    var kind: ShopKind
    /// 空き店舗が再生済みかどうか。
    var isRestored: Bool
    /// 再生後の名前（vacant のみ意味を持つ）。
    var restoredName: String?
    /// 再生条件の説明文（HUD表示用）。
    var restoreHint: String?

    /// 入口で表示する現在の名前。
    var currentName: String {
        if kind == .vacant {
            return isRestored ? (restoredName ?? displayName) : displayName
        }
        return displayName
    }
}
