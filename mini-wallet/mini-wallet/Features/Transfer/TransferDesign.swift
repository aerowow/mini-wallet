import SwiftUI

/// Дизайн-токены экрана «Перевод». Числа взяты из `design/pen-dev-prompt.md` (шаг 1:
/// отступы 4/8/12/16/24/32, радиусы 8/12/16, типографика 28/17/15/13, зона нажатия ≥ 44)
/// и сверены с `AccountsDesign`: палитра и «хром» карточки на всех трёх экранах общие.
/// Единственный источник цветов, размеров и шрифтов для всех вью фичи.
enum TransferDesign {
    // MARK: - Цвета
    // Совпадают с AccountsDesign: это одни и те же переменные макета.
    // Только светлая тема — тёмная вне скоупа (ТЗ 02 §5).
    static let screenBackground = Color(red: 245 / 255, green: 245 / 255, blue: 247 / 255)
    static let surface = Color.white
    static let border = Color(red: 227 / 255, green: 227 / 255, blue: 232 / 255)
    static let textPrimary = Color(red: 16 / 255, green: 16 / 255, blue: 20 / 255)
    static let textSecondary = Color(red: 107 / 255, green: 107 / 255, blue: 115 / 255)
    static let accent = Color(red: 10 / 255, green: 100 / 255, blue: 240 / 255)

    // На экране «Счета» не понадобились: в наборе переменных макета есть,
    // а точных значений в текстовом промпте нет — подобраны в тон палитре.
    // Красный — только для ошибок (pen-dev-prompt, шаг 2).
    static let negative = Color(red: 214 / 255, green: 48 / 255, blue: 49 / 255)
    static let positive = Color(red: 24 / 255, green: 152 / 255, blue: 92 / 255)
    /// Заливка вторичной кнопки и кнопки-свопа.
    static let secondaryFill = Color(red: 236 / 255, green: 236 / 255, blue: 240 / 255)

    // MARK: - Геометрия
    static let screenHPadding: CGFloat = 20
    static let sheetPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    /// Шкала отступов макета: 4 / 8 / 12 / 16 / 24 / 32.
    static let fieldSpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 24
    static let textSpacing: CGFloat = 4
    static let cardCornerRadius: CGFloat = 16
    static let fieldCornerRadius: CGFloat = 12
    static let borderWidth: CGFloat = 1
    static let buttonHeight: CGFloat = 52
    static let buttonCornerRadius: CGFloat = 16
    /// Минимальная зона нажатия из макета — кнопка-своп и мелкие тапы.
    static let iconButtonSize: CGFloat = 44
    /// Иконка в шапке шита результата.
    static let sheetIconSize: CGFloat = 48

    // MARK: - Типографика
    // Как в AccountsDesign: размеры макета 28/34/17/15/13 совпадают с дефолтами
    // системных стилей, поэтому Dynamic Type достаётся без расхождения с макетом.
    static let titleFont = Font.system(.title, weight: .bold)
    static let amountLargeFont = Font.system(.largeTitle, weight: .bold)
    static let sheetTitleFont = Font.system(.title3, weight: .semibold)
    static let bodyFont = Font.system(.body)
    static let bodySemiboldFont = Font.system(.body, weight: .semibold)
    static let subtitleFont = Font.system(.subheadline)
    static let captionFont = Font.system(.footnote)
}

extension View {
    /// «Хром» карточки/поля: белая подложка со скруглением 16 и бордером 1 pt.
    func transferCardBackground() -> some View {
        background {
            RoundedRectangle(cornerRadius: TransferDesign.cardCornerRadius)
                .fill(TransferDesign.surface)
                .strokeBorder(TransferDesign.border, lineWidth: TransferDesign.borderWidth)
        }
    }

    /// То же со скруглением 12 — для полей ввода и строк выбора счёта.
    func transferFieldBackground() -> some View {
        background {
            RoundedRectangle(cornerRadius: TransferDesign.fieldCornerRadius)
                .fill(TransferDesign.surface)
                .strokeBorder(TransferDesign.border, lineWidth: TransferDesign.borderWidth)
        }
    }
}
