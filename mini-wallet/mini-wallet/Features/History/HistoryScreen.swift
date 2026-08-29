import SwiftUI

/// Экран «История» (ТЗ 03): операции стора, сгруппированные по дням,
/// с поиском и быстрыми фильтрами. Только чтение: операции отсюда
/// не создаются, не редактируются и не удаляются.
/// Имя типа зафиксировано: на него ссылается RootTabView.
struct HistoryScreen: View {
    @Environment(WalletStore.self) private var store

    /// Вьюмодель принимается снаружи только ради превью состояний
    /// (например, «ничего не найдено» с заранее введённым запросом).
    @State private var viewModel: HistoryViewModel

    init(viewModel: HistoryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    /// Отдельный init вместо значения по умолчанию: выражение дефолтного
    /// аргумента вычисляется вне MainActor, а HistoryViewModel им изолирован.
    init() {
        self.init(viewModel: HistoryViewModel())
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.operations.isEmpty {
                    // Пустая история: поиск и чипы скрыты целиком (ТЗ 03).
                    HistoryNoOperationsView()
                } else {
                    operationsContent
                }
            }
            .navigationTitle("История")
            .sheet(isPresented: $viewModel.isFiltersSheetPresented) {
                // Шит работает с черновиком: применённые фильтры меняет только
                // «Применить», закрытие свайпом ничего не сохраняет (ТЗ 03).
                HistoryFiltersSheet(initial: viewModel.filters,
                                    accounts: store.accounts) { applied in
                    viewModel.apply(applied)
                }
            }
        }
    }

    private var operationsContent: some View {
        // Порядок стора сохраняется: вьюмодель только фильтрует,
        // группировка режет уже готовую последовательность на дни.
        let sections = HistoryGrouping.sections(from: viewModel.visibleOperations(in: store))

        return VStack(spacing: 12) {
            HistoryFilterChips(viewModel: viewModel)

            if sections.isEmpty {
                // Кнопка чистит и запрос, и фильтры — возвращает полный список (ТЗ 03).
                HistoryNothingFoundView { viewModel.resetAll() }
                    .frame(maxHeight: .infinity)
            } else {
                // ScrollView + LazyVStack(pinnedViews:), а не List: у List
                // закреплённый заголовок дня оказывается ПОД уезжающими строками
                // и они его перечёркивают. Здесь заголовок рисуется поверх,
                // с непрозрачным фоном — липкость из ТЗ 03 сохраняется.
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0,
                               pinnedViews: [.sectionHeaders]) {
                        ForEach(sections) { section in
                            Section {
                                ForEach(section.operations) { operation in
                                    OperationRow(operation: operation)
                                        .padding(.horizontal, 16)
                                    // Сепаратор рисуем сами: List здесь не используется.
                                    Divider()
                                        .padding(.leading, 56)
                                }
                            } header: {
                                sectionHeader(section.title)
                            }
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
        .searchable(text: $viewModel.searchText,
                    prompt: "Поиск по комментарию и сумме")
    }

    /// Липкий заголовок дня. Свой фон обязателен: у прозрачного заголовка
    /// при прокрутке сквозь него просвечивают строки списка.
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
    }
}
