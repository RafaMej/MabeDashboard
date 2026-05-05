// NexusHRApp.swift
// Nexus HR — macOS 14 Sonoma HR Analytics Dashboard
// Entry point and window configuration

import SwiftUI

@main
struct MabeApp: App {
    @StateObject private var dashboardVM = DashboardViewModel(service: MockDashboardService())

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(dashboardVM)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 780)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
