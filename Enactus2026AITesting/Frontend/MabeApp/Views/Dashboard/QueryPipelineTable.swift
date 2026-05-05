// QueryPipelineTable.swift
// Sortable macOS Table listing recent HR queries with status badges and keyboard navigation.

internal import SwiftUI

struct QueryPipelineTable: View {
    let queries: [QueryRecord]

    @State private var sortOrder: [KeyPathComparator<QueryRecord>] = [
        KeyPathComparator(\QueryRecord.timestamp, order: .reverse)
    ]
    @State private var selection: Set<QueryRecord.ID> = []
    @State private var hoveredRow: QueryRecord.ID? = nil

    private var sortedQueries: [QueryRecord] {
        queries.sorted(using: sortOrder)
    }

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "dd MMM, HH:mm"
        return f
    }()

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pipeline de Consultas")
                            .font(.NexusHR.sectionTitle)
                            .foregroundColor(Color.NexusHR.textPrimary)
                        Text("Historial reciente de consultas procesadas")
                            .font(.NexusHR.caption)
                            .foregroundColor(Color.NexusHR.textSecondary)
                    }
                    Spacer()
                    // Live count badge
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.NexusHR.statusPositive)
                            .frame(width: 7, height: 7)
                        Text("\(queries.count) consultas")
                            .font(.NexusHR.caption)
                            .foregroundColor(Color.NexusHR.textSecondary)
                    }
                }
                .padding(20)

                Divider()
                    .foregroundColor(Color.NexusHR.divider)

                // Table
                Table(sortedQueries, selection: $selection, sortOrder: $sortOrder) {

                    TableColumn("Hora", value: \.timestamp) { record in
                        Text(timeFormatter.string(from: record.timestamp))
                            .font(.NexusHR.tableCell)
                            .foregroundColor(Color.NexusHR.textSecondary)
                            .monospacedDigit()
                    }
                    .width(min: 110, ideal: 120)

                    TableColumn("Categoría", value: \.category.rawValue) { record in
                        HStack(spacing: 6) {
                            Image(systemName: record.category.icon)
                                .font(.system(size: 12))
                                .foregroundColor(Color.NexusHR.primaryBlue)
                                .accessibilityHidden(true)
                            Text(record.category.rawValue)
                                .font(.NexusHR.tableCell)
                                .foregroundColor(Color.NexusHR.textPrimary)
                        }
                    }
                    .width(min: 100, ideal: 130)

                    TableColumn("Modelo", value: \.modelUsed.rawValue) { record in
                        StatusBadge.forModel(record.modelUsed)
                    }
                    .width(min: 100, ideal: 130)

                    TableColumn("Estado", value: \.status.rawValue) { record in
                        StatusBadge.forStatus(record.status)
                    }
                    .width(min: 90, ideal: 110)

                    TableColumn("Sentimiento", value: \.sentiment.rawValue) { record in
                        StatusBadge.forSentiment(record.sentiment)
                    }
                    .width(min: 90, ideal: 110)

                    TableColumn("PII") { record in
                        HStack(spacing: 4) {
                            Image(systemName: record.isAnonymized ? "lock.fill" : "lock.open")
                                .font(.system(size: 11))
                                .foregroundColor(record.isAnonymized ? Color.NexusHR.statusPositive : Color.NexusHR.statusNegative)
                            Text(record.isAnonymized ? "Anon." : "Sin anon.")
                                .font(.NexusHR.caption)
                                .foregroundColor(Color.NexusHR.textSecondary)
                        }
                        .accessibilityLabel(record.isAnonymized ? "Datos anonimizados" : "Sin anonimizar")
                    }
                    .width(min: 80, ideal: 90)
                }
                .tableStyle(.inset)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(height: 280)
                // Full keyboard navigation via focusable rows (macOS Table handles this natively)
                .focusable()
                .accessibilityLabel("Tabla de consultas recientes")
            }
        }
    }
}

// MARK: — Preview

#Preview {
    QueryPipelineTable(queries: QueryRecord.mockData)
        .frame(width: 800)
        .padding(40)
        .background(Color.NexusHR.background)
}
