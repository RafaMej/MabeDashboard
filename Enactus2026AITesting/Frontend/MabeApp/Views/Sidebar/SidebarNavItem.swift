// SidebarNavItem.swift
// Individual navigation item in the sidebar with active state highlighting.

internal import SwiftUI

struct SidebarNavItem: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? .white : Color.NexusHR.sidebarInactiveText)
                    .frame(width: 18)
                    .accessibilityHidden(true)

                Text(label)
                    .font(.NexusHR.sidebarItem)
                    .foregroundColor(isActive ? .white : Color.NexusHR.sidebarInactiveText)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                Group {
                    if isActive {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.NexusHR.primaryBlue)
                    } else if isHovered {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.NexusHR.primaryBlue20)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        // Accessibility: visible focus ring in primaryBlue
        .focusEffectDisabled(false)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
        // Keyboard-accessible focus ring
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.NexusHR.primaryBlue, lineWidth: 2)
                .opacity(0) // Shown by system focus ring; kept for custom-ring use if needed
        )
    }
}

// MARK: — Preview

#Preview {
    VStack(spacing: 4) {
        SidebarNavItem(icon: "square.grid.2x2", label: "Dashboard", isActive: true, action: {})
        SidebarNavItem(icon: "message", label: "Consultas", isActive: false, action: {})
        SidebarNavItem(icon: "heart", label: "Sentimiento", isActive: false, action: {})
    }
    .padding(16)
    .frame(width: 220)
    .background(Color.NexusHR.sidebarBackground)
}
