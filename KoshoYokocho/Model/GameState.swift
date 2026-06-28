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
    /// 街の復興度（旧 townLevel）。店を取り戻すと上がる。
    @Published var townLevel: Int
    /// 撃破したゾンビの数。
    @Published var zombiesDefeated: Int
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
         flags: [String: Bool], townLevel: Int, zombiesDefeated: Int, lastSaved: Date?) {
        self.player = player
        self.shops = shops
        self.books = books
        self.flags = flags
        self.townLevel = townLevel
        self.zombiesDefeated = zombiesDefeated
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
                zombiesDefeated: snap.zombiesDefeated,
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
            zombiesDefeated: 0,
            lastSaved: nil
        )
    }

    // MARK: - セーブ

    /// 喫茶店で休息＝体力全回復＋セーブ。
    func saveGame() {
        player.hp = player.maxHP
        let snap = SaveSnapshot(
            version: saveVersion,
            player: player,
            shops: shops,
            books: books,
            flags: flags,
            townLevel: townLevel,
            zombiesDefeated: zombiesDefeated,
            savedAt: Date()
        )
        SaveManager.save(snap)
        lastSaved = snap.savedAt
        showToast("☕ 珈琲で一服…体力回復＆記録した")
    }

    func resetAndNewGame() {
        SaveManager.deleteSave()
        let fresh = GameState.newGame()
        player = fresh.player
        shops = fresh.shops
        books = fresh.books
        flags = fresh.flags
        townLevel = fresh.townLevel
        zombiesDefeated = fresh.zombiesDefeated
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
        case .enemy:
            startBattle(placement: placement)
        }
    }

    // MARK: - 会話の構築

    private func presentShopDialogue(shopID: String) {
        guard let shop = shops.first(where: { $0.id == shopID }) else { return }
        switch shop.kind {
        case .bookCafe:
            activeDialogue = DialogueContent(
                speaker: shop.currentName,
                lines: ["わが店「\(shop.currentName)」。亡者を締め出した、つかの間の安全地帯だ。",
                        "珈琲を一杯どうだい？　飲めば体力が戻り、記録（セーブ）もできる。"],
                choices: [
                    DialogueChoice(label: "珈琲を飲む（休息＝全回復＆セーブ）", action: .saveGame),
                    DialogueChoice(label: "やめておく", action: .dismiss),
                ]
            )
        case .curry:
            activeDialogue = DialogueContent(
                speaker: shop.currentName,
                lines: ["「\(shop.currentName)」——こんな世でも鍋を守る、生き残りの主人だ。",
                        "「亡者と渡り合うにゃあ、まず腹ごしらえよ。食っていきな。」"],
                choices: [
                    DialogueChoice(label: "特製カレーを食べる（体力回復＋力がみなぎる）", action: .eat(dish: "莫迦楼スペシャルカレー")),
                    DialogueChoice(label: "立ち去る", action: .dismiss),
                ]
            )
        case .vacant:
            if shop.isRestored {
                activeDialogue = DialogueContent(
                    speaker: shop.currentName,
                    lines: ["亡者を祓って取り戻した「\(shop.currentName)」。",
                            "通りにまた灯りがひとつ戻った。"],
                    choices: [DialogueChoice(label: "とじる", action: .dismiss)]
                )
            } else {
                activeDialogue = DialogueContent(
                    speaker: "占拠された店",
                    lines: ["亡者に占拠され、本が食い荒らされた店。淀んだ気配がする。",
                            shop.restoreHint ?? "守りの亡者を祓えば、取り戻せそうだ。"],
                    choices: [DialogueChoice(label: "とじる", action: .dismiss)]
                )
            }
        }
    }

    private func presentNPCDialogue(npcID: String) {
        switch npcID {
        case "npc_cat":
            let cleared = zombiesDefeated
            activeDialogue = DialogueContent(
                speaker: "看板猫 とら",
                lines: ["「にゃあ。……生きてたのかい、あんた。」",
                        "「ある日、呪われた稀覯本から“亡者（古書ゾンビ）”が湧いてね。この古書街は喰い荒らされたのさ。」",
                        "「亡者を祓い、占拠された店を取り戻すんだ。店の前を守る大物を倒せば、その店は復興する。」",
                        "「いまの撃破数は \(cleared) 体。無理だと思ったら喫茶店で珈琲を——体力が戻るよ。」"],
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
            lines: ["瓦礫の中に、無事だった稀覯本を見つけた。",
                    "『\(book.title)』（\(book.author)／\(book.era)）"],
            choices: [
                DialogueChoice(label: "救出して図鑑に登録する", action: .collectBook(book.id)),
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

    // MARK: - 食べて回復＋バフ

    func eat(dish: String) {
        let buff = GameContent.curryBuff()
        player.buff = buff
        // 腹ごしらえで体力も半分ほど回復。
        let heal = max(1, player.maxHP / 2)
        player.hp = min(player.maxHP, player.hp + heal)
        showToast("🍛 \(dish)を食べた！ 体力+\(heal)・力がみなぎる（食通+\(buff.shokutsuBonus)）")
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

    // MARK: - 戦闘（ゾンビとの HP バトル）

    /// すでにこのゾンビと決着済みか（撃破して消えている）。
    func isEnemyCleared(_ placementID: String) -> Bool {
        flags["cleared_\(placementID)"] == true
    }

    /// フィールドのゾンビと戦闘を開始する（接触 or 調べる）。
    func startBattle(placement: Placement) {
        guard activeDuel == nil, activeDialogue == nil else { return }
        guard case .enemy(let typeID) = placement.kind else { return }
        guard !isEnemyCleared(placement.id) else { return }
        moveVector = .zero

        let enemy = EnemyCatalog.type(typeID)
        var session = DuelSession.versus(
            enemy: enemy,
            placementID: placement.id,
            playerHP: player.hp, playerMaxHP: player.maxHP,
            playerKiai: 3, playerMaxKiai: 6
        )
        session.log.append(DuelLogLine(
            text: "\(enemy.name) が立ちはだかった！ うめき声をあげている…",
            isPlayer: false))
        activeDuel = session
    }

    /// プレイヤーのコマンドを処理 → 敵の反撃 → 決着判定まで1ターン進める。
    func battle(command: BattleCommand) {
        guard var s = activeDuel, !s.isFinished else { return }
        let eff = player.stats.applying(player.buff)
        let atk = 6 + eff.shokutsu * 2   // 食通でダメージが伸びる（腹ごしらえのバフが効く）

        s.playerDefending = false

        // --- プレイヤーの手 ---
        switch command {
        case .attack:
            let dmg = max(1, atk + Int.random(in: -2...2))
            s.enemyHP = max(0, s.enemyHP - dmg)
            s.log.append(DuelLogLine(text: "渾身の一撃！ \(s.opponentName)に \(dmg) のダメージ！", isPlayer: true))

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
            s.log.append(DuelLogLine(text: "とっておきの一撃！ \(dmg) の大ダメージ！", isPlayer: true))

        case .defend:
            s.playerDefending = true
            s.playerKiai = min(s.playerMaxKiai, s.playerKiai + 3)
            s.log.append(DuelLogLine(text: "身がまえて隙をうかがう（気合+3）", isPlayer: true))
        }

        // --- 勝利判定（敵の体力 0）---
        if s.enemyHP <= 0 {
            s.isFinished = true
            s.didWin = true
            s.log.append(DuelLogLine(text: "\(s.opponentName)は塵となって崩れ落ちた！", isPlayer: true))
            player.hp = s.playerHP
            activeDuel = s
            return
        }

        // --- 敵の反撃（簡易AI）---
        enemyTurn(&s)

        // 気合の自然回復。
        s.playerKiai = min(s.playerMaxKiai, s.playerKiai + 1)

        // --- 敗北判定（自分の体力 0）---
        if s.playerHP <= 0 {
            s.isFinished = true
            s.didWin = false
            s.log.append(DuelLogLine(text: "目の前が暗くなった…", isPlayer: false))
        } else {
            s.turn += 1
        }

        player.hp = s.playerHP
        activeDuel = s
    }

    /// 敵1手。たまに大技を出す（敵パラメータに従う）。
    private func enemyTurn(_ s: inout DuelSession) {
        var dmg: Int
        if Int.random(in: 0...9) < s.enemyBigChance {
            dmg = Int.random(in: s.enemyBigLow...s.enemyBigHigh)
            s.log.append(DuelLogLine(text: "\(s.opponentName)が大きく襲いかかる！", isPlayer: false))
        } else {
            dmg = Int.random(in: s.enemyAtkLow...s.enemyAtkHigh)
            s.log.append(DuelLogLine(text: "\(s.opponentName)の攻撃！", isPlayer: false))
        }
        if s.playerDefending {
            dmg = max(1, dmg / 2)
            s.log.append(DuelLogLine(text: "身がまえていた！ ダメージ半減！", isPlayer: true))
        }
        s.playerHP = max(0, s.playerHP - dmg)
        s.log.append(DuelLogLine(text: "あなたは \(dmg) のダメージを受けた…", isPlayer: false))
    }

    /// 戦闘ウィンドウを閉じる。勝敗に応じて後処理。
    func finishDuel() {
        guard let session = activeDuel else { return }
        if session.isFinished {
            if session.didWin == true {
                grantBattleVictory(session)
            } else {
                handleDefeat()
            }
        }
        activeDuel = nil
    }

    private func grantBattleVictory(_ session: DuelSession) {
        let placementID = session.enemyPlacementID
        flags["cleared_\(placementID)"] = true
        zombiesDefeated += 1
        player.stats.shokutsu += session.enemyRewardShokutsu
        scene?.removeEnemyNode(placementID: placementID)

        var msg = "🗡 \(session.opponentName)を撃破！（撃破数 \(zombiesDefeated)）"
        if session.enemyRewardShokutsu > 0 { msg += " 食通+\(session.enemyRewardShokutsu)" }
        showToast(msg)

        // 店を守るボスを倒したら、その店を復興する。
        restoreShopIfPossible()
    }

    /// 体力 0 で敗北。喫茶店（安全地帯）へ戻し、半分回復して立て直す。
    private func handleDefeat() {
        let safe = YokochoMap.worldPosition(of: GridPos(col: 2, row: 6)) // 古書喫茶の前
        player.position = safe
        player.facing = .down
        player.hp = max(1, player.maxHP / 2)
        scene?.warpPlayer(to: safe)
        showToast("💤 力尽きた…気づけば喫茶店の前にいた（体力半分回復）")
    }

    // MARK: - 発展（占拠店の復興）

    /// 店を守るボスゾンビを倒していれば、その店を復興し復興度を上げる。
    func restoreShopIfPossible() {
        guard let idx = shops.firstIndex(where: { $0.id == "shop_vacant" }) else { return }
        guard !shops[idx].isRestored else { return }
        // 復興条件：占拠店の前を守るボス（zombie_guard）を撃破していること。
        guard isEnemyCleared("zombie_guard") else { return }
        shops[idx].isRestored = true
        townLevel += 1
        let name = shops[idx].currentName
        showToast("🏮 店を取り戻した！「\(name)」復活／復興度 \(townLevel)")
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
