import Foundation

/// Валюта счёта. Замкнутый набор MVP: конвертаций нет.
enum Currency: Hashable {
    case rub
    case usd

    /// Символ, который MoneyFormatter дописывает после суммы.
    var symbol: String {
        switch self {
        case .rub: "₽"
        case .usd: "$"
        }
    }
}

/// Тип операции: перевод между своими счетами или пополнение извне.
enum OperationKind: Hashable {
    case transfer
    case deposit
}

/// Направление операции для истории и фильтров.
enum OperationDirection: Hashable {
    case incoming
    case outgoing
}

/// Причина неуспеха операции. Замкнутый набор: у каждого кейса два текста.
enum OperationFailureReason: Hashable {
    /// Перевод между счетами в разных валютах — существует только в стартовых моках,
    /// новые такие операции блокируются валидацией формы перевода.
    case differentCurrencies
    /// Ошибка выполнения (симулируется флагом стора в DEBUG/Preview).
    case executionFailed

    /// Короткий текст для подписи строки в истории.
    var shortText: String {
        switch self {
        case .differentCurrencies: "Разные валюты счетов"
        case .executionFailed: "Ошибка выполнения"
        }
    }

    /// Развёрнутый текст для шита на экране перевода.
    var displayText: String {
        switch self {
        case .differentCurrencies: "Перевод между счетами в разных валютах недоступен"
        case .executionFailed: "Деньги не списаны, попробуйте ещё раз"
        }
    }
}

/// Статус операции.
enum OperationStatus: Hashable {
    case success
    case failed(reason: OperationFailureReason)
}

/// Счёт пользователя.
struct Account: Identifiable, Hashable {
    let id: UUID
    let name: String
    /// Маскированный номер в формате из макета, например "•• 4417".
    let maskedNumber: String
    let currency: Currency
    var balance: Decimal
}

/// Операция в истории. Сумма всегда положительная:
/// знак −/+ добавляется только при отображении.
struct Operation: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let kind: OperationKind
    /// Счёт-источник; nil у пополнения.
    let sourceAccountID: UUID?
    /// Счёт-получатель.
    let destinationAccountID: UUID
    let amount: Decimal
    let currency: Currency
    let comment: String?
    let status: OperationStatus
    /// Ключ идемпотентности; есть только у переводов, выполненных через стор.
    let key: UUID?

    /// Правило MVP (ТЗ 03): пополнения — входящие, любые переводы — исходящие,
    /// в том числе неуспешные.
    var direction: OperationDirection {
        kind == .deposit ? .incoming : .outgoing
    }
}

/// Запрос на перевод между своими счетами.
/// Предусловия обеспечивает форма перевода ДО вызова стора: счета существуют
/// и различны, валюты совпадают, 0 < amount ≤ баланс источника.
struct TransferRequest: Hashable {
    let sourceAccountID: UUID
    let destinationAccountID: UUID
    let amount: Decimal
    let comment: String?
    /// Ключ идемпотентности попытки; жизненный цикл ключа — зона экрана перевода.
    let key: UUID
}

/// Результат вызова WalletStore.transfer(_:).
enum TransferResult: Hashable {
    /// Перевод выполнен, операция создана, балансы обновлены.
    case completed(Operation)
    /// Повтор с уже использованным ключом: возвращается первоначальная операция,
    /// балансы не изменены, новая операция не создана.
    case duplicate(Operation)
    /// Выполнить не удалось: балансы не изменены, операция не создана.
    case failed(reason: OperationFailureReason)
}
