import SwiftUI

/// Zentrales Farbsystem, abgeleitet vom Rot des Tölzer-Knabenchor-Logos.
/// Alle Farben passen sich Hell-/Dunkelmodus an.
enum Theme {
    static let brand = Color(light: 0xA2201A, dark: 0xEC584F)
    static let brandDeep = Color(light: 0x6E1410, dark: 0x8F2620)
    static let gold = Color(light: 0xD99A1E, dark: 0xF2BC4B)
    static let background = Color(light: 0xFBF4EC, dark: 0x171112)
    static let card = Color(light: 0xFFFFFF, dark: 0x261C1D)

    static let heroGradient = LinearGradient(
        colors: [Color(light: 0xB8281F, dark: 0xA92B23), Color(light: 0x5E100C, dark: 0x4A0E0B)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let buttonGradient = LinearGradient(
        colors: [Color(light: 0xC22F25, dark: 0xF06A5F), Color(light: 0x8E1A14, dark: 0xC13A31)],
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

/// Dekoratives Logo-Motiv (Ring mit zwei Punkten, angelehnt an das Ö im Chor-Logo).
struct LogoRing: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().stroke(lineWidth: size * 0.12)
                HStack(spacing: size * 0.16) {
                    Circle().frame(width: size * 0.13, height: size * 0.13)
                    Circle().frame(width: size * 0.13, height: size * 0.13)
                }
                .offset(y: -size * 0.12)
            }
            .frame(width: size, height: size)
        }
    }
}
