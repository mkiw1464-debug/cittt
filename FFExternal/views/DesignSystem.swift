import SwiftUI

// MARK: - FF External Design System (ProjectX Edition)
// Theme: Pure black + red — aggressive, clean

// MARK: - FFTheme (original — kept for LoginView, LanguagePickerView compatibility)

enum FFTheme {
    static let background        = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let backgroundSecond  = Color(red: 0.08, green: 0.08, blue: 0.09)
    static let card              = Color(red: 0.10, green: 0.10, blue: 0.10)
    static let cardElevated      = Color(red: 0.14, green: 0.14, blue: 0.14)

    static let glass             = Color.white.opacity(0.05)
    static let glassBorder       = Color.white.opacity(0.08)
    static let separator         = Color.white.opacity(0.07)

    static let text              = Color.white
    static let textSecondary     = Color(white: 0.50)
    static let textTertiary      = Color(white: 0.32)

    // Accent mapped to red for ProjectX style
    static let accent            = Color(red: 0.90, green: 0.12, blue: 0.12)
    static let accentAlt         = Color(red: 0.70, green: 0.10, blue: 0.10)

    static let success           = Color(red: 0.18, green: 0.78, blue: 0.38)
    static let danger            = Color(red: 0.90, green: 0.12, blue: 0.12)
    static let warn              = Color(red: 0.95, green: 0.70, blue: 0.15)

    static let titleFont    = Font.system(size: 30, weight: .bold,    design: .rounded)
    static let subtitleFont = Font.system(size: 14, weight: .regular, design: .rounded)
    static let bodyFont     = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let captionFont  = Font.system(size: 12, weight: .regular, design: .rounded)
    static let labelFont    = Font.system(size: 11, weight: .semibold, design: .rounded)
    static let monoFont     = Font.system(size: 13, weight: .medium,  design: .monospaced)

    static let cornerRadius: CGFloat = 14
    static let cardPadding:  CGFloat = 16
}

// MARK: - PXTheme (ProjectX — used by MainMenuView)

enum PXTheme {
    // Backgrounds
    static let background      = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let backgroundDeep  = Color(red: 0.03, green: 0.03, blue: 0.03)
    static let sidebar         = Color(red: 0.07, green: 0.07, blue: 0.07)
    static let card            = Color(red: 0.10, green: 0.10, blue: 0.10)
    static let cardElevated    = Color(red: 0.14, green: 0.14, blue: 0.14)

    // Borders
    static let separator       = Color.white.opacity(0.07)
    static let glassBorder     = Color.white.opacity(0.08)
    static let redBorder       = Color(red: 0.85, green: 0.10, blue: 0.10).opacity(0.50)

    // Text
    static let text            = Color.white
    static let textSecondary   = Color(white: 0.50)
    static let textDim         = Color(white: 0.32)

    // Accent — red
    static let accent          = Color(red: 0.90, green: 0.12, blue: 0.12)
    static let accentDark      = Color(red: 0.65, green: 0.08, blue: 0.08)
    static let accentGlow      = Color(red: 0.90, green: 0.12, blue: 0.12).opacity(0.18)

    // Semantic
    static let success         = Color(red: 0.18, green: 0.80, blue: 0.38)
    static let warn            = Color(red: 0.95, green: 0.70, blue: 0.15)
    static let online          = Color(red: 0.90, green: 0.12, blue: 0.12)

    // Layout
    static let cornerRadius:   CGFloat = 14
    static let cardPadding:    CGFloat = 16
    static let sidebarWidth:   CGFloat = 78
}

// MARK: - Background views

struct FFBackground: View {
    var body: some View {
        FFTheme.background.ignoresSafeArea()
    }
}

struct PXBackground: View {
    var body: some View {
        PXTheme.backgroundDeep.ignoresSafeArea()
    }
}

// MARK: - Card modifiers

struct CardModifier: ViewModifier {
    var padding: CGFloat = FFTheme.cardPadding
    var radius:  CGFloat = FFTheme.cornerRadius
    var color:   Color   = FFTheme.card

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(color)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(FFTheme.glassBorder, lineWidth: 0.8)
                    )
            )
    }
}

extension View {
    func ffCard(padding: CGFloat = FFTheme.cardPadding,
                radius:  CGFloat = FFTheme.cornerRadius,
                color:   Color   = FFTheme.card) -> some View {
        modifier(CardModifier(padding: padding, radius: radius, color: color))
    }

    func glassCard(padding: CGFloat = FFTheme.cardPadding,
                   cornerRadius: CGFloat = FFTheme.cornerRadius) -> some View {
        ffCard(padding: padding, radius: cornerRadius)
    }

    func shimmerBorder() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: FFTheme.cornerRadius, style: .continuous)
                .strokeBorder(FFTheme.glassBorder, lineWidth: 0.8)
        )
    }

    func pxCard(padding: CGFloat = PXTheme.cardPadding,
                radius:  CGFloat = PXTheme.cornerRadius,
                color:   Color   = PXTheme.card) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(color)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(PXTheme.glassBorder, lineWidth: 0.7)
                    )
            )
    }
}

// MARK: - FFButton (original — LoginView uses this)

struct FFButton: View {
    let title:   String
    var icon:    String? = nil
    let action:  () -> Void
    var isLoading:  Bool = false
    var isDisabled: Bool = false
    var style: ButtonStyle = .primary

    enum ButtonStyle { case primary, secondary, danger }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(labelColor).scaleEffect(0.85)
                } else if let icon {
                    Image(systemName: icon).font(.system(size: 15, weight: .semibold))
                }
                Text(title).font(FFTheme.bodyFont)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(labelColor)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: FFTheme.cornerRadius - 2, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FFTheme.cornerRadius - 2, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 0.8)
            )
            .opacity(isDisabled ? 0.40 : 1.0)
        }
        .disabled(isDisabled || isLoading)
        .buttonStyle(.plain)
    }

    private var bgColor: Color {
        switch style {
        case .primary:   return PXTheme.accent
        case .secondary: return FFTheme.cardElevated
        case .danger:    return FFTheme.danger.opacity(0.15)
        }
    }
    private var labelColor: Color {
        switch style {
        case .primary:   return .white
        case .secondary: return FFTheme.text
        case .danger:    return FFTheme.danger
        }
    }
    private var borderColor: Color {
        switch style {
        case .primary:   return Color.clear
        case .secondary: return FFTheme.glassBorder
        case .danger:    return FFTheme.danger.opacity(0.4)
        }
    }
}

// MARK: - Exploit Status (used by MainMenuView + SupportPolicy)

enum ExploitStatus: Equatable {
    case notStarted
    case success(method: String)
    case failed(method: String, code: Int)
    case unsupported(String)

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}
