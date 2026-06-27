//
//  ContentView.swift
//  古書横丁ものがたり — ルートビュー
//
//  SpriteKit の横丁シーンの上に、SwiftUI の HUD・仮想スティック・
//  会話・対決ウィンドウ・トーストを重ねる。
//

import SpriteKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var game: GameState
    @State private var scene: YokochoScene?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1) ゲーム本体（SpriteKit）
                if let scene {
                    SpriteView(scene: scene, preferredFramesPerSecond: 60)
                        .ignoresSafeArea()
                } else {
                    Color.black.ignoresSafeArea()
                }

                // 2) HUD（ステータス／調べる）
                HUDView()

                // 3) 仮想スティック（左下）。会話・対決中は隠す。
                if game.activeDialogue == nil && game.activeDuel == nil {
                    VStack {
                        Spacer()
                        HStack {
                            VirtualJoystick()
                                .padding(.leading, 28)
                                .padding(.bottom, 24)
                            Spacer()
                        }
                    }
                }

                // 4) 会話ウィンドウ
                if let dialogue = game.activeDialogue {
                    DialogueView(content: dialogue)
                        .id(dialogue.id)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // 5) 対決ウィンドウ
                if let duel = game.activeDuel {
                    DuelView(session: duel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // 6) トースト
                if let toast = game.toast {
                    VStack {
                        Spacer()
                        Text(toast)
                            .font(RetroTheme.font(12))
                            .foregroundColor(RetroTheme.ink)
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .background(RetroTheme.windowFill.opacity(0.95))
                            .overlay(RoundedRectangle(cornerRadius: 3)
                                .stroke(RetroTheme.windowBorder, lineWidth: 2))
                            .padding(.bottom, 150)
                            .transition(.opacity)
                    }
                    .allowsHitTesting(false)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: game.activeDialogue?.id)
            .animation(.easeInOut(duration: 0.2), value: game.activeDuel?.id)
            .animation(.easeInOut(duration: 0.2), value: game.toast)
            .animation(.easeInOut(duration: 0.2), value: game.player.buff?.id)
            .onAppear {
                if scene == nil {
                    let s = YokochoScene(game: game, size: geo.size)
                    scene = s
                }
            }
        }
    }
}
