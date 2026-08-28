import SwiftUI

/// Строка списка истории (ТЗ 03, «UI и состояния» и «Суммы»).
/// Без карточки-обёртки: строки разделяет сепаратор самого List.
@MainActor
struct OperationRow: View {
    let operation: Operation

    /// Имена счетов берём из общего стора: в операции лежат только id.
    @Environment(WalletStore.self) private var store

    /// Время в подписи: «14:32».
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.body)
                // Иконка всегда нейтральная: красный в строке зарезервирован за бейджем ошибки.
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .lineLimit(1)
                    // Название счёта в заголовке важнее свободного места:
                    // на узком экране лучше слегка ужать, чем обрезать «Накопите…».
                    .minimumScaleFactor(0.75)

                HStack(spacing: 6) {
                    if isFailed {
                        errorBadge
                    }
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            // Текстовая колонка забирает остаток ширины у Spacer, а не у суммы.
            .layoutPriority(1)

            Spacer(minLength: 8)

            Text(amountText)
                .font(.body.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(amountColor)
                .lineLimit(1)
                // Сумма не сжимается и не переносится ни при какой длине названий.
                .fixedSize()
        }
        .padding(.vertical, 6)
        .frame(minHeight: 44)
        // Нажатие ловит вся строка, а не только текст.
        .contentShape(.rect)
    }

    private var errorBadge: some View {
        Text("Ошибка")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.red)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(.red.opacity(0.12)))
            .overlay(Capsule().strokeBorder(.red.opacity(0.35)))
    }

    // MARK: - Содержимое

    private var isFailed: Bool {
        if case .failed = operation.status { return true }
        return false
    }

    /// Перевод — «Основной → Накопительный», пополнение — «Пополнение: Основной».
    private var title: String {
        let destination = accountName(operation.destinationAccountID)
        guard let sourceAccountID = operation.sourceAccountID else {
            return "Пополнение: \(destination)"
        }
        return "\(accountName(sourceAccountID)) → \(destination)"
    }

    /// Счёт может не найтись только при рассинхроне моков — показываем заглушку,
    /// строка остаётся читаемой.
    private func accountName(_ id: UUID) -> String {
        store.account(id: id)?.name ?? "Неизвестный счёт"
    }

    /// У неуспешной операции вместо комментария — причина ошибки (ТЗ 03).
    private var subtitle: String {
        let time = Self.timeFormatter.string(from: operation.date)
        if case .failed(let reason) = operation.status {
            return "\(reason.shortText) · \(time)"
        }
        if let comment = operation.comment, !comment.isEmpty {
            return "\(comment) · \(time)"
        }
        return time
    }

    private var iconName: String {
        operation.direction == .incoming ? "arrow.down.left" : "arrow.up.right"
    }

    /// Знак ставим только для успешных: по неуспешной деньги не списаны (ТЗ 03),
    /// поэтому проверка статуса идёт раньше направления.
    private var amountText: String {
        let amount = MoneyFormatter.string(from: operation.amount, currency: operation.currency)
        if isFailed { return amount }
        // U+2212 MINUS SIGN: типографский минус, а не дефис.
        return (operation.direction == .incoming ? "+" : "\u{2212}") + amount
    }

    private var amountColor: Color {
        // Зелёный — только у входящих; у неуспешной цвет нейтральный, красный
        // остаётся признаком ошибки на бейдже.
        if isFailed { return .primary }
        return operation.direction == .incoming ? .green : .primary
    }
}

#Preview("Строка операции") {
    let store = WalletStore()
    let main = store.accounts[0].id
    let savings = store.accounts[1].id
    let currencyAccount = store.accounts[2].id

    List {
        OperationRow(operation: Operation(
            id: UUID(), date: .now, kind: .transfer,
            sourceAccountID: main, destinationAccountID: savings,
            amount: 5_000, currency: .rub,
            comment: "Отложить на отпуск", status: .success, key: nil))

        OperationRow(operation: Operation(
            id: UUID(), date: .now, kind: .deposit,
            sourceAccountID: nil, destinationAccountID: main,
            amount: 32_000, currency: .rub,
            comment: "Зарплата", status: .success, key: nil))

        OperationRow(operation: Operation(
            id: UUID(), date: .now, kind: .transfer,
            sourceAccountID: main, destinationAccountID: currencyAccount,
            amount: 10_000, currency: .rub,
            comment: nil, status: .failed(reason: .differentCurrencies), key: nil))
    }
    .environment(store)
}
