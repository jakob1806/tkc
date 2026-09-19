import SwiftUI

/// Zentrales Farbsystem, abgeleitet vom Rot des Tölzer-Knabenchor-Logos.
/// Alle Farben passen sich Hell-/Dunkelmodus an.
enum Theme {
    static let brand = Color(light: 0x952121, dark: 0xE2635C)
    static let brandDeep = Color(light: 0x651313, dark: 0x8A2A26)
    static let gold = Color(light: 0xD99A1E, dark: 0xF2BC4B)
    static let background = Color(light: 0xFBF4EC, dark: 0x171112)
    static let card = Color(light: 0xFFFFFF, dark: 0x261C1D)

    static let heroGradient = LinearGradient(
        colors: [Color(light: 0xA52727, dark: 0x9C2E2A), Color(light: 0x5C1010, dark: 0x4A1210)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let buttonGradient = LinearGradient(
        colors: [Color(light: 0xA92828, dark: 0xE87068), Color(light: 0x7C1919, dark: 0xB8403A)],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

extension View {
    /// Warmer Hintergrund statt kaltem Systemgrau für Listen-Screens.
    func themedList() -> some View {
        scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
    }
}

/// Farbiges Icon-Kästchen (wie in den iOS-Einstellungen) für Menüzeilen.
struct ThemedLabel: View {
    let title: String
    let symbol: String
    var color: Color = Theme.brand

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
    }
}

/// Datums-Kästchen (Tag + Monat) für Konzertzeilen.
struct DateBadge: View {
    let date: Date
    var isPast = false

    var body: some View {
        VStack(spacing: 0) {
            Text(date.formatted(Date.FormatStyle(locale: .german).day()))
                .font(.title3.weight(.bold))
            Text(date.formatted(Date.FormatStyle(locale: .german).month(.abbreviated)))
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
        }
        .foregroundStyle(.white)
        .frame(width: 48, height: 48)
        .background(
            isPast ? AnyShapeStyle(Color.gray.gradient) : AnyShapeStyle(Theme.buttonGradient),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }
}
