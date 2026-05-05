// SidebarView.swift
// Left navigation sidebar (220pt wide) with app brand, nav items, and user profile footer.

internal import SwiftUI

enum NavDestination: String, CaseIterable {
    case dashboard      = "Dashboard"
    case consultas      = "Consultas"
    case sentimiento    = "Sentimiento"
    case eficiencia     = "Eficiencia"
    case simulador     = "Simulador"
    case configuracion  = "Configuración"

    var icon: String {
        switch self {
        case .dashboard:     return "square.grid.2x2.fill"
        case .consultas:     return "message"
        case .sentimiento:   return "heart"
        case .eficiencia:    return "waveform.path.ecg"
        case .simulador:    return "wand.and.stars"
        case .configuracion: return "gearshape"
        }
    }
}

struct SidebarView: View {
    @Binding var selectedDestination: NavDestination

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: App Brand
            HStack(spacing: 10) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 32, height: 32)
                    .cornerRadius(8)
                    .accessibilityHidden(true)

                Text("Allies")
                    .font(.NexusHR.appName)
                    .foregroundColor(Color.NexusHR.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 24)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Nexus HR, aplicación de recursos humanos")

            // MARK: Navigation Items
            VStack(spacing: 4) {
                ForEach(NavDestination.allCases, id: \.self) { destination in
                    SidebarNavItem(
                        icon: destination.icon,
                        label: destination.rawValue,
                        isActive: selectedDestination == destination
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDestination = destination
                        }
                    }
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            Divider()
                .foregroundColor(Color.NexusHR.divider)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            // MARK: User Profile Footer
            userProfile
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
        }
        .frame(width: 220)
        .background(Color.NexusHR.sidebarBackground)
    }

    // MARK: — User Profile

    private var userProfile: some View {
        HStack(spacing: 10) {
            // Avatar placeholder — INTEGRATION POINT: Replace with AsyncImage from user profile API
            ZStack {
                Circle()
                    .fill(Color.NexusHR.primaryBlue20)
                    .frame(width: 34, height: 34)
                Text("AM")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.NexusHR.primaryBlue)
            }
            .overlay(alignment: .bottomTrailing) {
                // Online indicator — color + shape
                Circle()
                    .fill(Color.NexusHR.statusPositive)
                    .frame(width: 9, height: 9)
                    .overlay(Circle().stroke(Color.NexusHR.sidebarBackground, lineWidth: 1.5))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("Ana Martínez")
                    .font(.NexusHR.metricLabel)
                    .foregroundColor(Color.NexusHR.textPrimary)
                Text("HR Admin")
                    .font(.NexusHR.caption)
                    .foregroundColor(Color.NexusHR.textSecondary)
            }

            Spacer()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sesión activa: Ana Martínez, Administradora de RRHH")
    }
}

// MARK: — Preview

#Preview {
    @Previewable @State var destination: NavDestination = .dashboard
    SidebarView(selectedDestination: $destination)
        .frame(height: 700)
}

