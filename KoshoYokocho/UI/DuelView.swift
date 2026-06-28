//
//  DuelView.swift
//  古書横丁ものがたり — グルメ対決ウィンドウ（ドラクエ風 HP バトル）
//
//  互いの「自信（HP）」ゲージを削り合う。先に相手の自信を 0 にすれば勝ち。
//

import SwiftUI

struct DuelView: View {
    @EnvironmentObject var game: GameState
    let session: DuelSession

    var body: some View {
        VStack {
            Spacer()
            RetroWindow {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    statusPane
                    logPane
                    Divider().overlay(RetroTheme.ink.opacity(0.3))
                    if session.isFinished {
                        resultControls
                    } else {
                        commandPane
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
        }
        .background(Color.black.opacity(0.4).ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("⚔️ \(session.title)")
                .font(RetroTheme.font(15))
                .foregroundColor(RetroTheme.accent)
            Text("対 \(session.opponentName)")
                .font(RetroTheme.font(10))
                .foregroundColor(RetroTheme.ink.opacity(0.7))
        }
    }

    // MARK: - 自信(HP)・気合ゲージ

    /// 敵の大きな絵（DQ風）。撃破すると薄くなる。
    private var enemyPortrait: some View {
        Image(uiImage: TextureFactory.zombieImage(tint: session.enemyTint))
            .interpolation(.none)
            .resizable()
            .frame(width: 104, height: 104)
            .frame(maxWidth: .infinity)
            .shadow(color: RetroTheme.danger.opacity(0.3), radius: 8)
            .opacity(session.isFinished && session.didWin == true ? 0.2 : 1)
    }

    private var statusPane: some View {
        VStack(spacing: 8) {
            enemyPortrait
            // 相手の自信
            gauge(label: session.opponentName,
                  value: session.enemyHP, max: session.enemyMaxHP,
                  ratio: session.enemyHPRatio, color: RetroTheme.danger)
            // 自分の自信
            gauge(label: "あなた",
                  value: session.playerHP, max: session.playerMaxHP,
                  ratio: session.playerHPRatio, color: Color(red: 0.45, green: 0.80, blue: 0.50))
            // 気合
            kiaiGauge
        }
    }

    private func gauge(label: String, value: Int, max: Int, ratio: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(RetroTheme.font(11))
                    .foregroundColor(RetroTheme.ink)
                    .lineLimit(1)
                Spacer()
                Text("体力 \(value)/\(max)")
                    .font(RetroTheme.font(11))
                    .foregroundColor(RetroTheme.ink.opacity(0.85))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.white.opacity(0.12))
                    Rectangle().fill(color)
                        .frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 10)
            .overlay(Rectangle().stroke(RetroTheme.windowBorder.opacity(0.5), lineWidth: 1))
        }
    }

    private var kiaiGauge: some View {
        HStack(spacing: 6) {
            Text("気合")
                .font(RetroTheme.font(10))
                .foregroundColor(RetroTheme.ink.opacity(0.8))
            HStack(spacing: 3) {
                ForEach(0..<session.playerMaxKiai, id: \.self) { i in
                    Circle()
                        .fill(i < session.playerKiai ? RetroTheme.accent : Color.white.opacity(0.15))
                        .frame(width: 9, height: 9)
                }
            }
            Spacer()
        }
    }

    private var logPane: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(session.log) { line in
                        Text(line.text)
                            .font(RetroTheme.font(11))
                            .foregroundColor(line.isPlayer ? RetroTheme.ink : RetroTheme.ink.opacity(0.75))
                            .frame(maxWidth: .infinity,
                                   alignment: line.isPlayer ? .leading : .trailing)
                            .id(line.id)
                    }
                }
            }
            .frame(height: 84)
            .onChange(of: session.log.count) { _, _ in
                if let last = session.log.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - コマンド

    private var commandPane: some View {
        VStack(spacing: 6) {
            Text("コマンド？")
                .font(RetroTheme.font(11))
                .foregroundColor(RetroTheme.ink.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)

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

    private var resultControls: some View {
        VStack(spacing: 8) {
            Text(session.didWin == true ? "🏆 あなたの勝ち！" : "…次は勝てる")
                .font(RetroTheme.font(16))
                .foregroundColor(session.didWin == true ? RetroTheme.accent : RetroTheme.danger)
                .frame(maxWidth: .infinity)
            RetroButton(title: "対決をおえる") {
                game.finishDuel()
            }
        }
    }
}
