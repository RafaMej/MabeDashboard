// DashboardView.swift
// Main dashboard content area — KPI row, charts grid, and pipeline table.

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: — Header
                dashboardHeader

                // MARK: — KPI Cards Row
                kpiRow

                // MARK: — Charts Row (Donut + Heatmap)
                chartsRow

                // MARK: — Sentiment Area Chart
                if !viewModel.sentimentPoints.isEmpty {
                    SentimentAreaChart(
                        dataPoints: viewModel.sentimentPoints,
                        annotations: SentimentAnnotation.mockAnnotations
                    )
                }

                // MARK: — Pipeline Table
                if !viewModel.recentQueries.isEmpty {
                    QueryPipelineTable(queries: viewModel.recentQueries)
                }

                Spacer(minLength: 20)
            }
            .padding(24)
        }
        .background(Color.NexusHR.background)
        .overlay(loadingOverlay)
        .task {
            await viewModel.loadAll()
        }
    }

    // MARK: — Dashboard Header

    private var dashboardHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard de RRHH")
                    .font(.system(size: 26, weight: .bold, design: .default))
                    .foregroundColor(Color.NexusHR.textPrimary)

                Text(viewModel.lastUpdatedLabel)
                    .font(.NexusHR.caption)
                    .foregroundColor(Color.NexusHR.textSecondary)
            }

            Spacer()

            HStack(spacing: 12) {
                // Date range picker
                Menu {
                    ForEach(DateRangeFilter.allCases) { filter in
                        Button(filter.rawValue) {
                            viewModel.selectedRange = filter
                            Task { await viewModel.loadAll() }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(viewModel.selectedRange.rawValue)
                            .font(.NexusHR.metricLabel)
                            .foregroundColor(Color.NexusHR.textPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.NexusHR.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.NexusHR.divider, lineWidth: 1)
                    )
                }
                .menuStyle(.borderlessButton)
                .accessibilityLabel("Filtro de rango de fechas: \(viewModel.selectedRange.rawValue)")

                // Export button — INTEGRATION POINT: connect to export service
                Button {
                    // INTEGRATION POINT: trigger CSV / PDF export via ExportService
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .medium))
                        Text("Exportar")
                            .font(.NexusHR.metricLabel)
                    }
                    .foregroundColor(Color.NexusHR.primaryBlue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.NexusHR.primaryBlue, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Exportar datos del dashboard")
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: — KPI Row

    private var kpiRow: some View {
        Group {
            if viewModel.kpis.isEmpty {
                kpiSkeletonRow
            } else {
                HStack(spacing: 16) {
                    ForEach(viewModel.kpis) { metric in
                        KPICardView(metric: metric)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var kpiSkeletonRow: some View {
        HStack(spacing: 16) {
            ForEach(0..<4, id: \.self) { _ in
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        RoundedRectangle(cornerRadius: 8).fill(Color.NexusHR.divider).frame(width: 40, height: 40)
                        RoundedRectangle(cornerRadius: 6).fill(Color.NexusHR.divider).frame(width: 80, height: 28)
                        RoundedRectangle(cornerRadius: 4).fill(Color.NexusHR.divider).frame(width: 110, height: 14)
                        RoundedRectangle(cornerRadius: 4).fill(Color.NexusHR.divider).frame(width: 60, height: 20)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .redacted(reason: .placeholder)
                .shimmering()
            }
        }
    }

    // MARK: — Charts Row

    private var chartsRow: some View {
        HStack(alignment: .top, spacing: 16) {
            ModelEfficiencyChart(
                data: viewModel.modelEfficiency.isEmpty ? ModelEfficiency.mockData : viewModel.modelEfficiency,
                totalConsultations: viewModel.totalConsultations == 0 ? ModelEfficiency.mockTotalConsultations : viewModel.totalConsultations
            )
            .frame(maxWidth: 400)

            ConsultaHeatmapView(
                cells: viewModel.heatmapCells.isEmpty ? HeatmapCell.mockData() : viewModel.heatmapCells
            )
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: — Loading Overlay

    @ViewBuilder
    private var loadingOverlay: some View {
        if viewModel.isLoading && viewModel.kpis.isEmpty {
            Color.NexusHR.background.opacity(0.3)
                .ignoresSafeArea()
                .overlay {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(Color.NexusHR.primaryBlue)
                }
        }
    }
}

// MARK: — Shimmer Effect Modifier

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.4), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase * 300 - 100)
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
            .clipped()
    }
}

private extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: — Preview

#Preview {
    DashboardView()
        .environmentObject(DashboardViewModel(service: MockDashboardService(simulatedLatency: 0)))
        .frame(width: 960, height: 780)
}
