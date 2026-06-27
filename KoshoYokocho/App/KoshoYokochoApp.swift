//
//  KoshoYokochoApp.swift
//  古書横丁ものがたり（仮題） — v0 プロトタイプ
//
//  アプリのエントリポイント。GameState を @StateObject として保持し、
//  「単一の真実（single source of truth）」としてビュー階層全体に注入する。
//

import SwiftUI

@main
struct KoshoYokochoApp: App {
    /// ゲーム全体の状態。永続データ＋一時的なUI状態を集約した中心オブジェクト。
    @StateObject private var game = GameState.bootstrap()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
        }
    }
}
