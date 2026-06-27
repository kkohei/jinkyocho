//
//  YokochoScene.swift
//  古書横丁ものがたり — 歩ける横丁シーン
//
//  タイルマップ生成・当たり判定・カメラ追従・歩行を担当する SKScene。
//  入力（仮想スティック）と「調べる」は GameState 経由で SwiftUI と連携する。
//

import Foundation
import SpriteKit

final class YokochoScene: SKScene {

    /// 単一の真実。SwiftUI 側と共有する。
    unowned let game: GameState

    private let player = PlayerNode()
    private let cameraNode = SKCameraNode()

    /// placement id → 表示ノード（拾得・再生で差し替え/削除する）。
    private var placementNodes: [String: SKNode] = [:]

    private var lastUpdateTime: TimeInterval = 0
    private let moveSpeed: CGFloat = 96   // pt/秒

    /// 調べられる距離（タイル換算）。
    private var interactRange: CGFloat { YokochoMap.tileSize * 1.3 }

    init(game: GameState, size: CGSize) {
        self.game = game
        super.init(size: size)
        self.scaleMode = .resizeFill
        self.backgroundColor = UIColor(red: 0.10, green: 0.09, blue: 0.12, alpha: 1)
        self.anchorPoint = CGPoint(x: 0, y: 0)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - セットアップ

    override func didMove(to view: SKView) {
        game.scene = self
        buildTileMap()
        buildPlacements()
        setupPlayer()
        setupCamera()
    }

    private func buildTileMap() {
        let road = TextureFactory.roadTile()
        let wall = TextureFactory.wallTile()
        for row in 0..<YokochoMap.rowCount {
            for col in 0..<YokochoMap.colCount {
                let type = YokochoMap.tile(col: col, row: row)
                let tex = type == .wall ? wall : road
                let node = SKSpriteNode(texture: tex,
                                        size: CGSize(width: YokochoMap.tileSize,
                                                     height: YokochoMap.tileSize))
                node.position = YokochoMap.worldPosition(of: GridPos(col: col, row: row))
                node.zPosition = (type == .wall) ? 10 : 0
                addChild(node)
            }
        }
    }

    private func buildPlacements() {
        for placement in YokochoMap.placements {
            let node = makeNode(for: placement)
            node.position = YokochoMap.worldPosition(of: placement.pos)
            node.zPosition = 20
            addChild(node)
            placementNodes[placement.id] = node

            // 拾得済みの古本は最初から出さない。
            if case .pickup(let bookID) = placement.kind,
               game.books.first(where: { $0.id == bookID })?.isCollected == true {
                node.isHidden = true
            }
        }
    }

    private func makeNode(for placement: Placement) -> SKNode {
        let texture: SKTexture
        switch placement.kind {
        case .shop(let id):
            texture = shopTexture(for: id)
        case .npc:
            texture = TextureFactory.catNPC()
        case .pickup:
            texture = TextureFactory.bookPickup()
        }
        let node = SKSpriteNode(texture: texture,
                                size: CGSize(width: YokochoMap.tileSize,
                                             height: YokochoMap.tileSize))
        // 拾得物はふわっと上下に揺らして目立たせる。
        if case .pickup = placement.kind {
            let up = SKAction.moveBy(x: 0, y: 3, duration: 0.6)
            up.timingMode = .easeInEaseOut
            node.run(.repeatForever(.sequence([up, up.reversed()])))
        }
        return node
    }

    private func shopTexture(for shopID: String) -> SKTexture {
        guard let shop = game.shops.first(where: { $0.id == shopID }) else {
            return TextureFactory.shopDoor(color: .gray)
        }
        switch shop.kind {
        case .bookCafe:
            return TextureFactory.shopDoor(color: UIColor(red: 0.45, green: 0.30, blue: 0.55, alpha: 1))
        case .curry:
            return TextureFactory.shopDoor(color: UIColor(red: 0.85, green: 0.55, blue: 0.20, alpha: 1))
        case .vacant:
            return shop.isRestored
                ? TextureFactory.shopDoor(color: UIColor(red: 0.90, green: 0.55, blue: 0.65, alpha: 1))
                : TextureFactory.vacantDoor()
        }
    }

    private func setupPlayer() {
        player.position = game.player.position
        player.update(facing: game.player.facing, moving: false)
        addChild(player)
    }

    private func setupCamera() {
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = player.position
    }

    // MARK: - メインループ

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        guard dt > 0 else { return }

        game.tick(dt)

        // 会話・対決中は移動を止める。
        let inputLocked = game.activeDialogue != nil || game.activeDuel != nil
        let vector = inputLocked ? .zero : game.moveVector

        movePlayer(vector: vector, dt: dt)
        updateCamera()
        updateInteractPrompt()
    }

