// NexusHRApp.swift
// Nexus HR — macOS 14 Sonoma HR Analytics Dashboard
// Entry point and window configuration

internal import SwiftUI
import SwiftData

@main
struct MabeApp: App {
    static let container: ModelContainer = {
        let schema = Schema([
            DocumentChunk.self,
            ConversacionLog.self,
            Colaborador.self,
            Ticket.self
        ])
        let config = ModelConfiguration("csc-nexushr", schema: schema)
        return try! ModelContainer(for: schema, configurations: config)
    }()

    @StateObject private var dashboardVM = DashboardViewModel(service: LiveDashboardService(container: Self.container))

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(dashboardVM)
                .task { await arrancarApp() }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .modelContainer(Self.container)
        .defaultSize(width: 1200, height: 750)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }

    @MainActor
    private func arrancarApp() async {
        // Seed test collaborators on first launch
        let context = Self.container.mainContext
        try? ColaboradorSeeder.sembrarSiNecesario(context: context)

        // Index PDFs in background — only runs once per document
        Task.detached(priority: .background) {
            do {
                let service = DocumentoIndexerService(modelContainer: Self.container)
                let resultados = try await service.indexarTodosLosDocumentos()
                let total = resultados.values.reduce(0) { $0 + $1.chunksIndexados }
                print("[NexusHR] Indexación completa — \(total) chunks")
            } catch {
                print("[NexusHR] Error indexación: \(error)")
            }
        }
    }
}
