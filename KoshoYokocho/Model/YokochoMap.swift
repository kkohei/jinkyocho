//
//  YokochoMap.swift
//  古書横丁ものがたり — 横丁1エリアのタイルマップ定義
//
//  ASCII でタイル（壁/道）を、placements で調べられる対象（店入口/住人/拾得物）を
//  別々に定義する。シーンはこれを読んでタイルとノードを敷き、当たり判定に使う。
//

import CoreGraphics
import Foundation

/// グリッド上の座標（左上が row0,col0）。
struct GridPos: Equatable {
    var col: Int
    var row: Int
}

/// タイル種別。
enum TileType {
    case road     // 歩ける
    case wall     // 建物・塀（ブロック）

    var isWalkable: Bool { self == .road }
}

/// 調べられる対象・敵の種別。
enum PlacementKind: Equatable {
    case shop(String)    // 店入口（shop id）
    case npc(String)     // 住人（npc id）
    case pickup(String)  // 拾得物（book id）
    case enemy(String)   // ゾンビ（EnemyType id）。接触で戦闘
}

/// マップ上に配置する対象。
struct Placement: Equatable {
    let id: String
    let kind: PlacementKind
    let pos: GridPos
}

/// 横丁マップ（v0 は1エリア固定）。
enum YokochoMap {
    /// 1タイルの一辺（ポイント）。全テクスチャ nearest 前提のドット感を出すため大きめ。
    static let tileSize: CGFloat = 32

    /// タイルレイアウト。'#' = 壁/建物, '.' = 道。
    /// 上下に建物群、中央〜下に広場と拠点。ポートレート向けの縦長。
    static let rows: [String] = [
        "###############",
        "#.............#",
        "#.###.###.###.#",
        "#.#.#.#.#.#.#.#",
        "#.#.#.#.#.#.#.#",
        "#.............#",
        "#.............#",
        "#....#####....#",
        "#....#...#....#",
        "#....#####....#",
        "#.............#",
        "#.............#",
        "#.###.....###.#",
        "#.#.#.....#.#.#",
        "#.###.....###.#",
        "#.............#",
        "#.............#",
        "#.............#",
        "#.............#",
        "###############",
    ]

    static var colCount: Int { rows.first?.count ?? 0 }
    static var rowCount: Int { rows.count }

    /// マップ上の配置。座標は道タイル上（建物の手前など）。
    static let placements: [Placement] = [
        // 自分の古書喫茶（安全地帯・セーブ地点）：左上の建物の手前
        Placement(id: "shop_bookcafe", kind: .shop("shop_bookcafe"), pos: GridPos(col: 2, row: 5)),
        // 老舗カレー屋（生き残りの主人。腹ごしらえ＆戦い方の指南）：中央上の建物の手前
        Placement(id: "shop_curry",    kind: .shop("shop_curry"),    pos: GridPos(col: 7, row: 5)),
        // ゾンビに占拠された店：右上の建物の手前（ボスを倒すと復興）
        Placement(id: "shop_vacant",   kind: .shop("shop_vacant"),   pos: GridPos(col: 12, row: 5)),
        // 看板猫（語り部）
        Placement(id: "npc_cat",       kind: .npc("npc_cat"),        pos: GridPos(col: 7, row: 10)),
        // 武器屋：左下の建物の手前
        Placement(id: "shop_weapon",   kind: .shop("shop_weapon"),   pos: GridPos(col: 3, row: 15)),
        // 魔導書店：右下の建物の手前
        Placement(id: "shop_grimoire", kind: .shop("shop_grimoire"), pos: GridPos(col: 11, row: 15)),
        // 救出する稀覯本（図鑑登録）
        Placement(id: "pickup_book1",  kind: .pickup("book_neko"),   pos: GridPos(col: 6, row: 16)),

        // --- ゾンビ（接触で戦闘）---
        Placement(id: "zombie_a",     kind: .enemy("z_weak"),  pos: GridPos(col: 5, row: 11)),
        Placement(id: "zombie_b",     kind: .enemy("z_mid"),   pos: GridPos(col: 9, row: 6)),
        // 占拠店の前を守るボスゾンビ。倒すと店が復興する
        Placement(id: "zombie_guard", kind: .enemy("z_guard"), pos: GridPos(col: 12, row: 6)),
    ]

    /// プレイヤーの初期スポーン（道タイル）。
    static let spawn = GridPos(col: 7, row: 17)

    // MARK: - 座標変換

    /// グリッド座標 → ワールド座標（タイル中心）。SpriteKit は y 上向きなので row を反転。
    static func worldPosition(of pos: GridPos) -> CGPoint {
        let x = CGFloat(pos.col) * tileSize + tileSize / 2
        let y = CGFloat(rowCount - 1 - pos.row) * tileSize + tileSize / 2
        return CGPoint(x: x, y: y)
    }

    /// ワールド座標 → グリッド座標。
    static func gridPosition(of point: CGPoint) -> GridPos {
        let col = Int(point.x / tileSize)
        let row = rowCount - 1 - Int(point.y / tileSize)
        return GridPos(col: col, row: row)
    }

    /// マップ全体のワールドサイズ。
    static var worldSize: CGSize {
        CGSize(width: CGFloat(colCount) * tileSize,
               height: CGFloat(rowCount) * tileSize)
    }

    static func tile(col: Int, row: Int) -> TileType {
        guard row >= 0, row < rowCount, col >= 0, col < colCount else { return .wall }
        let line = Array(rows[row])
        return line[col] == "#" ? .wall : .road
    }

    /// 指定ワールド座標が歩けるか（マップ範囲外は壁扱い）。
    static func isWalkable(_ point: CGPoint) -> Bool {
        let g = gridPosition(of: point)
        return tile(col: g.col, row: g.row).isWalkable
    }
}