    private func movePlayer(vector: CGVector, dt: TimeInterval) {
        let magnitude = hypot(vector.dx, vector.dy)
        let moving = magnitude > 0.12

        if moving {
            // 正規化して速度を適用。
            let nx = vector.dx / magnitude
            let ny = vector.dy / magnitude
            let dx = nx * moveSpeed * CGFloat(dt)
            let dy = ny * moveSpeed * CGFloat(dt)

            var pos = player.position
            // 軸ごとに当たり判定（壁ずりできるように）。
            let tryX = CGPoint(x: pos.x + dx, y: pos.y)
            if canStand(at: tryX) { pos.x = tryX.x }
            let tryY = CGPoint(x: pos.x, y: pos.y + dy)
            if canStand(at: tryY) { pos.y = tryY.y }
            player.position = pos

            // 向きは支配的な軸で決める。
            let facing: Facing
            if abs(nx) > abs(ny) {
                facing = nx >= 0 ? .right : .left
            } else {
                facing = ny >= 0 ? .up : .down
            }
            game.player.facing = facing
            game.player.position = pos
            player.update(facing: facing, moving: true)
        } else {
            player.update(facing: game.player.facing, moving: false)
        }
    }

    /// プレイヤーの当たり判定ボックスがすべて道なら立てる。
    private func canStand(at point: CGPoint) -> Bool {
        let r = player.collisionRadius
        let corners = [
            CGPoint(x: point.x - r, y: point.y - r),
            CGPoint(x: point.x + r, y: point.y - r),
            CGPoint(x: point.x - r, y: point.y + r),
            CGPoint(x: point.x + r, y: point.y + r),
        ]
        return corners.allSatisfy { YokochoMap.isWalkable($0) }
    }

    private func updateCamera() {
        guard let view = view else { return }
        // 表示範囲の半分。scaleMode=.resizeFill なので scene.size がそのまま見える範囲。
        let halfW = size.width / 2
        let halfH = size.height / 2
        let world = YokochoMap.worldSize

        var x = player.position.x
        var y = player.position.y
        // マップ端でカメラを止める（マップが画面より小さい場合は中央寄せ）。
        if world.width >= size.width {
            x = min(max(x, halfW), world.width - halfW)
        } else {
            x = world.width / 2
        }
        if world.height >= size.height {
            y = min(max(y, halfH), world.height - halfH)
        } else {
            y = world.height / 2
        }
        cameraNode.position = CGPoint(x: x, y: y)
    }

    // MARK: - 調べる

    /// HUD から呼ばれる。最寄りの調べ対象を探して反応する。
    func investigateNearest() {
        guard game.activeDialogue == nil, game.activeDuel == nil else { return }
        guard let placement = nearestPlacement(within: interactRange) else {
            game.showToast("…ここには何もない")
            return
        }
        // 対象の方を向く。
        faceTowards(YokochoMap.worldPosition(of: placement.pos))
        game.handle(placement: placement)
    }

    /// 近接プロンプト（「調べる」ガイド）を更新する。
    private func updateInteractPrompt() {
        guard game.activeDialogue == nil, game.activeDuel == nil else {
            if game.interactPrompt != nil { game.interactPrompt = nil }
            return
        }
        if let placement = nearestPlacement(within: interactRange) {
            let label = promptLabel(for: placement)
            if game.interactPrompt != label { game.interactPrompt = label }
        } else if game.interactPrompt != nil {
            game.interactPrompt = nil
        }
    }

    private func nearestPlacement(within range: CGFloat) -> Placement? {
        var best: Placement?
        var bestDist = CGFloat.greatestFiniteMagnitude
        for placement in YokochoMap.placements {
            // 拾得済みは無視。
            if case .pickup(let bookID) = placement.kind,
               game.books.first(where: { $0.id == bookID })?.isCollected == true {
                continue
            }
            let p = YokochoMap.worldPosition(of: placement.pos)
            let d = hypot(p.x - player.position.x, p.y - player.position.y)
            if d <= range, d < bestDist {
                bestDist = d
                best = placement
            }
        }
        return best
    }

    private func promptLabel(for placement: Placement) -> String {
        switch placement.kind {
        case .shop(let id):
            let name = game.shops.first(where: { $0.id == id })?.currentName ?? "店"
            return "調べる：\(name)"
        case .npc:
            return "調べる：看板猫"
        case .pickup:
            return "調べる：落ちている古本"
        }
    }

    private func faceTowards(_ target: CGPoint) {
        let dx = target.x - player.position.x
        let dy = target.y - player.position.y
        let facing: Facing
        if abs(dx) > abs(dy) {
            facing = dx >= 0 ? .right : .left
        } else {
            facing = dy >= 0 ? .up : .down
        }
        game.player.facing = facing
        player.update(facing: facing, moving: false)
    }

    // MARK: - GameState からの通知で見た目を更新

    /// 図鑑登録された古本ノードを消す。
    func removePickupNode(bookID: String) {
        for placement in YokochoMap.placements {
            if case .pickup(let id) = placement.kind, id == bookID {
                placementNodes[placement.id]?.run(.sequence([
                    .group([.fadeOut(withDuration: 0.25), .scale(to: 1.4, duration: 0.25)]),
                    .removeFromParent(),
                ]))
            }
        }
    }

    /// 店ノード（再生後の空き店舗など）のテクスチャを貼り替える。
    func refreshShopNode(shopID: String) {
        guard let node = placementNodes[shopID] as? SKSpriteNode else { return }
        node.texture = shopTexture(for: shopID)
        node.run(.sequence([.scale(to: 1.3, duration: 0.15), .scale(to: 1.0, duration: 0.15)]))
    }
}
