import Foundation

/// Секция списка истории: один календарный день.
/// Идентификатор — ISO-дата дня: стабилен между перерисовками, годится для ForEach.
struct HistorySection: Identifiable, Hashable {
    let id: String
    /// «Сегодня» / «Вчера» / «26 августа».
    let title: String
    let operations: [Operation]
}

/// Нарезка операций на секции по дням.
enum HistoryGrouping {
    /// «26 августа»: день и месяц в родительном падеже, без года.
    /// В ru_RU родительный падеж даёт шаблон `MMMM` (у `LLLL` был бы «август»).
    private static let dayTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM"
        return formatter
    }()

    /// Режет уже отсортированный список (стор отдаёт по убыванию даты) на секции.
    /// Порядок операций не меняется: группируются только подряд идущие операции
    /// одного дня — так секции наследуют сортировку стора и не переупорядочивают её.
    static func sections(from operations: [Operation],
                         calendar: Calendar = .current,
                         now: Date = .now) -> [HistorySection] {
        var sections: [HistorySection] = []
        var currentDay: Date?
        var bucket: [Operation] = []

        func closeSection() {
            guard let day = currentDay, !bucket.isEmpty else { return }
            sections.append(HistorySection(id: id(for: day, calendar: calendar),
                                           title: title(for: day, calendar: calendar, now: now),
                                           operations: bucket))
            bucket.removeAll()
        }

        for operation in operations {
            let day = calendar.startOfDay(for: operation.date)
            if day != currentDay {
                closeSection()
                currentDay = day
            }
            bucket.append(operation)
        }
        closeSection()

        return sections
    }

    /// Собираем id из компонент переданного календаря, а не через DateFormatter:
    /// формат не зависит от локали устройства и не требует ещё одного форматтера.
    private static func id(for day: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "%04d-%02d-%02d",
                      components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    private static func title(for day: Date, calendar: Calendar, now: Date) -> String {
        if calendar.isDate(day, inSameDayAs: now) {
            return "Сегодня"
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(day, inSameDayAs: yesterday) {
            return "Вчера"
        }
        return dayTitleFormatter.string(from: day)
    }
}
