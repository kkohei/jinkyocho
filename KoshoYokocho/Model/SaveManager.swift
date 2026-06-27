//
//  SaveManager.swift
//  古書横丁ものがたり — セーブ/ロード（JSON）
//
//  セーブは喫茶店で珈琲を飲む＝休息のタイミングで行う。
//  Documents/ 配下に JSON で書き出し、再起動時に復元する。
//

import Foundation

enum SaveManager {
    static let fileName = "savegame.json"

    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(fileName)
    }

    static var hasSave: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// 永続スナップショットを書き出す。
    static func save(_ snapshot: SaveSnapshot) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(snapshot)
            try data.write(to: fileURL, options: .atomic)
            #if DEBUG
            print("[SaveManager] saved -> \(fileURL.path)")
            #endif
        } catch {
            print("[SaveManager] save failed: \(error)")
        }
    }

    /// セーブが存在すれば読み込む。
    static func load() -> SaveSnapshot? {
        guard hasSave else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(SaveSnapshot.self, from: data)
        } catch {
            print("[SaveManager] load failed: \(error)")
            return nil
        }
    }

    static func deleteSave() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

/// JSON に書き出す永続データだけを束ねた Codable スナップショット。
/// 一時的なUI状態（会話/対決/入力）は含めない。
struct SaveSnapshot: Codable {
    var version: Int
    var player: PlayerData
    var shops: [Shop]
    var books: [BookEntry]
    var flags: [String: Bool]
    var townLevel: Int
    var savedAt: Date
}
