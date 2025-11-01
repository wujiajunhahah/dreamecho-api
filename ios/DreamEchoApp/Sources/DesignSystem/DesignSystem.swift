import SwiftUI

enum AppFont {
    static func heading(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func subtitle(_ size: CGFloat) -> Font { .system(size: size, weight: .medium, design: .rounded) }
}

// MARK: - Theme (Wise-inspired palette)
struct AppTheme {
    let accentPrimary: Color
    let accentSecondary: Color
    let background: Color   // 页面背景/Surface 颜色
    let glassBorder: Color

    static let current: AppTheme = .wise

    // 参考外部设计系统（可在此微调色值以对齐品牌）
    static let wise = AppTheme(
        accentPrimary: Color(red: 0.09, green: 0.75, blue: 0.38),   // Green
        accentSecondary: Color(red: 0.30, green: 0.90, blue: 0.60), // Light Green
        background: Color.white,                                     // 以白色为主
        glassBorder: Color.black.opacity(0.08)
    )
}

extension Color {
    static var dreamechoPrimary: Color { AppTheme.current.accentPrimary }
    static var dreamechoSecondary: Color { AppTheme.current.accentSecondary }
    static var dreamechoBackground: Color { AppTheme.current.background }
    static var dreamechoGlassBorder: Color { AppTheme.current.glassBorder }
    static var textPrimary: Color { Color.black }
    static var textSecondary: Color { Color.black.opacity(0.6) }
}

extension LinearGradient {
    static var dreamecho: LinearGradient {
        LinearGradient(colors: [.dreamechoPrimary, .dreamechoSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
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
            .overlay(
                Capsule().stroke(LinearGradient(colors: [Color.white.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 1)
            )
            .shadow(color: .dreamechoPrimary.opacity(configuration.isPressed ? 0.25 : 0.5), radius: configuration.isPressed ? 10 : 18, y: configuration.isPressed ? 4 : 10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

extension View {
    func glassBorder(cornerRadius: CGFloat = 28) -> some View {
        overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(Color.dreamechoGlassBorder, lineWidth: 1))
    }
}

// MARK: - Layout & GlassCard

enum Layout {
    static let containerMaxWidth: CGFloat = 860
    static let horizontalPadding: CGFloat = 20
    static let verticalSectionSpacing: CGFloat = 20
    static let gridSpacing: CGFloat = 16
    static let largeCornerRadius: CGFloat = 28
    static let minCardWidthCompact: CGFloat = 220
    static let minCardWidthRegular: CGFloat = 260
}
// 图标尺寸规范
enum AppIcon {
    static let large: CGFloat = 30
    static let xlarge: CGFloat = 34
}

struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let content: Content

    init(cornerRadius: CGFloat = Layout.largeCornerRadius, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(Layout.verticalSectionSpacing)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                // 顶部高光，增强液态玻璃质感
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(colors: [
                            Color.white.opacity(0.10),
                            Color.white.opacity(0.04),
                            Color.clear
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .allowsHitTesting(false)
            )
            .glassBorder(cornerRadius: cornerRadius)
            .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 10)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = Layout.largeCornerRadius, contentPadding: CGFloat = Layout.verticalSectionSpacing) -> some View {
        self
            .padding(contentPadding)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
            )
    }
}
