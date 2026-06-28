//
//  DuelView.swift
//  古書横丁ものがたり — 戦闘画面（ドラクエ5風）
//
//  背景の上に敵を大きく描き、下にメッセージ窓・ステータス・コマンド窓を並べる。
//  被弾時は敵が赤く点滅して揺れ、自分が食らうと画面が赤く明滅する。
//

import SwiftUI

struct DuelView: View {
    @EnvironmentObject var game: GameState
    let session: DuelSession

    @State private var enemyHit = false
    @State private var playerHit = false

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                enemyStage
                Spacer(minLength: 8)
                bottomPanel
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)

            // 自分の被弾フラッシュ
            Color.red.opacity(playerHit ? 0.28 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onChange(of: session.enemyHP) { old, new in
            if new < old { flashEnemy() }
        }
        .onChange(of: session.playerHP) { old, new in
            if new < old { flashPlayer() }
        }
    }

    // MARK: - 背景

    private var background: some View {
        Group {
            if let bg = TextureFactory.battleBackgroundImage() {
                Image(uiImage: bg)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    colors: [Color(red: 0.12, green: 0.10, blue: 0.18),
                             Color(red: 0.06, green: 0.05, blue: 0.09)],
                    startPoint: .top, endPoint: .bottom)
            }
        }
        .ignoresSafeArea()
        .overlay(Color.black.opacity(0.15).ignoresSafeArea())
    }

    // MARK: - 敵

    private var enemyStage: some View {
        VStack(spacing: 6) {
            Text(session.opponentName)
                .font(RetroTheme.font(14))
                .foregroundColor(RetroTheme.ink)
                .padding(.horizontal, 12).padding(.vertical, 4)
                .background(RetroTheme.windowFill.opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 2)
                    .stroke(RetroTheme.windowBorder.opacity(0.7), lineWidth: 1))

            let img = TextureFactory.battleImage(asset: session.enemyAsset, tint: session.enemyTint)
            let pixelArt = img.size.width <= 64
            Image(uiImage: img)
                .interpolation(pixelArt ? .none : .medium)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 180)
                .colorMultiply(enemyHit ? Color(red: 1, green: 0.5, blue: 0.5) : .white)
                .opacity(session.isFinished && session.didWin == true ? 0.0 : 1)
                .scaleEffect(session.isFinished && session.didWin == true ? 0.7 : 1)
                .offset(x: enemyHit ? -7 : 0)
                .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
                .animation(.easeInOut(duration: 0.12), value: enemyHit)
                .animation(.easeOut(duration: 0.4), value: session.didWin)

            // 敵HPゲージ
            gauge(value: session.enemyHP, max: session.enemyMaxHP,
                  ratio: session.enemyHPRatio, color: RetroTheme.danger)
                .frame(maxWidth: 240)
        }
        .padding(.top, 14)
    }

    // MARK: - 下段（メッセージ・ステータス・コマンド）

    private var bottomPanel: some View {
        VStack(spacing: 8) {
            messageWindow
            statusWindow
            if session.isFinished {
                resultControls
            } else {
                commandWindow
            }
        }
    }

    private var messageWindow: some View {
        RetroWindow {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(session.log.suffix(3)) { line in
                    Text(line.text)
                        .font(RetroTheme.font(11))
                        .foregroundColor(line.isPlayer ? RetroTheme.ink : RetroTheme.ink.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 52, alignment: .top)
        }
    }

    private var statusWindow: some View {
        RetroWindow {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("\(game.player.name) の体力")
                            .font(RetroTheme.font(10)).foregroundColor(RetroTheme.ink)
                        Spacer()
                        Text("\(session.playerHP)/\(session.playerMaxHP)")
                            .font(RetroTheme.font(11)).foregroundColor(RetroTheme.ink)
                    }
                    gauge(value: session.playerHP, max: session.playerMaxHP,
                          ratio: session.playerHPRatio,
                          color: Color(red: 0.45, green: 0.80, blue: 0.50))
                }
                VStack(spacing: 2) {
                    Text("気合").font(RetroTheme.font(9)).foregroundColor(RetroTheme.ink.opacity(0.8))
                    HStack(spacing: 3) {
                        ForEach(0..<session.playerMaxKiai, id: \.self) { i in
                            Circle()
                                .fill(i < session.playerKiai ? RetroTheme.accent : Color.white.opacity(0.15))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
        }
    }

    private var commandWindow: some View {
        RetroWindow {
            VStack(alignment: .leading, spacing: 6) {
                Text("コマンド？")
                    .font(RetroTheme.font(11)).foregroundColor(RetroTheme.ink.opacity(0.7))
                ForEach(BattleCommand.allCases) { command in
                    let disabled = command == .special && !session.canUseSpecial
                    RetroButton(
                        title: command.label,
                        subtitle: command.hint,
                        tint: disabled ? RetroTheme.ink.opacity(0.3) : RetroTheme.accent
                    ) {
                        guard !disabled else { return }
                        game.battle(command: command)
                    }
                    .opacity(disabled ? 0.45 : 1)
                    .disabled(disabled)
                }
            }
        }
    }

    private var resultControls: some View {
        RetroWindow {
            VStack(spacing: 8) {
                Text(session.didWin == true ? "🏆 \(session.opponentName)を撃破した！" : "…目の前が暗くなった")
                    .font(RetroTheme.font(14))
                    .foregroundColor(session.didWin == true ? RetroTheme.accent : RetroTheme.danger)
                    .frame(maxWidth: .infinity)
                RetroButton(title: session.didWin == true ? "勝どきを上げる" : "退却する") {
                    game.finishDuel()
                }
            }
        }
    }

    // MARK: - 共通ゲージ

    private func gauge(value: Int, max: Int, ratio: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.black.opacity(0.4))
                Rectangle().fill(color).frame(width: geo.size.width * ratio)
            }
        }
        .frame(height: 9)
        .overlay(Rectangle().stroke(RetroTheme.windowBorder.opacity(0.6), lineWidth: 1))
    }

    // MARK: - 被弾エフェクト

    private func flashEnemy() {
        enemyHit = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { enemyHit = false }
    }

    private func flashPlayer() {
        withAnimation(.easeIn(duration: 0.06)) { playerHit = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.easeOut(duration: 0.2)) { playerHit = false }
        }
    }
}
