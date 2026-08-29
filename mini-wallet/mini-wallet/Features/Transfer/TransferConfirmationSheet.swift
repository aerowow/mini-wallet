import SwiftUI

/// Шит подтверждения перевода: состояние «Подтверждение» (ТЗ 02 §3), макет — фрейм 06.
///
/// «Глупая» вью: про `TransferViewModel`, `WalletStore` и `AppRouter` не знает.
/// Данные приходят параметрами, действия уходят замыканиями — поэтому превью
/// собираются на `MockData`, а порядок вызова стора остаётся заботой экрана.
///
/// `debugSection` — дырка для DEBUG-переключателей (ТЗ 02 §2). В обычной сборке
/// экран вызывает инициализатор без неё, `DebugSection == EmptyView`,
/// и тестовых элементов в продуктовом интерфейсе физически нет.
struct TransferConfirmationSheet<DebugSection: View>: View {
    private let source: Account
    private let destination: Account
    private let amount: Decimal
    private let comment: String?
    private let onConfirm: () -> Void
    private let onCancel: () -> Void
    private let debugSection: DebugSection

    /// Инициализаторы написаны руками: memberwise init не бывает с `@ViewBuilder`,
    /// а сигнатура — контракт с местом вызова, её нельзя отдавать компилятору.
    init(source: Account,
         destination: Account,
         amount: Decimal,
         comment: String?,
         onConfirm: @escaping () -> Void,
         onCancel: @escaping () -> Void,
         @ViewBuilder debugSection: () -> DebugSection) {
        self.source = source
        self.destination = destination
        self.amount = amount
        self.comment = comment
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        self.debugSection = debugSection()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TransferDesign.sectionSpacing) {
            Text("Подтверждение перевода")
                .font(TransferDesign.sheetTitleFont)
                .foregroundStyle(TransferDesign.textPrimary)

            VStack(alignment: .leading, spacing: TransferDesign.fieldSpacing) {
                TransferConfirmationRow(label: "Откуда", value: Self.accountText(source))
                TransferConfirmationRow(label: "Куда", value: Self.accountText(destination))
                // Сумма — в валюте счёта-источника: переводы между валютами
                // отсекает валидация формы до открытия этого шита (ТЗ 02 §3).
                TransferConfirmationRow(
                    label: "Сумма",
                    value: MoneyFormatter.string(from: amount, currency: source.currency),
                    isProminent: true
                )
                // Комиссии в MVP нет. Ноль печатаем тем же форматтером, а не строкой
                // «0,00 ₽»: хардкод разъехался бы с валютой счёта и с форматом денег.
                TransferConfirmationRow(
                    label: "Комиссия",
                    value: MoneyFormatter.string(from: .zero, currency: source.currency)
                )
                if let comment, !comment.isEmpty {
                    TransferConfirmationRow(label: "Комментарий", value: comment)
                }
            }
            .padding(TransferDesign.cardPadding)
            .transferCardBackground()

            debugSection

            // Spacer'а нет намеренно: высота шита считается по контенту
            // (TransferSheetHeight на месте вызова), поэтому корень должен
            // иметь СВОЮ высоту, а не растягиваться на весь экран.
            VStack(spacing: TransferDesign.fieldSpacing) {
                TransferPrimaryButton(title: "Подтвердить", action: onConfirm)
                TransferSecondaryButton(title: "Отмена", action: onCancel)
            }
        }
        .padding(TransferDesign.sheetPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TransferDesign.screenBackground)
    }

    /// «Основной •• 4417» — как в макете (шаг 4, фрейм 06).
    private static func accountText(_ account: Account) -> String {
        "\(account.name) \(account.maskedNumber)"
    }
}

extension TransferConfirmationSheet where DebugSection == EmptyView {
    /// Продуктовый вариант шита — без DEBUG-секции (ТЗ 02 §2).
    init(source: Account,
         destination: Account,
         amount: Decimal,
         comment: String?,
         onConfirm: @escaping () -> Void,
         onCancel: @escaping () -> Void) {
        self.init(source: source,
                  destination: destination,
                  amount: amount,
                  comment: comment,
                  onConfirm: onConfirm,
                  onCancel: onCancel,
                  debugSection: { EmptyView() })
    }
}

/// Строка «подпись — значение» карточки подтверждения.
/// Значение не переносится в ущерб сумме: при нехватке ширины сжимается подпись.
private struct TransferConfirmationRow: View {
    let label: String
    let value: String
    var isProminent: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: TransferDesign.fieldSpacing) {
            Text(label)
                .font(TransferDesign.subtitleFont)
                .foregroundStyle(TransferDesign.textSecondary)
            Spacer(minLength: TransferDesign.textSpacing)
            Text(value)
                .font(isProminent ? TransferDesign.bodySemiboldFont : TransferDesign.bodyFont)
                .foregroundStyle(TransferDesign.textPrimary)
                .multilineTextAlignment(.trailing)
                .layoutPriority(1)
        }
        // VoiceOver читает строку целиком: «Сумма, 5 000,00 ₽».
        .accessibilityElement(children: .combine)
    }
}

#Preview("Подтверждение — продуктовый вид") {
    TransferConfirmationSheet(
        source: MockData.accounts[0],
        destination: MockData.accounts[1],
        amount: 5_000,
        comment: "Отложить на отпуск",
        onConfirm: {},
        onCancel: {}
    )
}

#if DEBUG
#Preview("Подтверждение — с DEBUG-секцией") {
    @Previewable @State var simulatesExecutionFailure = false
    @Previewable @State var simulatesDuplicate = false

    TransferConfirmationSheet(
        source: MockData.accounts[0],
        destination: MockData.accounts[1],
        amount: 5_000,
        comment: nil,
        onConfirm: {},
        onCancel: {}
    ) {
        TransferDebugSection(
            simulatesExecutionFailure: $simulatesExecutionFailure,
            simulatesDuplicate: $simulatesDuplicate,
            canSimulateDuplicate: true
        )
    }
}
#endif
