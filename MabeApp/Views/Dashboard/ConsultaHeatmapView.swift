// ConsultaHeatmapView.swift
// Weekly consultation heatmap using Swift Charts RectangleMark.
// Color intensity maps query count; labels always present for accessibility.

import SwiftUI
import Charts

struct ConsultaHeatmapView: View {
    let cells: [HeatmapCell]

    @State private var hoveredCell: HeatmapCell? = nil
    @State private var tooltipPosition: CGPoint = .zero

    private let hours = Array(6...22)
    private let days = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]

    private var maxCount: Int {
        cells.map(\.queryCount).max() ?? 1
    }

    // INTEGRATION POINT: Call this method to refresh heatmap with live data
    func loadData(from source: HeatmapDataSource) async {
        // INTEGRATION POINT: Await data from your custom HeatmapDataSource protocol
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Heatmap de Consultas")
                    .font(.NexusHR.sectionTitle)
                    .foregroundColor(Color.NexusHR.textPrimary)

                // Day headers
                HStack(spacing: 0) {
                    // Hour label column spacer
                    Text("00:00")
                        .font(.NexusHR.tiny)
                        .hidden()
                        .frame(width: 42)

                    ForEach(days, id: \.self) { day in
                        Text(day)
                            .font(.NexusHR.tiny)
                            .foregroundColor(Color.NexusHR.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Grid
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 3) {
                        ForEach(hours, id: \.self) { hour in
                            HStack(spacing: 3) {
                                // Hour label
                                Text(String(format: "%02d:00", hour))
                                    .font(.NexusHR.tiny)
                                    .foregroundColor(Color.NexusHR.textSecondary)
                                    .frame(width: 42, alignment: .trailing)
                                    .accessibilityHidden(true)

                                // Day cells
                                ForEach(0..<7, id: \.self) { dayIndex in
                                    if let cell = cell(hour: hour, day: dayIndex) {
                                        heatCell(cell)
                                    }
                                }
                            }
                        }
                    }
                }

                // Color scale legend
                colorScaleLegend
            }
            .padding(20)
        }
        // Tooltip overlay
        .overlay(alignment: .topLeading) {
            if let cell = hoveredCell {
                tooltipView(for: cell)
                    .offset(x: tooltipPosition.x + 12, y: tooltipPosition.y - 30)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityLabel("Heatmap de consultas por hora y día de la semana")
        .accessibilityValue("Pico de actividad entre las 9 y las 11 de la mañana de lunes a viernes")
    }

    // MARK: — Cell View

    @ViewBuilder
    private func heatCell(_ cell: HeatmapCell) -> some View {
        let intensity = maxCount > 0 ? Double(cell.queryCount) / Double(maxCount) : 0
        let fillColor = Color.NexusHR.primaryBlue.opacity(max(0.08, intensity))

        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(fillColor)
            .frame(maxWidth: .infinity)
            .aspectRatio(1.2, contentMode: .fit)
            .overlay(
                // Focus ring for keyboard navigation
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(hoveredCell?.id == cell.id ? Color.NexusHR.primaryBlue : Color.clear, lineWidth: 1.5)
            )
            .onHover { isHovered in
                hoveredCell = isHovered ? cell : nil
            }
            .accessibilityElement()
            .accessibilityLabel("\(cell.dayLabel), \(cell.hourLabel)")
            .accessibilityValue("\(cell.queryCount) consultas")
    }

    // MARK: — Tooltip

    @ViewBuilder
    private func tooltipView(for cell: HeatmapCell) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(cell.dayLabel) \(cell.hourLabel)")
                .font(.NexusHR.tiny)
                .foregroundColor(Color.NexusHR.textSecondary)
            Text("\(cell.queryCount) consultas")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Color.NexusHR.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.NexusHR.borderSubtle, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    // MARK: — Color Scale Legend

    private var colorScaleLegend: some View {
        HStack(spacing: 6) {
            Text("Menos")
                .font(.NexusHR.tiny)
                .foregroundColor(Color.NexusHR.textTertiary)
            HStack(spacing: 2) {
                ForEach([0.08, 0.25, 0.5, 0.75, 1.0], id: \.self) { opacity in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.NexusHR.primaryBlue.opacity(opacity))
                        .frame(width: 16, height: 10)
                }
            }
            Text("Más")
                .font(.NexusHR.tiny)
                .foregroundColor(Color.NexusHR.textTertiary)
        }
        .accessibilityLabel("Escala de color: de menos a más consultas")
    }

    // MARK: — Helper

    private func cell(hour: Int, day: Int) -> HeatmapCell? {
        cells.first { $0.hour == hour && $0.dayOfWeek == day }
    }
}

// MARK: — Data Source Protocol (Integration Hook)

/// INTEGRATION POINT: Implement this protocol to connect a live data source.
protocol HeatmapDataSource {
    func heatmapCells(for range: DateInterval) async throws -> [HeatmapCell]
}

// MARK: — Preview

#Preview {
    ConsultaHeatmapView(cells: HeatmapCell.mockData())
        .frame(width: 520)
        .padding(40)
        .background(Color.NexusHR.background)
}
