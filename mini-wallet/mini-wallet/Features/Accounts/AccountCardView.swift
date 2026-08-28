import SwiftUI

/// Карточка одного счёта: имя и маскированный номер слева, баланс справа.
/// Высота не фиксируется — складывается из паддингов и двух строк текста.
struct AccountCardView: View {
    let account: Account

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(AccountsDesign.bodyFont)
                    .foregroundStyle(AccountsDesign.textPrimary)
                Text("\(account.maskedNumber) · \(account.currency.symbol)")
                    .font(AccountsDesign.captionFont)
                    .foregroundStyle(AccountsDesign.textSecondary)
            }
            Spacer(minLength: 12)
            Text(MoneyFormatter.string(from: account.balance, currency: account.currency))
                .font(AccountsDesign.bodySemiboldFont)
                .foregroundStyle(AccountsDesign.textPrimary)
        }
        .padding(AccountsDesign.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accountsCardBackground()
    }
}

#Preview {
    AccountCardView(account: MockData.accounts[0])
        .padding(.horizontal, AccountsDesign.screenHPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AccountsDesign.screenBackground)
}
