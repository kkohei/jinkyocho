//
//  HUDView.swift
//  古書横丁ものがたり — HUD（ステータス／バフ／街レベル／調べるボタン）
//

import SwiftUI

struct HUDView: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VStack {
            topBar
            Spacer()
            bottomControls
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 18)
    }

    // MARK: - 上段：ステータス・街レベル

    private var topBar: some View {
        VStack(spacing: 6) {
            RetroWindow {
                VStack(spacing: 8) {
                    hpBar
                    HStack(spacing: 12) {
                        stat("教養", game.player.stats.kyoyo, bonus: game.player.buff?.kyoyoBonus)
                        stat("目利き", game.player.stats.mekiki, bonus: game.player.buff?.mekikiBonus)
                        stat("食通", game.player.stats.shokutsu, bonus: game.player.buff?.shokutsuBonus)
                        Divider().frame(height: 22).overlay(RetroTheme.ink.opacity(0.3))
                        miniStat("復興", "\(game.townLevel)", tint: RetroTheme.accent)
                        miniStat("撃破", "\(game.zombiesDefeated)", tint: RetroTheme.danger)
                        miniStat("図鑑", "\(game.collectedBookCount)/\(game.books.count)", tint: RetroTheme.ink)
                    }
                }
            }

            if let buff = game.player.buff {
                buffGauge(buff)
            }
        }
    }

    private var hpBar: some View {
        let p = game.player
        let color: Color = p.hpRatio > 0.5
            ? Color(red: 0.45, green: 0.80, blue: 0.50)
            : (p.hpRatio > 0.25 ? RetroTheme.accent : RetroTheme.danger)
        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("体力")
                    .font(RetroTheme.font(10))
                    .foregroundColor(RetroTheme.ink.opacity(0.85))
                Spacer()
                Text("\(p.hp)/\(p.maxHP)")
                    .font(RetroTheme.font(11))
                    .foregroundColor(RetroTheme.ink)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.white.opacity(0.12))
                    Rectangle().fill(color).frame(width: geo.size.width * p.hpRatio)
                }
            }
            .frame(height: 9)
            .overlay(Rectangle().stroke(RetroTheme.windowBorder.opacity(0.5), lineWidth: 1))
        }
    }

    private func miniStat(_ name: String, _ value: String, tint: Color) -> some View {
        VStack(spacing: 1) {
            Text(name)
                .font(RetroTheme.font(9))
                .foregroundColor(RetroTheme.ink.opacity(0.7))
            Text(value)
                .font(RetroTheme.font(13))
                .foregroundColor(tint)
        }
    }

    private func stat(_ name: String, _ value: Int, bonus: Int?) -> some View {
        VStack(spacing: 1) {
            Text(name)
                .font(RetroTheme.font(9))
                .foregroundColor(RetroTheme.ink.opacity(0.7))
            HStack(spacing: 2) {
                Text("\(value)")
                    .font(RetroTheme.font(16))
                    .foregroundColor(RetroTheme.ink)
                if let bonus, bonus > 0 {
                    Text("+\(bonus)")
                        .font(RetroTheme.font(11))
                        .foregroundColor(RetroTheme.accent)
                }
            }
        }
    }

    private func buffGauge(_ buff: Buff) -> some View {
        RetroWindow {
            VStack(alignment: .leading, spacing: 4) {
                Text("🍃 \(buff.name)")
                    .font(RetroTheme.font(11))
                    .foregroundColor(RetroTheme.ink)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.white.opacity(0.12))
                        Rectangle().fill(RetroTheme.accent)
                            .frame(width: geo.size.width * buff.progress)
                    }
                }
                .frame(height: 6)
            }
        }
        .transition(.opacity)
    }

    // MARK: - 下段：調べるボタン（スティックは別レイヤ）

    private var bottomControls: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                if let prompt = game.interactPrompt {
                    Text(prompt)
                        .font(RetroTheme.font(11))
                        .foregroundColor(RetroTheme.ink)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(RetroTheme.windowFill.opacity(0.9))
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(RetroTheme.windowBorder.opacity(0.6), lineWidth: 1))
                        .transition(.opacity)
                }
                Button {
                    game.investigate()
                } label: {
                    Text("しらべる")
                        .font(RetroTheme.font(15))
                        .foregroundColor(RetroTheme.ink)
                        .frame(width: 96, height: 60)
                        .background(
                            Circle().fill(game.interactPrompt != nil
                                          ? RetroTheme.accent.opacity(0.85)
                                          : Color.white.opacity(0.08))
                        )
                        .overlay(Circle().stroke(RetroTheme.windowBorder, lineWidth: 2).frame(width: 78, height: 78))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
