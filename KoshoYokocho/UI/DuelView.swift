//
//  DuelView.swift
//  古書横丁ものがたり — グルメ対決ウィンドウ（ターン制コマンド）
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
                    scoreBoard
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
            Text("🍛 \(session.title)")
                .font(RetroTheme.font(15))
                .foregroundColor(RetroTheme.accent)
            Text("対 \(session.opponentName)　／　\(min(session.turn, session.totalTurns))品目・全\(session.totalTurns)品")
                .font(RetroTheme.font(10))
                .foregroundColor(RetroTheme.ink.opacity(0.7))
        }
    }

    private var scoreBoard: some View {
        HStack {
            scoreCol(name: "あなた", score: session.playerScore, tint: RetroTheme.accent)
            Text("対")
                .font(RetroTheme.font(13))
                .foregroundColor(RetroTheme.ink.opacity(0.6))
            scoreCol(name: session.opponentName, score: session.opponentScore, tint: RetroTheme.danger)
        }
        .frame(maxWidth: .infinity)
    }

    private func scoreCol(name: String, score: Int, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(name)
                .font(RetroTheme.font(10))
                .foregroundColor(RetroTheme.ink.opacity(0.8))
                .lineLimit(1)
            Text("\(score)")
                .font(RetroTheme.font(24))
                .foregroundColor(tint)
        }
        .frame(maxWidth: .infinity)
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
            .frame(height: 96)
            .onChange(of: session.log.count) { _, _ in
                if let last = session.log.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var commandPane: some View {
        VStack(spacing: 6) {
            Text("コマンドを選べ")
                .font(RetroTheme.font(11))
                .foregroundColor(RetroTheme.ink.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(GourmetCommand.allCases) { command in
                RetroButton(title: command.label, subtitle: command.hint) {
                    game.playGourmet(command: command)
                }
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
