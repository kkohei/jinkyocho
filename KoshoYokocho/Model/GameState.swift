//
//  GameState.swift
//  古書横丁ものがたり — 単一の真実（single source of truth）
//
//  永続データ（プレイヤー/店舗/図鑑/フラグ）と、一時的なUI状態
//  （会話/対決/入力ベクトル/トースト）を1つの ObservableObject に集約する。
//  永続化は SaveSnapshot 経由で JSON へ。
//

import Combine
import CoreGraphics
import SwiftUI

final class GameState: ObservableObject {

    // MARK: - 永続データ

    @Published var player: PlayerData
    @Published var shops: [Shop]
    @Published var books: [BookEntry]
    @Published var flags: [String: Bool]
    @Published var townLevel: Int
    /// 最後にセーブした時刻（HUD/タイトル表示用）。
    @Published var lastSaved: Date?

    // MARK: - 一時的なUI状態（セーブ対象外）

    /// 仮想スティックの入力ベクトル（-1...1）。シーンが update で読む。
    @Published var moveVector: CGVector = .zero
    /// 表示中の会話（nil で非表示）。
    @Published var activeDialogue: DialogueContent?
    /// 進行中の対決（nil で非表示）。
    @Published var activeDuel: DuelSession?
    /// 「調べる」可能なときに出すプロンプト。
    @Published var interactPrompt: String?
    /// 画面に一瞬出すトースト通知。
    @Published var toast: String?

    /// 現在シーンが認識している、もっとも近い調べ対象。
    var focusedPlacement: Placement?

    /// シーンとの橋渡し（弱参照）。
    weak var scene: YokochoScene?

    private let saveVersion = 1

    // MARK: - 生成

    init(player: PlayerData, shops: [Shop], books: [BookEntry],
         flags: [String: Bool], townLevel: Int, lastSaved: Date?) {
        self.player = player
        self.shops = shops
        self.books = books
        self.flags = flags
        self.townLevel = townLevel
        self.lastSaved = lastSaved
    }

    /// 起動時：セーブがあれば復元、無ければ新規ゲーム。
    static func bootstrap() -> GameState {
        if let snap = SaveManager.load() {
            return GameState(
                player: snap.player,
                shops: snap.shops,
                books: snap.books,
                flags: snap.flags,
                townLevel: snap.townLevel,
                lastSaved: snap.savedAt
            )
        }
        return newGame()
    }

    static func newGame() -> GameState {
        let spawn = YokochoMap.worldPosition(of: YokochoMap.spawn)
        return GameState(
            player: .newGame(spawn: spawn),
            shops: GameContent.initialShops(),
            books: GameContent.allBooks(),
            flags: [:],
            townLevel: 1,
            lastSaved: nil
        )
    }

    // MARK: - セーブ

    /// 喫茶店で休息＝セーブ。
    func saveGame() {
        let snap = SaveSnapshot(
            version: saveVersion,
            player: player,
            shops: shops,
            books: books,
            flags: flags,
            townLevel: townLevel,
            savedAt: Date()
        )
        SaveManager.save(snap)
        lastSaved = snap.savedAt
        showToast("☕ 珈琲で一服…記録した")
    }

    func resetAndNewGame() {
        SaveManager.deleteSave()
        let fresh = GameState.newGame()
        player = fresh.player
        shops = fresh.shops
        books = fresh.books
        flags = fresh.flags
        townLevel = fresh.townLevel
        lastSaved = nil
    }

    // MARK: - 毎フレーム更新（シーンから dt 付きで呼ばれる）

    func tick(_ dt: TimeInterval) {
        // 探索バフの自然減衰。
        if var buff = player.buff {
            buff.remaining -= dt
            if buff.remaining <= 0 {
                player.buff = nil
                showToast("バフ「\(buff.name)」が切れた")
            } else {
                player.buff = buff
            }
        }
    }

    // MARK: - 調べる

    /// HUDの「調べる」ボタン → シーンに最寄りの対象を問い合わせる。
    func investigate() {
        scene?.investigateNearest()
    }

    /// シーンから渡された調べ対象を処理して、会話やアクションを起こす。
    func handle(placement: Placement) {
        // 会話に入る瞬間に移動入力を止める（スティックを握ったままでもドリフトしない）。
        moveVector = .zero
        switch placement.kind {
        case .shop(let id):
            presentShopDialogue(shopID: id)
        case .npc(let id):
            presentNPCDialogue(npcID: id)
        case .pickup(let bookID):
            presentPickupDialogue(bookID: bookID)
        }
    }

    // MARK: - 会話の構築

