import SwiftUI

enum AppFont {
    static func heading(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func subtitle(_ size: CGFloat) -> Font { .system(size: size, weight: .medium, design: .rounded) }
}

extension Color {
    static let dreamechoPrimary = Color(red: 0.45, green: 0.38, blue: 0.98)
    static let dreamechoSecondary = Color(red: 0.34, green: 0.85, blue: 0.96)
    static let dreamechoBackground = Color(red: 0.06, green: 0.07, blue: 0.15)
    static let dreamechoGlassBorder = Color.white.opacity(0.2)
}

extension LinearGradient {
    static let dreamecho = LinearGradient(colors: [.dreamechoPrimary, .dreamechoSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.dreamechoGlassBorder, lineWidth: 1.2))
            .shadow(color: .black.opacity(configuration.isPressed ? 0.1 : 0.2), radius: configuration.isPressed ? 6 : 14, x: 0, y: configuration.isPressed ? 2 : 10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(LinearGradient.dreamecho)
            .clipShape(Capsule())
            .shadow(color: .dreamechoPrimary.opacity(configuration.isPressed ? 0.25 : 0.4), radius: configuration.isPressed ? 10 : 16, y: configuration.isPressed ? 4 : 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

extension View {
    func glassBorder(cornerRadius: CGFloat = 28) -> some View {
        overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(Color.dreamechoGlassBorder, lineWidth: 1))
    }
}
