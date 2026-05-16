import SwiftUI

// MARK: - Color tokens
// All colors must be referenced via these extensions — never use Color("...") strings in views.

extension Color {
    // Brand
    static let brandPrimary     = Color("Brand/Primary")
    static let brandPrimaryHover = Color("Brand/PrimaryHover")
    static let brandNavy        = Color("Brand/Navy")
    static let brandAccent      = Color("Brand/Accent")
    static let brandAccentHover = Color("Brand/AccentHover")

    // Background
    static let bgPrimary        = Color("Background/Primary")
    static let bgSurface        = Color("Background/Surface")
    static let bgSecondary      = Color("Background/Secondary")

    // Text
    static let textPrimary      = Color("Text/Primary")
    static let textSecondary    = Color("Text/Secondary")
    static let textTertiary     = Color("Text/Tertiary")

    // Border
    static let borderDefault    = Color("Border/Default")
    static let borderStrong     = Color("Border/Strong")

    // Semantic
    static let semanticSuccess  = Color("Semantic/Success")
    static let semanticDanger   = Color("Semantic/Danger")
    static let semanticWarning  = Color("Semantic/Warning")
}

// MARK: - ViewModifiers

struct TipCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radii.large))
            .overlay(
                RoundedRectangle(cornerRadius: Radii.large)
                    .stroke(Color.borderDefault, lineWidth: 0.5)
            )
    }
}

struct TipPrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .background(Color.brandAccent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: Radii.large))
    }
}

struct TipSecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(Color.brandPrimary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: Radii.large))
    }
}

struct TipInputStyle: ViewModifier {
    var hasError: Bool = false

    func body(content: Content) -> some View {
        content
            .frame(minHeight: 48)
            .padding(.horizontal, Spacing.s12)
            .background(Color.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radii.medium))
            .overlay(
                RoundedRectangle(cornerRadius: Radii.medium)
                    .stroke(hasError ? Color.semanticDanger : Color.borderDefault, lineWidth: hasError ? 2 : 0.5)
            )
    }
}

extension View {
    func tipCardStyle() -> some View {
        modifier(TipCardStyle())
    }

    func tipPrimaryButton() -> some View {
        modifier(TipPrimaryButtonStyle())
    }

    func tipSecondaryButton() -> some View {
        modifier(TipSecondaryButtonStyle())
    }

    func tipInputStyle(hasError: Bool = false) -> some View {
        modifier(TipInputStyle(hasError: hasError))
    }

    /// Applies `.accessibilityLiveRegion(.polite)` on iOS 18+; no-op on earlier versions.
    /// Use this instead of `.accessibilityLiveRegion(.polite)` directly so the project
    /// compiles against the iOS 17.1 deployment target in CI (Xcode 16).
    @ViewBuilder
    func accessibilityLiveRegionPolite() -> some View {
        if #available(iOS 18, *) {
            self.accessibilityLiveRegion(.polite)
        } else {
            self
        }
    }
}
