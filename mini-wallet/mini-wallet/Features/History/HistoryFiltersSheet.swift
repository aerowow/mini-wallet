import SwiftUI

/// Шит выбора фильтров истории.
/// Правки здесь — черновые: пока не нажато «Применить», список и чипы
/// не меняются, поэтому закрытие свайпом ничего не сохраняет (ТЗ 03).
/// Про HistoryViewModel и WalletStore шит не знает: счета приходят
/// параметром, результат уходит через onApply.
struct HistoryFiltersSheet: View {
    private let accounts: [Account]
    private let onApply: (HistoryFilters) -> Void

    /// Черновик. Инициализируется текущими применёнными фильтрами:
    /// при открытии шит показывает то, что уже выбрано в чипах.
    @State private var draft: HistoryFilters

    @Environment(\.dismiss) private var dismiss

    private static let typeOptions: [HistoryTypeFilter] = [.all, .incoming, .outgoing]
    private static let periodOptions: [HistoryPeriodFilter] = [.today, .last7Days, .last30Days, .allTime]

    init(initial: HistoryFilters,
         accounts: [Account],
         onApply: @escaping (HistoryFilters) -> Void) {
        self.accounts = accounts
        self.onApply = onApply
        _draft = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Тип — одно значение: выбор здесь и в чипах всегда совпадает.
                    Picker("Тип операции", selection: $draft.type) {
                        ForEach(Self.typeOptions, id: \.self) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section {
                    Picker("Счёт", selection: $draft.account) {
                        Text("Все").tag(HistoryAccountFilter.all)
                        ForEach(accounts) { account in
                            Text(account.name).tag(HistoryAccountFilter.account(account.id))
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section {
                    Picker("Период", selection: $draft.period) {
                        ForEach(Self.periodOptions, id: \.self) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // Сбрасывает только черновик — применится по «Применить».
                    Button("Сбросить") {
                        draft = HistoryFilters()
                    }
                    .disabled(draft == HistoryFilters())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Применить") {
                        onApply(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview("Шит — фильтры по умолчанию") {
    HistoryFiltersSheet(initial: HistoryFilters(), accounts: MockData.accounts) { _ in }
}

#Preview("Шит — фильтры применены") {
    HistoryFiltersSheet(
        initial: HistoryFilters(type: .outgoing,
                                account: .account(MockData.accounts[1].id),
                                period: .last30Days),
        accounts: MockData.accounts
    ) { _ in }
}
