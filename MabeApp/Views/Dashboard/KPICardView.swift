// KPICardView.swift
// Displays a single KPI metric with icon, value, and trend or live indicator.

import SwiftUI

struct KPICardView: View {
    let metric: KPIMetric

    @State private var isHovered = false
    @State private var livePulse = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Icon row
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.NexusHR.primaryBlue10)
                            .frame(width: 40, height: 40)
                        Image(systemName: metric.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.NexusHR.primaryBlue)
                            // Accessibility: icon is decorative; label is on parent
                            .accessibilityHidden(true)
                    }
                    Spacer()
                }

                // Value
                Text(metric.value)
                    .font(.NexusHR.kpiValue)
                    .foregroundColor(Color.NexusHR.textPrimary)

                // Metric title
                Text(metric.title)
                    .font(.NexusHR.metricLabel)
                    .foregroundColor(Color.NexusHR.textSecondary)

                // Trend or Live indicator
                if metric.isLive {
                    liveDot
                } else {
                    TrendIndicator(trend: metric.trend)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(
            color: .black.opacity(isHovered ? 0.10 : 0.06),
            radius: isHovered ? 18 : 12,
            x: 0, y: isHovered ? 6 : 4
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        // Accessibility: VoiceOver reads full metric context
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: — Live Pulsing Dot

    private var liveDot: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.NexusHR.statusPositive)
                .frame(width: 8, height: 8)
                .scaleEffect(livePulse ? 1.4 : 1.0)
                .opacity(livePulse ? 0.6 : 1.0)
                .animation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: livePulse
                )
            Text("en tiempo real")
                .font(.NexusHR.caption)
                .foregroundColor(Color.NexusHR.textSecondary)
        }
        .onAppear { livePulse = true }
    }

    // MARK: — Accessibility Label

    private var accessibilityLabel: String {
        var label = "\(metric.title): \(metric.value)"
        if metric.isLive {
            label += ", actualización en tiempo real"
        } else if metric.trend != 0 {
            let direction = metric.trend > 0 ? "incremento" : "decremento"
            label += ", \(direction) del \(String(format: "%.0f", abs(metric.trend)))% esta semana"
        }
        return label
    }
}

// MARK: — Preview

#Preview {
    HStack(spacing: 16) {
        ForEach(KPIMetric.mockData) { metric in
            KPICardView(metric: metric)
                .frame(width: 220)
        }
    }
    .padding(40)
    .background(Color.NexusHR.background)
}
