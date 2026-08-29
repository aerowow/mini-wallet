import SwiftUI

/// Шит повтора уже выполненного перевода: состояние «Повтор уже выполненного
/// перевода» (ТЗ 02 §3), макет — фрейм 09.
///
/// `operation` — ПЕРВОНАЧАЛЬНАЯ операция из стора: повторный вызов с тем же ключом
/// новую не создаёт (ТЗ 02 §1). Счета приходят с НЕизменёнными балансами —
/// шит показывает их явно, чтобы было видно: повторно деньги не списаны.
///
/// Иконка нейтральная, не красная: это не ошибка, а нормальный исход
/// идемпотентного повтора (ТЗ 02 §3 требует этого прямо).
struct TransferDuplicateSheet: View {
    let operation: Operation
    let sourceAccount: Account?
    let destinationAccount: Account?
    let onOpenHistory: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TransferDesign.sectionSpacing) {
            VStack(spacing: TransferDesign.fieldSpacing) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: TransferDesign.sheetIconSize))
                    .foregroundStyle(TransferDesign.textSecondary)
                    .accessibilityHidden(true)

                Text("Перевод уже выполнен")
                    .font(TransferDesign.sheetTitleFont)
                    .foregroundStyle(TransferDesign.textPrimary)

                Text("Эта операция была выполнена ранее, повторно деньги не списаны")
                    .font(TransferDesign.subtitleFont)
                    .foregroundStyle(TransferDesign.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)

            // Карточка первоначальной операции: дата, время, сумма, счета.
            VStack(alignment: .leading, spacing: TransferDesign.fieldSpacing) {
                TransferDuplicateRow(label: "Дата и время",
                                     value: TransferDuplicateDateFormat.string(from: operation.date))
                TransferDuplicateRow(
                    label: "Сумма",
                    value: MoneyFormatter.string(from: operation.amount, currency: operation.currency),
                    isProminent: true
                )
                if let sourceAccount {
                    TransferDuplicateRow(label: "Откуда", value: Self.accountText(sourceAccount))
                }
                if let destinationAccount {
                    TransferDuplicateRow(label: "Куда", value: Self.accountText(destinationAccount))
                }
            }
            .padding(TransferDesign.cardPadding)
            .transferCardBackground()

            if !unchangedAccounts.isEmpty {
                VStack(alignment: .leading, spacing: TransferDesign.textSpacing) {
                    Text("Балансы не изменились")
                        .font(TransferDesign.captionFont)
                        .foregroundStyle(TransferDesign.textSecondary)

                    VStack(alignment: .leading, spacing: TransferDesign.fieldSpacing) {
                        ForEach(unchangedAccounts) { account in
                            TransferDuplicateBalanceRow(account: account)
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
                // ТЗ 02 §3 перечисляет кнопки этого шита как «Открыть в истории»
                // и «Готово», а у шита успеха — наоборот. Вертикальный порядок
                // выровнен по успеху: два почти одинаковых шита с переставленными
                // кнопками ломают мышечную память — рука попадает в другое действие.
                // Расхождение с порядком перечисления в ТЗ — осознанное.
                TransferPrimaryButton(title: "Готово", action: onDone)
                TransferSecondaryButton(title: "Открыть в истории", action: onOpenHistory)
            }
        }
        .padding(TransferDesign.sheetPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TransferDesign.screenBackground)
    }

    private var unchangedAccounts: [Account] {
        [sourceAccount, destinationAccount].compactMap { $0 }
    }

    private static func accountText(_ account: Account) -> String {
        "\(account.name) \(account.maskedNumber)"
    }
}

/// Дата и время первоначальной операции: «29 августа 2026, 14:32».
/// Свой форматтер, а не общий с историей: `Features/History/` — чужая зона,
/// ходить туда за кодом нельзя (CLAUDE.md, карта владения).
private enum TransferDuplicateDateFormat {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        // Локаль фиксируем явно: тексты интерфейса русские независимо
        // от системных настроек устройства.
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy, HH:mm"
        return formatter
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }
}

/// Строка «подпись — значение» карточки первоначальной операции.
private struct TransferDuplicateRow: View {
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
        .accessibilityElement(children: .combine)
    }
}

/// Строка неизменённого баланса счёта.
private struct TransferDuplicateBalanceRow: View {
    let account: Account

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: TransferDesign.fieldSpacing) {
            Text(account.name)
                .font(TransferDesign.bodyFont)
                .foregroundStyle(TransferDesign.textPrimary)
            Spacer(minLength: TransferDesign.textSpacing)
            Text(MoneyFormatter.string(from: account.balance, currency: account.currency))
                .font(TransferDesign.bodySemiboldFont)
                .foregroundStyle(TransferDesign.textPrimary)
                .layoutPriority(1)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Повтор — первоначальная операция") {
    // Балансы — стартовые из MockData: повторный вызов их не менял (ТЗ 02 §3).
    let source = MockData.accounts[0]
    let destination = MockData.accounts[1]

    TransferDuplicateSheet(
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
        sourceAccount: source,
        destinationAccount: destination,
        onOpenHistory: {},
        onDone: {}
    )
}

#Preview("Повтор — счета недоступны") {
    TransferDuplicateSheet(
        operation: Operation(
            id: UUID(),
            date: .now,
            kind: .transfer,
            sourceAccountID: MockData.accounts[0].id,
            destinationAccountID: MockData.accounts[1].id,
            amount: 1_500,
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
