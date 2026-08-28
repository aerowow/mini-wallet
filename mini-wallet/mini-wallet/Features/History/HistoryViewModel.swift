import Foundation
import Observation

/// Фильтр по направлению операции (ТЗ 03: пополнения — входящие,
/// любые переводы, включая неуспешный, — исходящие).
enum HistoryTypeFilter: Hashable {
    case all
    case incoming
    case outgoing

    /// Один и тот же текст в чипах и в шите: выбор типа там всегда совпадает.
    var title: String {
        switch self {
        case .all: "Все"
        case .incoming: "Входящие"
        case .outgoing: "Исходящие"
        }
    }
}

/// Фильтр по счёту: операция подходит, если счёт — источник ИЛИ получатель.
enum HistoryAccountFilter: Hashable {
    case all
    case account(UUID)
}

/// Фильтр по периоду. Границы считаются календарно от начала текущего дня,
/// а не вычитанием секунд: иначе «Сегодня» ломается на границе суток.
enum HistoryPeriodFilter: Hashable {
    case allTime
    case today
    case last7Days
    case last30Days

    var title: String {
        switch self {
        case .allTime: "Всё время"
        case .today: "Сегодня"
        case .last7Days: "7 дней"
        case .last30Days: "30 дней"
        }
    }
}

/// Три независимые группы фильтров. Значение по умолчанию у каждой — «всё»,
/// поэтому `HistoryFilters()` — это состояние «фильтры не активны».
struct HistoryFilters: Hashable {
    var type: HistoryTypeFilter = .all
    var account: HistoryAccountFilter = .all
    var period: HistoryPeriodFilter = .allTime

    /// Число изменённых групп из трёх — то, что показывает счётчик рядом с чипами.
    /// Поисковый запрос в счётчик не входит (ТЗ 03, «Фильтры»).
    var changedGroupCount: Int {
        var count = 0
        if type != .all { count += 1 }
        if account != .all { count += 1 }
        if period != .allTime { count += 1 }
        return count
    }
}

/// Состояние экрана «История»: поисковый запрос, применённые фильтры и показ шита.
/// Данные не хранит — операции берутся из WalletStore на каждый вызов
/// `visibleOperations(in:)`, поэтому новый перевод появляется в списке сразу.
@MainActor
@Observable
final class HistoryViewModel {
    /// Текст поиска. Ищем только по комментарию и сумме (ТЗ 03, «Поиск»).
    var searchText: String = ""

    /// Показ шита фильтров; сам шит презентует HistoryScreen.
    var isFiltersSheetPresented = false

    /// Применённые фильтры. Меняются только через selectType/apply/reset*,
    /// чтобы черновик из шита не протекал в экран без «Применить».
    private(set) var filters = HistoryFilters()

    init() {}

    var activeFilterCount: Int { filters.changedGroupCount }

    var hasActiveFilters: Bool { activeFilterCount > 0 }

    // MARK: - Выборка

    /// Операции для списка: поиск И фильтры одновременно (ТЗ 03).
    /// Порядок стора (по убыванию даты) сохраняется — только фильтрация.
    func visibleOperations(in store: WalletStore) -> [Operation] {
        let query = SearchQuery(rawText: searchText)
        let periodStart = periodStart(for: filters.period)
        return store.operations.filter { operation in
            matchesFilters(operation, periodStart: periodStart)
                && matchesSearch(operation, query: query)
        }
    }

    // MARK: - Действия

    /// Быстрый чип направления: применяется сразу, без шита.
    func selectType(_ type: HistoryTypeFilter) {
        filters.type = type
    }

    /// «Применить» в шите: черновик становится применёнными фильтрами.
    func apply(_ filters: HistoryFilters) {
        self.filters = filters
    }

    /// Чип «Все» и «Сбросить» рядом с чипами: сбрасываются все три группы,
    /// поисковый запрос сохраняется (ТЗ 03, таблица сброса).
    func resetFilters() {
        filters = HistoryFilters()
    }

    /// Кнопка из состояния «Ничего не найдено»: сбрасываются и поиск, и фильтры.
    func resetAll() {
        searchText = ""
        filters = HistoryFilters()
    }

    // MARK: - Фильтры

    private func matchesFilters(_ operation: Operation, periodStart: Date?) -> Bool {
        // Статус не влияет на фильтрацию: неуспешная операция фильтруется
        // наравне с остальными (ТЗ 03).
        switch filters.type {
        case .all: break
        case .incoming: if operation.direction != .incoming { return false }
        case .outgoing: if operation.direction != .outgoing { return false }
        }

        if case .account(let accountID) = filters.account {
            guard operation.sourceAccountID == accountID
                    || operation.destinationAccountID == accountID
            else { return false }
        }

        if let periodStart, operation.date < periodStart { return false }

        return true
    }

    /// Начало периода включительно; nil — «Всё время».
    /// «7 дней» и «30 дней» считаем вместе с сегодняшним днём.
    private func periodStart(for period: HistoryPeriodFilter, now: Date = .now) -> Date? {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        switch period {
        case .allTime: return nil
        case .today: return startOfToday
        case .last7Days: return calendar.date(byAdding: .day, value: -6, to: startOfToday)
        case .last30Days: return calendar.date(byAdding: .day, value: -29, to: startOfToday)
        }
    }

    // MARK: - Поиск

    /// Запрос в двух видах: как есть — для комментария, без пробелов — для суммы.
    private struct SearchQuery {
        /// Обрезанный запрос; пустой — поиск не применяется.
        let text: String
        /// Тот же запрос без пробелов и с точкой, приведённой к запятой.
        let compactAmount: String

        init(rawText: String) {
            let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
            text = trimmed
            compactAmount = HistoryViewModel.compactAmount(trimmed)
        }

        var isEmpty: Bool { text.isEmpty }
    }

    private func matchesSearch(_ operation: Operation, query: SearchQuery) -> Bool {
        guard !query.isEmpty else { return true }

        // По названию счёта не ищем никогда — отдельный критерий приёмки ТЗ 03.
        if let comment = operation.comment, comment.localizedStandardContains(query.text) {
            return true
        }

        let formatted = MoneyFormatter.string(from: operation.amount, currency: operation.currency)
        return Self.compactAmount(formatted).contains(query.compactAmount)
    }

    /// Нормализация суммы для поиска: MoneyFormatter разделяет разряды неразрывным
    /// пробелом, а пользователь вводит обычный (или не вводит вовсе), поэтому
    /// выкидываем пробелы с обеих сторон. Точку приводим к запятой ради «5000.00».
    private static func compactAmount(_ string: String) -> String {
        var result = ""
        result.reserveCapacity(string.count)
        for character in string where !character.isWhitespace {
            result.append(character == "." ? "," : character)
        }
        return result
    }
}
