//
//  DialogueView.swift
//  古書横丁ものがたり — 会話ウィンドウ（レトロ枠）
//
//  複数行のセリフを1ページずつ送り、最後に選択肢を出す。
//

import SwiftUI

struct DialogueView: View {
    @EnvironmentObject var game: GameState
    let content: DialogueContent

    @State private var pageIndex = 0

    private var isLastPage: Bool { pageIndex >= content.lines.count - 1 }

    var body: some View {
        VStack {
            Spacer()
            RetroWindow {
                VStack(alignment: .leading, spacing: 12) {
                    if let speaker = content.speaker {
                        Text("【\(speaker)】")
                            .font(RetroTheme.font(13))
                            .foregroundColor(RetroTheme.accent)
                    }

                    Text(content.lines.indices.contains(pageIndex) ? content.lines[pageIndex] : "")
                        .font(RetroTheme.font(14))
                        .foregroundColor(RetroTheme.ink)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .topLeading)

                    if isLastPage {
                        VStack(spacing: 6) {
                            ForEach(content.choices) { choice in
                                RetroButton(title: choice.label) {
                                    game.perform(choice.action)
                                }
                            }
                        }
                    } else {
                        HStack {
                            Spacer()
                            Button {
                                pageIndex += 1
                            } label: {
                                Text("▼ つぎへ")
                                    .font(RetroTheme.font(13))
                                    .foregroundColor(RetroTheme.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 20)
        }
        .background(Color.black.opacity(0.25).ignoresSafeArea())
    }
}
