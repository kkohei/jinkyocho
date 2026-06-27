//
//  RetroTheme.swift
//  古書横丁ものがたり — レトロUIの色・フォント・ウィンドウ枠
//
//  8〜16bit JRPG 風の二重枠ウィンドウとビットマップ調フォントを共通化する。
//

import SwiftUI

enum RetroTheme {
    static let ink = Color(red: 0.96, green: 0.93, blue: 0.84)        // 文字（生成り）
    static let windowFill = Color(red: 0.12, green: 0.10, blue: 0.16) // ウィンドウ背景（濃紺）
    static let windowBorder = Color(red: 0.96, green: 0.93, blue: 0.84)
    static let accent = Color(red: 0.95, green: 0.78, blue: 0.36)     // 山吹色
    static let danger = Color(red: 0.88, green: 0.42, blue: 0.40)

    /// ビットマップ調の等幅フォント（端末標準の monospaced を流用）。
    static func font(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .monospaced)
    }
}

/// レトロな二重枠ウィンドウ。会話・対決・HUDの土台に使う。
struct RetroWindow<Content: View>: View {
    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(14)
            .background(RetroTheme.windowFill)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(RetroTheme.windowBorder, lineWidth: 3)
                    .padding(3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(RetroTheme.windowBorder.opacity(0.5), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

/// レトロなコマンドボタン。
struct RetroButton: View {
    let title: String
    var subtitle: String? = nil
    var tint: Color = RetroTheme.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("▶").foregroundColor(tint)
                    Text(title).foregroundColor(RetroTheme.ink)
                }
                .font(RetroTheme.font(15))
                if let subtitle {
                    Text(subtitle)
                        .font(RetroTheme.font(10))
                        .foregroundColor(RetroTheme.ink.opacity(0.65))
                        .padding(.leading, 18)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(RetroTheme.windowBorder.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
