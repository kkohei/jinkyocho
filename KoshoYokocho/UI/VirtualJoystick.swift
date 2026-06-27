//
//  VirtualJoystick.swift
//  古書横丁ものがたり — 仮想スティック
//
//  ドラッグ量を -1...1 の CGVector にして GameState.moveVector へ流す。
//  シーンは update でこれを読んで移動する。
//

import Foundation
import SwiftUI

struct VirtualJoystick: View {
    /// 入力を反映する先。
    @EnvironmentObject var game: GameState

    private let baseRadius: CGFloat = 56
    private let knobRadius: CGFloat = 26

    @State private var knobOffset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        ZStack {
            // 台座
            Circle()
                .fill(Color.white.opacity(0.06))
                .overlay(Circle().stroke(RetroTheme.windowBorder.opacity(0.35), lineWidth: 2))
                .frame(width: baseRadius * 2, height: baseRadius * 2)

            // ノブ
            Circle()
                .fill(RetroTheme.accent.opacity(isDragging ? 0.9 : 0.6))
                .overlay(Circle().stroke(RetroTheme.windowBorder, lineWidth: 2))
                .frame(width: knobRadius * 2, height: knobRadius * 2)
                .offset(knobOffset)
        }
        .frame(width: baseRadius * 2, height: baseRadius * 2)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDragging = true
                    let limit = baseRadius - knobRadius
                    var dx = value.translation.width
                    var dy = value.translation.height
                    let dist = hypot(dx, dy)
                    if dist > limit, dist > 0 {
                        dx = dx / dist * limit
                        dy = dy / dist * limit
                    }
                    knobOffset = CGSize(width: dx, height: dy)
                    // SwiftUI は y 下向き、SpriteKit は y 上向きなので dy を反転。
                    game.moveVector = CGVector(dx: dx / limit, dy: -dy / limit)
                }
                .onEnded { _ in
                    isDragging = false
                    knobOffset = .zero
                    game.moveVector = .zero
                }
        )
    }
}