    private func presentShopDialogue(shopID: String) {
        guard let shop = shops.first(where: { $0.id == shopID }) else { return }
        switch shop.kind {
        case .bookCafe:
            activeDialogue = DialogueContent(
                speaker: shop.currentName,
                lines: ["わが店「\(shop.currentName)」。",
                        "珈琲を一杯どうだい？　飲めば一息ついて、記録（セーブ）もできる。"],
                choices: [
                    DialogueChoice(label: "珈琲を飲む（休息＝セーブ）", action: .saveGame),
                    DialogueChoice(label: "やめておく", action: .dismiss),
                ]
            )
        case .curry:
            activeDialogue = DialogueContent(
                speaker: shop.currentName,
                lines: ["「\(shop.currentName)」の暖簾だ。香ばしいスパイスの匂い。",
                        "主人がこちらを見て不敵に笑った。「一品、勝負といくかい？」"],
                choices: [
                    DialogueChoice(label: "グルメ対決を挑む", action: .startGourmetDuel(shop.id)),
                    DialogueChoice(label: "スペシャルカレーを食べる（バフ）", action: .eat(dish: "莫迦楼スペシャルカレー")),
                    DialogueChoice(label: "立ち去る", action: .dismiss),
                ]
            )
        case .vacant:
            if shop.isRestored {
                activeDialogue = DialogueContent(
                    speaker: shop.currentName,
                    lines: ["再生された「\(shop.currentName)」。",
                            "通りにまた灯りがひとつ増えた。"],
                    choices: [DialogueChoice(label: "とじる", action: .dismiss)]
                )
            } else {
                activeDialogue = DialogueContent(
                    speaker: "空き店舗",
                    lines: ["シャッターの下りた空き店舗。埃の匂いがする。",
                            shop.restoreHint ?? "何か条件を満たせば、再生できそうだ。"],
                    choices: [DialogueChoice(label: "とじる", action: .dismiss)]
                )
            }
        }
    }

    private func presentNPCDialogue(npcID: String) {
        switch npcID {
        case "npc_cat":
            activeDialogue = DialogueContent(
                speaker: "看板猫 とら",
                lines: ["「にゃあ。……いや、しゃべれるとも。」",
                        "「この横丁はね、空き店舗を再生するたびに賑わっていくのさ。」",
                        "「まずは莫迦楼のカレー勝負に勝ってごらん。甘味処が戻るはずだよ。」"],
                choices: [DialogueChoice(label: "とじる", action: .dismiss)]
            )
        default:
            activeDialogue = DialogueContent(
                speaker: nil,
                lines: ["……誰もいないようだ。"],
                choices: [DialogueChoice(label: "とじる", action: .dismiss)]
            )
        }
    }

    private func presentPickupDialogue(bookID: String) {
        guard let book = books.first(where: { $0.id == bookID }) else { return }
        if book.isCollected {
            activeDialogue = DialogueContent(
                speaker: nil,
                lines: ["足元を探したが、もう何も残っていない。"],
                choices: [DialogueChoice(label: "とじる", action: .dismiss)]
            )
            return
        }
        activeDialogue = DialogueContent(
            speaker: nil,
            lines: ["落ちている古本を見つけた。",
                    "『\(book.title)』（\(book.author)／\(book.era)）"],
            choices: [
                DialogueChoice(label: "拾って図鑑に登録する", action: .collectBook(book.id)),
                DialogueChoice(label: "そのままにする", action: .dismiss),
            ]
        )
    }

    // MARK: - 選択肢アクションの実行

    func perform(_ action: DialogueAction) {
        switch action {
        case .dismiss:
            activeDialogue = nil
        case .enterShop(let id):
            activeDialogue = nil
            presentShopDialogue(shopID: id)
        case .startGourmetDuel(let opponentID):
            activeDialogue = nil
            startGourmetDuel(opponentID: opponentID)
        case .eat(let dish):
            activeDialogue = nil
            eat(dish: dish)
        case .collectBook(let id):
            activeDialogue = nil
            collectBook(id: id)
        case .saveGame:
            activeDialogue = nil
            saveGame()
        case .custom(let block):
            block()
        }
    }

    // MARK: - 食べてバフ

    func eat(dish: String) {
        let buff = GameContent.curryBuff()
        player.buff = buff
        showToast("🍛 \(dish)を食べた！ 目利き+\(buff.mekikiBonus) 食通+\(buff.shokutsuBonus)")
    }

    // MARK: - 図鑑登録

    func collectBook(id: String) {
        guard let idx = books.firstIndex(where: { $0.id == id }) else { return }
        guard !books[idx].isCollected else { return }
        books[idx].isCollected = true
        let collected = books.filter { $0.isCollected }.count
        showToast("📚『\(books[idx].title)』を図鑑に登録（\(collected)/\(books.count)）")
        scene?.removePickupNode(bookID: id)
    }

    var collectedBookCount: Int { books.filter { $0.isCollected }.count }

    // MARK: - 対決（グルメ＝ドラクエ風 HP バトル）

    func startGourmetDuel(opponentID: String) {
        let opponent = shops.first(where: { $0.id == opponentID })
        var session = DuelSession(
            kind: .gourmet,
            opponentName: opponent?.currentName ?? "謎の料理人",
            title: "グルメ対決！",
            playerHP: 30, playerMaxHP: 30,
            enemyHP: 36, enemyMaxHP: 36,
            playerKiai: 3, playerMaxKiai: 6
        )
        session.log.append(DuelLogLine(
            text: "「料理で勝負だ！ 互いの“自信”を削りあって、先に音を上げた方が負けだぜ。」",
            isPlayer: false))
        activeDuel = session
    }

