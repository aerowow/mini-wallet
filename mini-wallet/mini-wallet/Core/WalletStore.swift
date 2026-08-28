import Foundation
import Observation

/// Единственный источник данных всех трёх экранов.
/// Создаётся один раз в @main и прокидывается через .environment;
/// экраны читают тот же инстанс, SwiftUI перерисовывает их сам.
@MainActor
@Observable
final class WalletStore {
    /// Счета в порядке отображения на экране «Счета».
    private(set) var accounts: [Account]

    /// Операции по убыванию даты и времени: новые в начале.
    private(set) var operations: [Operation]

    #if DEBUG
    /// Одноразовая симуляция ошибки выполнения (только DEBUG и Preview, ТЗ 02).
    /// Первый transfer(_:) после включения вернёт .failed и сбросит флаг сам.
    var simulateExecutionFailure = false
    #endif

    /// Реестр идемпотентности: ключ операции -> id выполненной операции.
    /// Пишутся только успешные переводы, поэтому «Повторить» после ошибки
    /// выполнения с тем же ключом проходит.
    private var completedTransferIDs: [UUID: Operation.ID] = [:]

    init(accounts: [Account] = MockData.accounts,
         operations: [Operation] = MockData.operations) {
        self.accounts = accounts
        self.operations = operations
    }

    /// Сводный баланс: сумма балансов только рублёвых счетов.
    /// Счета в других валютах не входят и не конвертируются.
    var totalRubBalance: Decimal {
        accounts.filter { $0.currency == .rub }.reduce(.zero) { $0 + $1.balance }
    }

    func account(id: UUID) -> Account? {
        accounts.first { $0.id == id }
    }

    /// Перевод между своими счетами с гарантией идемпотентности.
    /// Предусловия обеспечивает форма перевода ДО вызова: счета существуют
    /// и различны, валюты совпадают, 0 < amount ≤ баланс источника.
    func transfer(_ request: TransferRequest) async -> TransferResult {
        if let operationID = completedTransferIDs[request.key],
           let original = operations.first(where: { $0.id == operationID }) {
            return .duplicate(original)
        }

        // Имитация задержки выполнения ~1 с (согласовано с Dev 2).
        try? await Task.sleep(for: .seconds(1))

        #if DEBUG
        if simulateExecutionFailure {
            simulateExecutionFailure = false // мок-ошибка одноразовая (ТЗ 02)
            return .failed(reason: .executionFailed)
        }
        #endif

        guard let sourceIndex = accounts.firstIndex(where: { $0.id == request.sourceAccountID }),
              let destinationIndex = accounts.firstIndex(where: { $0.id == request.destinationAccountID })
        else {
            return .failed(reason: .executionFailed)
        }

        accounts[sourceIndex].balance -= request.amount
        accounts[destinationIndex].balance += request.amount

        let operation = Operation(
            id: UUID(),
            date: .now,
            kind: .transfer,
            sourceAccountID: request.sourceAccountID,
            destinationAccountID: request.destinationAccountID,
            amount: request.amount,
            currency: accounts[sourceIndex].currency,
            comment: request.comment,
            status: .success,
            key: request.key
        )
        operations.insert(operation, at: 0)
        completedTransferIDs[request.key] = operation.id
        return .completed(operation)
    }
}
