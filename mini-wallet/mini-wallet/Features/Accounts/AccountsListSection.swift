import SwiftUI

/// Секция «Мои счета»: заголовок и вертикальный список карточек.
/// Данные приходят параметром, порядок счетов сохраняется как передан.
struct AccountsListSection: View {
    let accounts: [Account]

    var body: some View {
        VStack(alignment: .leading, spacing: AccountsDesign.cardSpacing) {
            Text("Мои счета")
                .font(AccountsDesign.bodySemiboldFont)
                .foregroundStyle(AccountsDesign.textPrimary)
            ForEach(accounts) { account in
                AccountCardView(account: account)
            }
        }
    }
}

#Preview {
    AccountsListSection(accounts: MockData.accounts)
        .padding(.horizontal, AccountsDesign.screenHPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AccountsDesign.screenBackground)
}
