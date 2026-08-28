import Foundation
import Observation

/// Вкладки корневого TabView. Порядок соответствует таб-бару.
enum AppTab: Hashable {
    case accounts
    case transfer
    case history
}

/// Программное переключение вкладок: экраны присваивают selectedTab
/// («Перевести» → .transfer, «Открыть в истории» → .history,
/// «Сделать перевод» → .transfer). Создаётся один раз в @main
/// и прокидывается через .environment.
@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .accounts
}
