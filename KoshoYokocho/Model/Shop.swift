//
//  Shop.swift
//  古書横丁ものがたり — 店舗モデル
//
//  発展（空き店舗の再生）はメイン進行の中核。
//

import Foundation

/// 店舗の種別。
enum ShopKind: String, Codable {
    case bookCafe   // 自分の古書喫茶（拠点・セーブ地点）
    case curry      // 老舗カレー屋（グルメ対決）
    case vacant     // 空き店舗（条件達成で再生）
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
