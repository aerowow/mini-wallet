import SwiftUI

/// Корневой TabView. Ссылается на фиксированные имена экранов
/// AccountsScreen / TransferScreen / HistoryScreen и после мержа
/// core/shell не правится.
struct RootTabView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            Tab("Счета", systemImage: "creditcard", value: AppTab.accounts) {
                AccountsScreen()
            }
            Tab("Перевод", systemImage: "arrow.left.arrow.right", value: AppTab.transfer) {
                TransferScreen()
            }
            Tab("История", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                HistoryScreen()
            }
        }
    }
}

#Preview {
    RootTabView()
        .environment(WalletStore())
        .environment(AppRouter())
}
