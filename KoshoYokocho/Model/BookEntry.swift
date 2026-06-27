//
//  BookEntry.swift
//  古書横丁ものがたり — 蒐集（図鑑）モデル
//

import Foundation

/// 図鑑（本棚）に並ぶ一冊。
struct BookEntry: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var author: String
    /// 年代・出自などのフレーバー。
    var era: String
    /// おおよその価値（目利き対決のフレーバー）。
    var value: Int
    /// 図鑑に登録済みか（拾得・入手で true）。
    var isCollected: Bool
}
