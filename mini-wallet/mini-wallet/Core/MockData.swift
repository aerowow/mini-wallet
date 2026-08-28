import Foundation

/// Стартовые мок-данные из ТЗ (docs/specs/01-accounts.md, 03-history.md).
/// Балансы счетов и история задаются независимо: история — пример последних
/// операций, а не реестр, из которого рассчитываются балансы.
enum MockData {
    // Фиксированные id, чтобы операции могли ссылаться на счета.
    private static let mainAccountID = UUID()
    private static let savingsAccountID = UUID()
    private static let currencyAccountID = UUID()

    static let accounts: [Account] = [
        Account(id: mainAccountID, name: "Основной", maskedNumber: "•• 4417",
                currency: .rub, balance: 128_450),
        Account(id: savingsAccountID, name: "Накопительный", maskedNumber: "•• 8032",
                currency: .rub, balance: 75_000),
        Account(id: currencyAccountID, name: "Валютный", maskedNumber: "•• 1195",
                currency: .usd, balance: Decimal(string: "1240.50")!),
    ]

    /// Семь операций из ТЗ истории. Даты — относительно текущего дня
    /// (смещения 0/0/1/1/2/2/4), чтобы группы «Сегодня» и «Вчера» не устаревали.
    static let operations: [Operation] = [
        Operation(id: UUID(), date: date(daysAgo: 0, hour: 14, minute: 32),
                  kind: .transfer, sourceAccountID: mainAccountID,
                  destinationAccountID: savingsAccountID, amount: 5_000, currency: .rub,
                  comment: "Отложить на отпуск", status: .success, key: nil),
        Operation(id: UUID(), date: date(daysAgo: 0, hour: 11, minute: 5),
                  kind: .transfer, sourceAccountID: mainAccountID,
                  destinationAccountID: currencyAccountID, amount: 10_000, currency: .rub,
                  comment: nil, status: .failed(reason: .differentCurrencies), key: nil),
        Operation(id: UUID(), date: date(daysAgo: 1, hour: 19, minute: 48),
                  kind: .deposit, sourceAccountID: nil,
                  destinationAccountID: mainAccountID, amount: 32_000, currency: .rub,
                  comment: "Зарплата", status: .success, key: nil),
        Operation(id: UUID(), date: date(daysAgo: 1, hour: 9, minute: 12),
                  kind: .transfer, sourceAccountID: savingsAccountID,
                  destinationAccountID: mainAccountID, amount: 1_500, currency: .rub,
                  comment: "Продукты", status: .success, key: nil),
        Operation(id: UUID(), date: date(daysAgo: 2, hour: 21, minute: 3),
                  kind: .transfer, sourceAccountID: mainAccountID,
                  destinationAccountID: savingsAccountID, amount: 12_000, currency: .rub,
                  comment: nil, status: .success, key: nil),
        Operation(id: UUID(), date: date(daysAgo: 2, hour: 8, minute: 40),
                  kind: .deposit, sourceAccountID: nil,
                  destinationAccountID: savingsAccountID, amount: 7_000, currency: .rub,
                  comment: "Кэшбэк", status: .success, key: nil),
        Operation(id: UUID(), date: date(daysAgo: 4, hour: 16, minute: 20),
                  kind: .transfer, sourceAccountID: mainAccountID,
                  destinationAccountID: savingsAccountID, amount: 3_200, currency: .rub,
                  comment: "Резерв", status: .success, key: nil),
    ]

    private static func date(daysAgo: Int, hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: -daysAgo,
                                to: calendar.startOfDay(for: .now)) ?? .now
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }
}
