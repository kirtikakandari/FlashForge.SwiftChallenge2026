import SwiftUI

enum AppTheme {
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color.accentColor.opacity(0.95), Color.accentColor.opacity(0.8)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color(.separator).opacity(0.18), lineWidth: 0.8)
                    )
            )
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}


struct PrimaryButtonStyle: ViewModifier {
    var isDisabled: Bool = false

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isDisabled ? Color(.systemGray3) : Color.accentColor)
            )
    }
}


struct PressFeedbackButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.97
    var pressedOpacity: Double = 0.92

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .opacity(configuration.isPressed ? pressedOpacity : 1)
            .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
    }
}


struct GradientBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}


struct ThemedTextField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(.separator).opacity(0.2), lineWidth: 0.8)
            )
            .foregroundStyle(Color(.label))
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }

    func primaryButtonStyle(isDisabled: Bool = false) -> some View {
        modifier(PrimaryButtonStyle(isDisabled: isDisabled))
    }

    func gradientBackground() -> some View {
        modifier(GradientBackground())
    }

    func themedTextField() -> some View {
        modifier(ThemedTextField())
    }

}
