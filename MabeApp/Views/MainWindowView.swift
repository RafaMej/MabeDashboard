// MainWindowView.swift
// Root layout: sidebar + content area in a horizontal split.
// Manages navigation state and injects environment objects.

import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var dashboardVM: DashboardViewModel
    @StateObject private var sentimentVM = SentimentViewModel()
    @StateObject private var pipelineVM = QueryPipelineViewModel()

    @State private var selectedDestination: NavDestination = .dashboard
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            // MARK: Sidebar
            SidebarView(selectedDestination: $selectedDestination)
                .frame(width: 220)

            // Divider
            Divider()
                .foregroundColor(Color.NexusHR.divider)

            // MARK: Content Area
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 900, minHeight: 680)
        .background(Color.NexusHR.background)
        // Sync pipeline VM with dashboard data when queries load
        .onChange(of: dashboardVM.recentQueries) { _, newQueries in
            pipelineVM.loadQueries(from: newQueries)
        }
    }

    // MARK: — Content Router

    @ViewBuilder
    private var contentView: some View {
        switch selectedDestination {
        case .dashboard:
            DashboardView()
                .environmentObject(dashboardVM)

        case .consultas:
            consultasPlaceholder

        case .sentimiento:
            sentimientoPlaceholder

        case .eficiencia:
            eficienciaPlaceholder

        case .configuracion:
            configuracionPlaceholder
        }
    }

    // MARK: — Placeholder Views (Future Tabs)
    // INTEGRATION POINT: Replace each placeholder with its dedicated View + ViewModel

    private var consultasPlaceholder: some View {
        placeholderView(
            icon: "message",
            title: "Consultas",
            subtitle: "Vista detallada del pipeline de consultas en desarrollo"
        )
    }

    private var sentimientoPlaceholder: some View {
        placeholderView(
            icon: "heart",
            title: "Sentimiento",
            subtitle: "Análisis profundo de sentimiento organizacional en desarrollo"
        )
    }

    private var eficienciaPlaceholder: some View {
        placeholderView(
            icon: "waveform.path.ecg",
            title: "Eficiencia",
            subtitle: "Métricas avanzadas de eficiencia del modelo en desarrollo"
        )
    }

    private var configuracionPlaceholder: some View {
        placeholderView(
            icon: "gearshape",
            title: "Configuración",
            subtitle: "Gestión de modelos, conexiones y preferencias en desarrollo"
        )
    }

    private func placeholderView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Color.NexusHR.primaryBlue.opacity(0.4))
                .accessibilityHidden(true)

            Text(title)
                .font(.NexusHR.sectionTitle)
                .foregroundColor(Color.NexusHR.textPrimary)

            Text(subtitle)
                .font(.NexusHR.body)
                .foregroundColor(Color.NexusHR.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.NexusHR.background)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): próximamente disponible")
    }
}

// MARK: — Preview

#Preview {
    MainWindowView()
        .environmentObject(DashboardViewModel(service: MockDashboardService(simulatedLatency: 0)))
        .frame(width: 1200, height: 780)
}
