import Foundation

/// Единый формат денег на все три экрана: `128 450,00 ₽`.
/// Два знака после запятой, неразрывный пробел в разрядах,
/// символ валюты после суммы через неразрывный пробел.
enum MoneyFormatter {
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        // Разделители фиксируем явно, чтобы не зависеть от версии ICU.
        formatter.groupingSeparator = "\u{00A0}"
        formatter.decimalSeparator = ","
        return formatter
    }()

    static func string(from amount: Decimal, currency: Currency) -> String {
        let number = numberFormatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
        return number + "\u{00A0}" + currency.symbol
    }
}
