import SwiftUI

/// Шит успеха: состояние «Успех» (ТЗ 02 §3), макет — фрейм 08.
///
/// «Глупая» вью: ни `TransferViewModel`, ни `WalletStore` ей не нужны.
/// Счета приходят параметрами уже с ОБНОВЛЁННЫМИ балансами — их пересчитал стор
/// внутри `transfer(_:)`, шит ничего не вычитает и не складывает сам.
/// Счета опциональные: если стор их почему-то не отдал, строка баланса просто
/// не показывается, а шит остаётся валидным.
struct TransferSuccessSheet: View {
    let operation: Operation
    let sourceAccount: Account?
    let destinationAccount: Account?
    let onOpenHistory: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TransferDesign.sectionSpacing) {
            VStack(spacing: TransferDesign.fieldSpacing) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: TransferDesign.sheetIconSize))
                    .foregroundStyle(TransferDesign.positive)
                    // Иконка декоративная: смысл несёт заголовок.
                    .accessibilityHidden(true)

                Text("Перевод выполнен")
                    .font(TransferDesign.sheetTitleFont)
                    .foregroundStyle(TransferDesign.textPrimary)

                Text(MoneyFormatter.string(from: operation.amount, currency: operation.currency))
                    .font(TransferDesign.amountLargeFont)
                    .foregroundStyle(TransferDesign.textPrimary)

                if let routeText {
                    Text(routeText)
                        .font(TransferDesign.subtitleFont)
                        .foregroundStyle(TransferDesign.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)

            if !updatedAccounts.isEmpty {
                VStack(alignment: .leading, spacing: TransferDesign.textSpacing) {
                    Text("Новые балансы")
                        .font(TransferDesign.captionFont)
                        .foregroundStyle(TransferDesign.textSecondary)

                    VStack(alignment: .leading, spacing: TransferDesign.fieldSpacing) {
                        ForEach(updatedAccounts) { account in
                            TransferSuccessBalanceRow(account: account)
                        }
                    }
                    .padding(TransferDesign.cardPadding)
                    .transferCardBackground()
                }
            }

            // Spacer'а нет намеренно: высота шита считается по контенту
            // (TransferSheetHeight на месте вызова), поэтому корень должен
            // иметь СВОЮ высоту, а не растягиваться на весь экран.
            VStack(spacing: TransferDesign.fieldSpacing) {
                // Порядок кнопок — как в ТЗ 02 §3: «Готово» и «Открыть в истории».
                TransferPrimaryButton(title: "Готово", action: onDone)
                TransferSecondaryButton(title: "Открыть в истории", action: onOpenHistory)
            }
        }
        .padding(TransferDesign.sheetPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TransferDesign.screenBackground)
    }

    /// «Основной → Накопительный» (ТЗ 02 §3). Без обоих названий строку не собираем.
    private var routeText: String? {
        guard let sourceAccount, let destinationAccount else { return nil }
        return "\(sourceAccount.name) → \(destinationAccount.name)"
    }

    private var updatedAccounts: [Account] {
        [sourceAccount, destinationAccount].compactMap { $0 }
    }
}

/// Строка нового баланса: название счёта слева, баланс справа.
private struct TransferSuccessBalanceRow: View {
    let account: Account

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: TransferDesign.fieldSpacing) {
            Text(account.name)
                .font(TransferDesign.bodyFont)
                .foregroundStyle(TransferDesign.textPrimary)
            Spacer(minLength: TransferDesign.textSpacing)
            // Сумма набрана неразрывными пробелами и не переносится:
            // при нехватке ширины сжимается название, а не баланс.
            Text(MoneyFormatter.string(from: account.balance, currency: account.currency))
                .font(TransferDesign.bodySemiboldFont)
                .foregroundStyle(TransferDesign.textPrimary)
                .layoutPriority(1)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Успех — Основной → Накопительный") {
    // Балансы уже после перевода 5 000 ₽ (критерий приёмки ТЗ 02 §4):
    // 123 450,00 ₽ и 80 000,00 ₽.
    let source = MockData.accounts[0]
    let destination = MockData.accounts[1]

    TransferSuccessSheet(
        operation: Operation(
            id: UUID(),
            date: .now,
            kind: .transfer,
            sourceAccountID: source.id,
            destinationAccountID: destination.id,
            amount: 5_000,
            currency: .rub,
            comment: "Отложить на отпуск",
            status: .success,
            key: UUID()
        ),
        sourceAccount: Account(id: source.id, name: source.name,
                               maskedNumber: source.maskedNumber,
                               currency: source.currency, balance: 123_450),
        destinationAccount: Account(id: destination.id, name: destination.name,
                                    maskedNumber: destination.maskedNumber,
                                    currency: destination.currency, balance: 80_000),
        onOpenHistory: {},
        onDone: {}
    )
}

#Preview("Успех — счета недоступны") {
    TransferSuccessSheet(
        operation: Operation(
            id: UUID(),
            date: .now,
            kind: .transfer,
            sourceAccountID: MockData.accounts[0].id,
            destinationAccountID: MockData.accounts[1].id,
            amount: 5_000,
            currency: .rub,
            comment: nil,
            status: .success,
            key: UUID()
        ),
        sourceAccount: nil,
        destinationAccount: nil,
        onOpenHistory: {},
        onDone: {}
    )
}
