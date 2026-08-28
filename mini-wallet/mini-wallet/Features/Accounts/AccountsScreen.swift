import SwiftUI

/// Экран «Счета»: сводный баланс, список счетов и переход к переводу.
/// Имя типа и init без параметров зафиксированы — на них ссылается RootTabView.
/// Заголовок — кастомный текст 28pt, как в макете (NavigationStack не нужен:
/// навигации с экрана нет, системный large title выглядел бы иначе).
struct AccountsScreen: View {
    @Environment(WalletStore.self) private var store
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: AccountsDesign.sectionSpacing) {
            Text("Счета")
                .font(AccountsDesign.titleFont)
                .foregroundStyle(AccountsDesign.textPrimary)

            if store.accounts.isEmpty {
                Spacer()
                AccountsEmptyStateView()
                Spacer()
            } else {
                AccountsSummaryView()
                AccountsListSection(accounts: store.accounts)
                Spacer(minLength: AccountsDesign.cardPadding)
            }

            AccountsPrimaryButton(title: "Перевести") {
                router.selectedTab = .transfer
            }
            .disabled(store.accounts.isEmpty)
        }
        .padding(.horizontal, AccountsDesign.screenHPadding)
        .padding(.top, AccountsDesign.cardPadding)
        .padding(.bottom, AccountsDesign.cardSpacing)
        .background(AccountsDesign.screenBackground.ignoresSafeArea())
        // Потолок Dynamic Type: вёрстка фиксированная, без ScrollView,
        // на бо́льших размерах контент перестал бы помещаться.
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }
}

#Preview("Обычное состояние") {
    AccountsScreen()
        .environment(WalletStore())
        .environment(AppRouter())
}

#Preview("Нет счетов") {
    AccountsScreen()
        .environment(WalletStore(accounts: [], operations: []))
        .environment(AppRouter())
}