    /// プレイヤーのコマンドを処理 → 相手の反撃 → 決着判定まで1ターン進める。
    func battle(command: BattleCommand) {
        guard var s = activeDuel, !s.isFinished else { return }
        let eff = player.stats.applying(player.buff)
        let atk = 6 + eff.shokutsu * 2   // 食通でダメージが伸びる（カレーのバフが効く）

        s.playerDefending = false

        // --- プレイヤーの手 ---
        switch command {
        case .attack:
            let dmg = max(1, atk + Int.random(in: -2...2))
            s.enemyHP = max(0, s.enemyHP - dmg)
            s.log.append(DuelLogLine(text: "あなたの自慢の一皿！ 相手の自信を \(dmg) けずった！", isPlayer: true))

        case .special:
            guard s.playerKiai >= BattleCommand.specialCost else {
                // ボタンは無効化しているので通常ここには来ない。来ても安全に無視。
                s.log.append(DuelLogLine(text: "気合が足りない！", isPlayer: true))
                activeDuel = s
                return
            }
            s.playerKiai -= BattleCommand.specialCost
            let dmg = max(1, Int(Double(atk) * 1.8) + eff.shokutsu + Int.random(in: -2...3))
            s.enemyHP = max(0, s.enemyHP - dmg)
            s.log.append(DuelLogLine(text: "とっておきの逸品を投入！ 自信を \(dmg) も削った！", isPlayer: true))

        case .defend:
            s.playerDefending = true
            s.playerKiai = min(s.playerMaxKiai, s.playerKiai + 3)
            s.log.append(DuelLogLine(text: "味をととのえ、隙をうかがう（気合+3）", isPlayer: true))
        }

        // --- 勝利判定（相手の自信 0）---
        if s.enemyHP <= 0 {
            s.isFinished = true
            s.didWin = true
            s.log.append(DuelLogLine(text: "相手が天を仰いだ…「参った、あんたの勝ちだ！」", isPlayer: true))
            activeDuel = s
            return
        }

        // --- 相手の反撃（簡易AI）---
        enemyTurn(&s)

        // 気合の自然回復。
        s.playerKiai = min(s.playerMaxKiai, s.playerKiai + 1)

        // --- 敗北判定（自分の自信 0）---
        if s.playerHP <= 0 {
            s.isFinished = true
            s.didWin = false
            s.log.append(DuelLogLine(text: "自信を失ってしまった…「次は負けないぞ」", isPlayer: false))
        } else {
            s.turn += 1
        }

        activeDuel = s
    }

    /// 相手1手。たまに大技を出す。
    private func enemyTurn(_ s: inout DuelSession) {
        var dmg: Int
        if Int.random(in: 0...9) < 2 {
            dmg = Int.random(in: 10...14)
            s.log.append(DuelLogLine(text: "相手の渾身の大皿が炸裂！", isPlayer: false))
        } else {
            dmg = Int.random(in: 5...9)
            s.log.append(DuelLogLine(text: "相手が一皿くり出した", isPlayer: false))
        }
        if s.playerDefending {
            dmg = max(1, dmg / 2)
            s.log.append(DuelLogLine(text: "ととのえた構えで半減！", isPlayer: true))
        }
        s.playerHP = max(0, s.playerHP - dmg)
        s.log.append(DuelLogLine(text: "あなたの自信を \(dmg) けずられた…", isPlayer: false))
    }

    /// 対決ウィンドウを閉じる。勝利していれば報酬処理。
    func finishDuel() {
        guard let session = activeDuel else { return }
        if session.isFinished, session.didWin == true {
            grantGourmetVictoryRewards()
        }
        activeDuel = nil
    }

    private func grantGourmetVictoryRewards() {
        // 食通を1上げる。
        player.stats.shokutsu += 1
        flags["won_curry_duel"] = true
        // 空き店舗の再生条件達成 → 再生。
        restoreShopIfPossible()
        showToast("🏆 勝利！ 食通+1")
    }

    // MARK: - 発展（空き店舗の再生）

    /// 条件を満たした空き店舗を再生し、街レベルを上げる。
    func restoreShopIfPossible() {
        guard let idx = shops.firstIndex(where: { $0.id == "shop_vacant" }) else { return }
        guard !shops[idx].isRestored else { return }
        // v0 の再生条件：カレー屋のグルメ対決に勝つ。
        guard flags["won_curry_duel"] == true else { return }
        shops[idx].isRestored = true
        townLevel += 1
        let name = shops[idx].currentName
        showToast("🏮 空き店舗が再生！「\(name)」開店／街レベル \(townLevel)")
        scene?.refreshShopNode(shopID: "shop_vacant")
    }

    // MARK: - トースト

    func showToast(_ text: String) {
        toast = text
        // 自動で消す。
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { [weak self] in
            if self?.toast == text { self?.toast = nil }
        }
    }
}
