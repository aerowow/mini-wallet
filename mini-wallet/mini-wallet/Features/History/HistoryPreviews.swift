import SwiftUI

// Превью экрана «История» в состояниях из ТЗ 03 и макета (фреймы 12–14).
// Данные — только MockData из Core: свои моки развели бы превью с приложением.

/// Вьюмодель с уже введённым запросом. Тело #Preview — это ViewBuilder,
/// императивной подготовке там не место, поэтому она вынесена сюда.
@MainActor
private func previewViewModel(searchText: String) -> HistoryViewModel {
    let viewModel = HistoryViewModel()
    viewModel.searchText = searchText
    return viewModel
}

#Preview("История — список") {
    HistoryScreen()
        .environment(WalletStore())
        .environment(AppRouter())
}

// «такси» не встречается ни в одном комментарии — запрос из критерия приёмки ТЗ 03.
#Preview("История — ничего не найдено") {
    HistoryScreen(viewModel: previewViewModel(searchText: "такси"))
        .environment(WalletStore())
        .environment(AppRouter())
}

#Preview("История — нет операций") {
    HistoryScreen()
        .environment(WalletStore(accounts: MockData.accounts, operations: []))
        .environment(AppRouter())
}

#Preview("Пустое состояние — ничего не найдено") {
    HistoryNothingFoundView(onReset: {})
}

#Preview("Пустое состояние — нет операций") {
    HistoryNoOperationsView()
        .environment(AppRouter())
}
