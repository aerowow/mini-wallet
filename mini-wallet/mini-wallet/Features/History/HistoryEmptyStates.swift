import SwiftUI

/// Компонент `EmptyState` из макета: иконка, заголовок, поясняющий текст,
/// кнопка действия. Оба пустых состояния истории собраны на нём, чтобы вёрстка
/// жила в одном месте. Основа — нативный ContentUnavailableView:
/// иллюстраций и маскотов дизайн не допускает.
private struct HistoryEmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
                // .large держит зону нажатия не меньше 44 (ограничение дизайна).
                .controlSize(.large)
        }
    }
}

/// «Ничего не найдено»: поиск и фильтры вместе не дали ни одной операции.
/// Кнопка сбрасывает И запрос, И фильтры — экран передаёт сюда resetAll(),
/// возврат полного списка это критерий приёмки ТЗ 03.
struct HistoryNothingFoundView: View {
    private let onReset: () -> Void

    init(onReset: @escaping () -> Void) {
        self.onReset = onReset
    }

    var body: some View {
        HistoryEmptyStateView(
            systemImage: "magnifyingglass",
            title: "Ничего не найдено",
            message: "Измените запрос или сбросьте фильтры",
            actionTitle: "Сбросить фильтры",
            action: onReset
        )
    }
}

/// «Операций пока нет»: история пуста. Поиск и чипы в этом состоянии скрывает
/// сам экран, здесь только предложение сделать первый перевод.
struct HistoryNoOperationsView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        HistoryEmptyStateView(
            systemImage: "clock.arrow.circlepath",
            title: "Операций пока нет",
            message: "Здесь появятся ваши переводы и пополнения",
            actionTitle: "Сделать перевод",
            action: { router.selectedTab = .transfer }
        )
    }
}
