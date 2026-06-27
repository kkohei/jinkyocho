//
//  Dialogue.swift
//  古書横丁ものがたり — 会話・選択肢モデル
//

import Foundation

/// 会話ウィンドウに表示する1件の内容。
struct DialogueContent: Identifiable, Equatable {
    let id = UUID()
    /// 話者名（看板猫・店主など）。nil なら地の文。
    var speaker: String?
    var lines: [String]
    /// 選択肢（空なら「とじる」のみ）。
    var choices: [DialogueChoice]

    static func == (lhs: DialogueContent, rhs: DialogueContent) -> Bool {
        lhs.id == rhs.id
    }
}

/// 会話の選択肢。`action` はタップ時に GameState で実行される。
struct DialogueChoice: Identifiable {
    let id = UUID()
    let label: String
    let action: DialogueAction
}

/// 選択肢が引き起こす振る舞い。
enum DialogueAction {
    case dismiss                 // 閉じるだけ
    case enterShop(String)       // 店に入る（shop id）
    case startGourmetDuel(String)// グルメ対決を開始（相手店 id）
    case eat(dish: String)       // 食べてバフ
    case collectBook(String)     // 古本を図鑑登録（book id）
    case saveGame                // 珈琲＝セーブ
    case custom(() -> Void)      // その他
}
