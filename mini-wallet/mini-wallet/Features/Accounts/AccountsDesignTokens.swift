import SwiftUI

/// Дизайн-токены экрана «Счета» по макету design/accountsDesign.pdf.
/// Единственный источник цветов, размеров и шрифтов для всех вью фичи.
enum AccountsDesign {
    // Цвета макета (только светлая тема — тёмная вне скоупа, ТЗ 01 §5)
    static let screenBackground = Color(red: 245 / 255, green: 245 / 255, blue: 247 / 255)
    static let surface = Color.white
    static let border = Color(red: 227 / 255, green: 227 / 255, blue: 232 / 255)
    static let textPrimary = Color(red: 16 / 255, green: 16 / 255, blue: 20 / 255)
    static let textSecondary = Color(red: 107 / 255, green: 107 / 255, blue: 115 / 255)
    static let accent = Color(red: 10 / 255, green: 100 / 255, blue: 240 / 255)

    // Геометрия
    static let screenHPadding: CGFloat = 20
    static let cardCornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 24
    static let buttonHeight: CGFloat = 52
    static let buttonCornerRadius: CGFloat = 16
    static let borderWidth: CGFloat = 1

    // Типографика макета: 28 / 34 / 17 / 15 / 13
    static let titleFont = Font.system(size: 28, weight: .bold)
    static let amountLargeFont = Font.system(size: 34, weight: .bold)
    static let bodyFont = Font.system(size: 17)
    static let bodySemiboldFont = Font.system(size: 17, weight: .semibold)
    static let subtitleFont = Font.system(size: 15)
    static let captionFont = Font.system(size: 13)
}

extension View {
    /// Единый «хром» карточки: белая подложка со скруглением 16 и бордером 1 pt.
    func accountsCardBackground() -> some View {
        background {
            RoundedRectangle(cornerRadius: AccountsDesign.cardCornerRadius)
                .fill(AccountsDesign.surface)
                .strokeBorder(AccountsDesign.border, lineWidth: AccountsDesign.borderWidth)
        }
    }
}
