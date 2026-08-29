import SwiftUI

/// Строка выбора счёта «Откуда» / «Куда» (ТЗ 02 §3, макет `AccountPickerRow`).
/// Слева название и маскированный номер, справа баланс счёта; под строкой —
/// текст ошибки, если он есть.
///
/// Вью «глупое»: про `TransferViewModel` и `WalletStore` не знает — счета,
/// выбранное значение и ошибка приходят параметрами, выбор уходит через
/// `onSelect`. Так строку можно показать в превью на голых `MockData`.
struct TransferAccountPickerRow: View {
    /// Подпись над строкой: «Откуда» или «Куда».
    let title: String
    /// Выбранный счёт; `nil` — показывается плейсхолдер.
    let account: Account?
    /// Варианты выбора — все счета пользователя.
    let accounts: [Account]
    /// Текст на месте невыбранного счёта («Выберите счёт»).
    var placeholder: String = "Выберите счёт"
    /// Ошибка под строкой: «Счета должны быть разными» /
    /// «Перевод между счетами в разных валютах недоступен» (ТЗ 02 §3).
    var errorText: String?
    let onSelect: (Account) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TransferDesign.textSpacing) {
            Text(title)
                .font(TransferDesign.captionFont)
                .foregroundStyle(TransferDesign.textSecondary)

            // Menu, а не свой шит: нативный выбор из короткого списка,
            // без лишнего экрана и своей навигации.
            Menu {
                ForEach(accounts) { candidate in
                    Button {
                        onSelect(candidate)
                    } label: {
                        // Галочка у текущего выбора — стандартное поведение меню.
                        if candidate.id == account?.id {
                            Label(Self.subtitle(for: candidate), systemImage: "checkmark")
                        } else {
                            Text(Self.subtitle(for: candidate))
                        }
                    }
                }
            } label: {
                rowContent
            }

            if let errorText {
                Text(errorText)
                    .font(TransferDesign.captionFont)
                    .foregroundStyle(TransferDesign.negative)
            }
        }
    }

    private var rowContent: some View {
        HStack(spacing: TransferDesign.fieldSpacing) {
            if let account {
                // Две строки, как в AccountCardView на экране «Счета»: одной
                // строкой «Накопительный •• 8032» не помещался рядом с балансом
                // и переносился, причём вторая строка уезжала в центр —
                // label внутри Menu наследует центровку кнопки.
                VStack(alignment: .leading, spacing: TransferDesign.textSpacing) {
                    Text(account.name)
                        .font(TransferDesign.bodyFont)
                        .foregroundStyle(TransferDesign.textPrimary)
                    Text("\(account.maskedNumber) · \(account.currency.symbol)")
                        .font(TransferDesign.captionFont)
                        .foregroundStyle(TransferDesign.textSecondary)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(placeholder)
                    .font(TransferDesign.bodyFont)
                    .foregroundStyle(TransferDesign.textSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let account {
                // Баланс набран неразрывными пробелами и не переносится:
                // при нехватке ширины сжимается название счёта, а не сумма.
                Text(MoneyFormatter.string(from: account.balance, currency: account.currency))
                    .font(TransferDesign.bodySemiboldFont)
                    .foregroundStyle(TransferDesign.textPrimary)
                    .layoutPriority(1)
            }

            Image(systemName: "chevron.up.chevron.down")
                .font(TransferDesign.captionFont)
                .foregroundStyle(TransferDesign.textSecondary)
        }
        .padding(TransferDesign.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .transferFieldBackground()
        // VoiceOver читает строку целиком: «Основной •• 4417, 128 450,00 ₽».
        .accessibilityElement(children: .combine)
    }

    /// «Основной •• 4417» — название и маскированный номер одной строкой.
    private static func subtitle(for account: Account) -> String {
        "\(account.name) \(account.maskedNumber)"
    }
}

#Preview("Выбран счёт") {
    TransferAccountPickerRow(title: "Откуда",
                             account: MockData.accounts[0],
                             accounts: MockData.accounts) { _ in }
        .padding(.horizontal, TransferDesign.screenHPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TransferDesign.screenBackground)
}

#Preview("Счёт не выбран") {
    TransferAccountPickerRow(title: "Куда",
                             account: nil,
                             accounts: MockData.accounts) { _ in }
        .padding(.horizontal, TransferDesign.screenHPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TransferDesign.screenBackground)
}

#Preview("С ошибкой") {
    TransferAccountPickerRow(title: "Куда",
                             account: MockData.accounts[2],
                             accounts: MockData.accounts,
                             errorText: "Перевод между счетами в разных валютах недоступен") { _ in }
        .padding(.horizontal, TransferDesign.screenHPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TransferDesign.screenBackground)
}
