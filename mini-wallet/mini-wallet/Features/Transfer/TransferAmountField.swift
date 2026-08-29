import SwiftUI

/// Поле «Сумма» в валюте счёта-источника (ТЗ 02 §3, макет `AmountField`):
/// ввод, символ валюты справа, под полем подпись «Доступно: …»
/// и текст ошибки валидации.
///
/// Вью «глупое»: нормализацию ввода и тексты ошибок считает вьюмодель,
/// сюда приходят готовые значения. Ничего в тексте не фильтрует —
/// иначе фильтрация была бы в двух местах и разъехалась.
struct TransferAmountField: View {
    @Binding var text: String
    /// Валюта счёта «Откуда»; `nil` — счёт не выбран, символ не показываем.
    let currency: Currency?
    /// Баланс счёта «Откуда» для подписи «Доступно: …».
    /// «Доступно» в MVP — это и есть баланс (ТЗ 02 §2).
    let availableBalance: Decimal?
    /// «Недостаточно средств» / «Введите сумму больше нуля» (ТЗ 02 §3).
    var errorText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: TransferDesign.textSpacing) {
            Text("Сумма")
                .font(TransferDesign.captionFont)
                .foregroundStyle(TransferDesign.textSecondary)

            HStack(spacing: TransferDesign.fieldSpacing) {
                TextField("0", text: $text)
                    // Клавиатура без букв: в поле осмысленны только цифры
                    // и разделитель дробной части.
                    .keyboardType(.decimalPad)
                    .font(TransferDesign.bodyFont)
                    .foregroundStyle(TransferDesign.textPrimary)

                if let currency {
                    Text(currency.symbol)
                        .font(TransferDesign.bodySemiboldFont)
                        .foregroundStyle(TransferDesign.textSecondary)
                }
            }
            .padding(TransferDesign.cardPadding)
            .transferFieldBackground()

            if let availableBalance, let currency {
                Text("Доступно: \(MoneyFormatter.string(from: availableBalance, currency: currency))")
                    .font(TransferDesign.captionFont)
                    .foregroundStyle(TransferDesign.textSecondary)
            }

            if let errorText {
                Text(errorText)
                    .font(TransferDesign.captionFont)
                    .foregroundStyle(TransferDesign.negative)
            }
        }
    }
}

#Preview("Пустое поле") {
    @Previewable @State var text = ""
    TransferAmountField(text: $text,
                        currency: MockData.accounts[0].currency,
                        availableBalance: MockData.accounts[0].balance)
        .padding(.horizontal, TransferDesign.screenHPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TransferDesign.screenBackground)
}

#Preview("Заполнено") {
    @Previewable @State var text = "5000"
    TransferAmountField(text: $text,
                        currency: MockData.accounts[0].currency,
                        availableBalance: MockData.accounts[0].balance)
        .padding(.horizontal, TransferDesign.screenHPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TransferDesign.screenBackground)
}

#Preview("Ошибка") {
    @Previewable @State var text = "999999"
    TransferAmountField(text: $text,
                        currency: MockData.accounts[0].currency,
                        availableBalance: MockData.accounts[0].balance,
                        errorText: "Недостаточно средств")
        .padding(.horizontal, TransferDesign.screenHPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TransferDesign.screenBackground)
}
