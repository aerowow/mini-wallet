import SwiftUI

/// Ряд быстрых фильтров над списком истории.
/// «Все» / «Входящие» / «Исходящие» применяются сразу, «Счёт» и «Период»
/// только открывают шит — презентует его HistoryScreen (ТЗ 03, «Фильтры»).
struct HistoryFilterChips: View {
    @Bindable var viewModel: HistoryViewModel

    /// Нужен единственно ради подписи чипа «Счёт» именем выбранного счёта.
    /// Опциональный: без стора в окружении чип остаётся с общим заголовком,
    /// а не роняет превью.
    @Environment(WalletStore.self) private var store: WalletStore?

    private var chipsScroll: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                // Верхний «Все» — это одновременно значение типа и сброс всех
                // трёх групп; поисковый запрос при этом сохраняется (таблица ТЗ 03).
                chip(title: HistoryTypeFilter.all.title,
                     isSelected: viewModel.filters.type == .all) {
                    viewModel.resetFilters()
                }
                chip(title: HistoryTypeFilter.incoming.title,
                     isSelected: viewModel.filters.type == .incoming) {
                    viewModel.selectType(.incoming)
                }
                chip(title: HistoryTypeFilter.outgoing.title,
                     isSelected: viewModel.filters.type == .outgoing) {
                    viewModel.selectType(.outgoing)
                }

                chip(title: accountChipTitle,
                     systemImage: "creditcard",
                     isSelected: viewModel.filters.account != .all) {
                    viewModel.isFiltersSheetPresented = true
                }
                chip(title: periodChipTitle,
                     systemImage: "calendar",
                     isSelected: viewModel.filters.period != .allTime) {
                    viewModel.isFiltersSheetPresented = true
                }

            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
    }

    var body: some View {
        HStack(spacing: 8) {
            chipsScroll

            // Счётчик и «Сбросить» вынесены из горизонтального скролла:
            // внутри ряда они уезжали за правый край и пользователь их не видел,
            // хотя ТЗ 03 требует показывать их рядом с активными фильтрами.
            if viewModel.hasActiveFilters {
                Divider()
                    .frame(height: 20)
                counter
                resetButton
                    .padding(.trailing, 16)
            }
        }
    }

    // MARK: - Части ряда

    /// Счётчик изменённых групп фильтров; поиск в него не входит (ТЗ 03).
    private var counter: some View {
        Text("\(viewModel.activeFilterCount)")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .frame(minWidth: 24, minHeight: 24)
            .background(Color.accentColor.opacity(0.15), in: .circle)
            .accessibilityLabel("Активных фильтров: \(viewModel.activeFilterCount)")
    }

    /// «Сбросить» рядом с чипами: только фильтры, поиск остаётся.
    private var resetButton: some View {
        Button("Сбросить") {
            viewModel.resetFilters()
        }
        .font(.subheadline.weight(.medium))
        .frame(minHeight: 44)
        .contentShape(.rect)
    }

    // MARK: - Подписи

    /// На чипе показываем выбранное значение, иначе — имя группы.
    private var accountChipTitle: String {
        guard case .account(let accountID) = viewModel.filters.account else { return "Счёт" }
        return store?.account(id: accountID)?.name ?? "Счёт"
    }

    private var periodChipTitle: String {
        viewModel.filters.period == .allTime ? "Период" : viewModel.filters.period.title
    }

    // MARK: - Капсула

    private func chip(title: String,
                      systemImage: String? = nil,
                      isSelected: Bool,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .imageScale(.small)
                }
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemFill), in: .capsule)
            // Капсула остаётся 36, но зона нажатия — не меньше 44.
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview("Чипы — фильтры не активны") {
    @Previewable @State var store = WalletStore()
    @Previewable @State var viewModel = HistoryViewModel()

    HistoryFilterChips(viewModel: viewModel)
        .environment(store)
}

#Preview("Чипы — фильтры активны") {
    @Previewable @State var store = WalletStore()
    @Previewable @State var viewModel = HistoryViewModel()

    HistoryFilterChips(viewModel: viewModel)
        .environment(store)
        .onAppear {
            viewModel.apply(
                HistoryFilters(type: .incoming,
                               account: .account(store.accounts[1].id),
                               period: .last7Days)
            )
        }
}
