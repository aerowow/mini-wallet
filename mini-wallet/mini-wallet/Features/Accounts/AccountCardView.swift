import SwiftUI

/// Карточка одного счёта: имя и маскированный номер слева, баланс справа.
/// Высота не фиксируется — складывается из паддингов и двух строк текста.
struct AccountCardView: View {
    let account: Account

    var body: some View {
        HStack(spacing: AccountsDesign.cardSpacing) {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(AccountsDesign.bodyFont)
                    .foregroundStyle(AccountsDesign.textPrimary)
                Text("\(account.maskedNumber) · \(account.currency.symbol)")
                    .font(AccountsDesign.captionFont)
                    .foregroundStyle(AccountsDesign.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // Сумма набрана неразрывными пробелами и не переносится —
            // при нехватке ширины сжимается имя, а не баланс.
            Text(MoneyFormatter.string(from: account.balance, currency: account.currency))
                .font(AccountsDesign.bodySemiboldFont)
                .foregroundStyle(AccountsDesign.textPrimary)
                .layoutPriority(1)
        }
        .padding(AccountsDesign.cardPadding)
        .accountsCardBackground()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    AccountCardView(account: MockData.accounts[0])
        .padding(.horizontal, AccountsDesign.screenHPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AccountsDesign.screenBackground)
}
