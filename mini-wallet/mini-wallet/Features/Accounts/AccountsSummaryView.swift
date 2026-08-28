import SwiftUI

/// Карточка сводного баланса «Всего» на экране «Счета».
/// Показывает готовую сумму рублёвых счетов из WalletStore.totalRubBalance;
/// сноска про валютный счёт — прямое требование ТЗ (в PDF-макете её нет,
/// расхождение сознательно решено в пользу ТЗ).
/// Скрытие карточки при пустом сторе — зона композиции экрана, не этой вью.
struct AccountsSummaryView: View {
    @Environment(WalletStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Всего")
                .font(AccountsDesign.captionFont)
                .foregroundStyle(AccountsDesign.textSecondary)
            Text(MoneyFormatter.string(from: store.totalRubBalance, currency: .rub))
                .font(AccountsDesign.amountLargeFont)
                .foregroundStyle(AccountsDesign.textPrimary)
            Text("Валютный счёт не входит в сумму")
                .font(AccountsDesign.captionFont)
                .foregroundStyle(AccountsDesign.textSecondary)
        }
        .padding(AccountsDesign.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accountsCardBackground()
    }
}

#Preview {
    AccountsSummaryView()
        .padding(.horizontal, AccountsDesign.screenHPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AccountsDesign.screenBackground)
        .environment(WalletStore())
}
