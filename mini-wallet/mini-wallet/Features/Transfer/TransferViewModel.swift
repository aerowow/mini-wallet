import Foundation
import Observation

/// Шит поверх формы перевода. `nil` — открыта только форма.
/// Состояние «Выполняется» шитом не является: шит подтверждения закрывается,
/// индикатор показывается на кнопке формы (ТЗ 02 §3).
enum TransferSheetKind: Identifiable, Hashable {
    case confirmation
    case success(Operation)
    case duplicate(Operation)
    case failure(reason: OperationFailureReason)

    var id: String {
        switch self {
        case .confirmation: "confirmation"
        case .success(let operation): "success-\(operation.id)"
        case .duplicate(let operation): "duplicate-\(operation.id)"
        case .failure(let reason): "failure-\(reason)"
        }
    }
}

/// Состояние формы перевода, валидация и жизненный цикл ключа операции (ТЗ 02 §3).
/// Данные не хранит: счета берутся из `WalletStore` параметром на каждый вызов —
/// как в `HistoryViewModel`, чтобы новые балансы попадали в UI сразу.
///
/// ВНИМАНИЕ: публичный API этого типа — контракт между тремя параллельными агентами
/// (форма и шиты пишутся против него). Сигнатуры не менять; тела — реализовать.
@MainActor
@Observable
final class TransferViewModel {
    /// Максимум символов комментария (ТЗ 02 §3).
    static let commentLimit = 100

    // MARK: - Поля формы
    //
    // Все четыре поля — вычисляемые обёртки над приватным хранением. Так сеттер
    // гарантированно завершает текущую попытку: «Изменение любого поля формы
    // завершает предыдущую попытку» (ТЗ 02 §3, «Ключ операции»).

    private var storedSourceAccountID: UUID?
    private var storedDestinationAccountID: UUID?
    private var storedAmountText: String
    private var storedComment: String

    var sourceAccountID: UUID? {
        get { storedSourceAccountID }
        set {
            storedSourceAccountID = newValue
            endAttempt()
        }
    }

    var destinationAccountID: UUID? {
        get { storedDestinationAccountID }
        set {
            storedDestinationAccountID = newValue
            endAttempt()
        }
    }

    /// Текст поля «Сумма». Сеттер нормализует ввод: только цифры и один
    /// десятичный разделитель (точка приводится к запятой), максимум два знака
    /// после запятой.
    var amountText: String {
        get { storedAmountText }
        set {
            storedAmountText = Self.sanitizedAmountText(newValue)
            endAttempt()
        }
    }

    /// Комментарий. Сеттер обрезает до `commentLimit`: лишние символы просто
    /// не вводятся, отдельная ошибка не показывается (ТЗ 02 §4).
    var comment: String {
        get { storedComment }
        set {
            storedComment = String(newValue.prefix(Self.commentLimit))
            endAttempt()
        }
    }

    // MARK: - Состояние

    /// Открытый шит; презентует его экран.
    private(set) var sheet: TransferSheetKind?

    /// Идёт вызов стора: поля и кнопки заблокированы, повторное нажатие
    /// не отправляет второй вызов (ТЗ 02 §4).
    private(set) var isExecuting = false

    /// Ключ текущей попытки. `nil` — активной попытки нет, следующее
    /// подтверждение получит новый ключ.
    private(set) var attemptKey: UUID?

    #if DEBUG
    /// DEBUG-переключатель «симулировать повтор»: следующее подтверждение уйдёт
    /// в стор с ключом последнего успешного перевода, и стор честно вернёт
    /// `.duplicate`. В обычной сборке переключателя на экране нет (ТЗ 02 §2).
    var simulatesDuplicate = false

    /// Ключ последнего успешного перевода — то, что подставляет `simulatesDuplicate`.
    private(set) var lastCompletedKey: UUID?

    /// Пока успешных переводов не было, подставлять нечего — переключатель выключен.
    var canSimulateDuplicate: Bool { lastCompletedKey != nil }
    #endif

    /// Параметры init'а нужны только превью: собрать заполненную форму без UI-шагов.
    init(sourceAccountID: UUID? = nil,
         destinationAccountID: UUID? = nil,
         amountText: String = "",
         comment: String = "") {
        self.storedSourceAccountID = sourceAccountID
        self.storedDestinationAccountID = destinationAccountID
        self.storedAmountText = amountText
        self.storedComment = comment
    }

    // MARK: - Производное для формы

    /// Сумма из `amountText`; `nil` — поле пустое или не разбирается.
    var amount: Decimal? {
        // Текст из сеттера уже нормализован, но init (превью) пишет в хранение
        // напрямую — прогоняем через ту же нормализацию, она идемпотентна.
        let sanitized = Self.sanitizedAmountText(storedAmountText)
        // Без единой цифры разбирать нечего: "" и "-" — это пустое поле, а не ноль.
        guard sanitized.contains(where: \.isNumber) else { return nil }
        // Деньги только Decimal: Double не участвует даже в разборе строки.
        // Decimal(string:) без локали ждёт точку, а в поле — запятая (ТЗ 02 §3).
        return Decimal(string: sanitized.replacingOccurrences(of: ",", with: "."))
    }

    /// Подставляет «Откуда» по умолчанию — первый счёт («Основной •• 4417», ТЗ 02 §3).
    /// Вызывается экраном при появлении; повторный вызов ничего не меняет.
    func prepareDefaults(in store: WalletStore) {
        // Уже выбран существующий счёт — это либо выбор пользователя, либо
        // сохранённое после «Готово» значение: не перетираем.
        if let sourceID = storedSourceAccountID, store.account(id: sourceID) != nil { return }
        guard let firstAccount = store.accounts.first else { return }
        // Пишем в хранение напрямую, минуя сеттер: это инициализация формы,
        // а не правка полей пользователем, и гасить попытку тут нечего.
        storedSourceAccountID = firstAccount.id
    }

    func sourceAccount(in store: WalletStore) -> Account? {
        guard let sourceID = storedSourceAccountID else { return nil }
        return store.account(id: sourceID)
    }

    func destinationAccount(in store: WalletStore) -> Account? {
        guard let destinationID = storedDestinationAccountID else { return nil }
        return store.account(id: destinationID)
    }

    /// Ошибка под строкой «Куда»: «Счета должны быть разными» либо
    /// «Перевод между счетами в разных валютах недоступен». `nil` — ошибки нет.
    func accountsErrorText(in store: WalletStore) -> String? {
        // «Куда» ещё не выбран — это не ошибка, а незаполненная форма:
        // текста нет, кнопка просто выключена (ТЗ 02 §3, «Пустая форма»).
        guard let source = sourceAccount(in: store),
              let destination = destinationAccount(in: store)
        else { return nil }

        if source.id == destination.id { return "Счета должны быть разными" }
        // Конвертации в MVP нет, поэтому разные валюты блокируют перевод (ТЗ 02 §3).
        if source.currency != destination.currency {
            return "Перевод между счетами в разных валютах недоступен"
        }
        return nil
    }

    /// Ошибка под полем «Сумма»: «Недостаточно средств» либо
    /// «Введите сумму больше нуля». `nil` — ошибки нет (в том числе у пустого поля).
    func amountErrorText(in store: WalletStore) -> String? {
        // Пустое поле ошибкой не считается: пользователь ещё не начал вводить.
        guard let amount = amount else { return nil }
        if amount <= 0 { return "Введите сумму больше нуля" }
        // «Доступно» — это баланс счёта-источника: отдельного доступного
        // баланса в MVP нет (ТЗ 02 §2).
        guard let source = sourceAccount(in: store) else { return nil }
        if amount > source.balance { return "Недостаточно средств" }
        return nil
    }

    /// Кнопка «Перевести» активна: счета выбраны и различны, валюты совпадают,
    /// 0 < сумма ≤ баланса источника, вызов не выполняется.
    func canSubmit(in store: WalletStore) -> Bool {
        guard !isExecuting,
              sourceAccount(in: store) != nil,
              destinationAccount(in: store) != nil,
              amount != nil,
              accountsErrorText(in: store) == nil,
              amountErrorText(in: store) == nil
        else { return false }
        return true
    }

    // MARK: - Действия формы

    /// Кнопка-иконка «поменять местами» активна: менять местами можно,
    /// только когда «Куда» выбран — иначе «Откуда» осталось бы пустым.
    var canSwap: Bool {
        storedDestinationAccountID != nil
    }

    /// Кнопка-иконка «поменять местами».
    func swapAccounts() {
        guard canSwap else { return } // «Куда» не выбран — менять нечего
        let previousSource = storedSourceAccountID
        storedSourceAccountID = storedDestinationAccountID
        storedDestinationAccountID = previousSource
        // Обмен — такое же изменение полей формы, как ручной выбор счёта,
        // поэтому текущая попытка завершается (ТЗ 02 §3, «Ключ операции»).
        endAttempt()
    }

    /// «Перевести»: открывает шит подтверждения. Ключ здесь ещё НЕ создаётся.
    func submit(in store: WalletStore) {
        // Кнопка и так выключена при ошибках, но защищаемся от гонки:
        // «пока есть хотя бы одна ошибка… выполнение перевода не вызывается» (ТЗ 02 §3).
        guard canSubmit(in: store) else { return }
        // Ключ появится только на «Подтвердить»: открытие шита попыткой не является.
        sheet = .confirmation
    }

    // MARK: - Действия шитов

    /// «Подтвердить»: создаёт ключ попытки (если её ещё нет) и вызывает стор.
    func confirm(in store: WalletStore) async {
        // Повторное нажатие во время выполнения второй вызов не отправляет (ТЗ 02 §4).
        guard !isExecuting else { return }
        // Счета и сумму разрешаем заново: между открытием шита и подтверждением
        // счёт мог исчезнуть, а стор ждёт валидные предусловия.
        guard let source = sourceAccount(in: store),
              let destination = destinationAccount(in: store),
              let amount = amount
        else { return }

        let key = resolvedAttemptKey()
        attemptKey = key

        // Шит подтверждения закрывается, а индикатор «Выполняется…» живёт
        // на кнопке формы (ТЗ 02 §3, фрейм 07).
        sheet = nil
        isExecuting = true

        // Пустой комментарий — это отсутствие комментария, а не строка из пробелов.
        let trimmedComment = storedComment.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = TransferRequest(
            sourceAccountID: source.id,
            destinationAccountID: destination.id,
            amount: amount,
            comment: trimmedComment.isEmpty ? nil : trimmedComment,
            key: key
        )
        let result = await store.transfer(request)

        isExecuting = false

        switch result {
        case .completed(let operation):
            #if DEBUG
            lastCompletedKey = key // будущему «симулировать повтор» нужен реальный ключ
            #endif
            endAttempt() // успех завершает попытку (ТЗ 02 §3)
            sheet = .success(operation)
        case .duplicate(let operation):
            endAttempt() // показ повтора тоже завершает попытку (ТЗ 02 §3)
            sheet = .duplicate(operation)
        case .failed(let reason):
            // Единственный случай, когда ключ СОХРАНЯЕТСЯ: «Повторить»
            // обязано уйти с прежним ключом (ТЗ 02 §3).
            sheet = .failure(reason: reason)
        }
    }

    /// «Повторить» на шите ошибки выполнения: тот же ключ, что и в прошлый раз.
    func retry(in store: WalletStore) async {
        // Без живого ключа это была бы новая попытка, а не повтор той же операции:
        // идемпотентность проверяется именно прежним ключом (ТЗ 02 §4).
        guard attemptKey != nil else { return }
        // confirm при непустом attemptKey новый ключ не создаёт — переиспользуем его.
        await confirm(in: store)
    }

    /// «Отмена» на шите ошибки выполнения: попытка завершена, поля сохраняются.
    func cancelFailure() {
        // Поля намеренно не чистим: пользователь может поправить данные или
        // подтвердить снова — и это будет новая попытка с новым ключом (ТЗ 02 §3).
        endAttempt()
        sheet = nil
    }

    /// «Готово» на шите успеха или повтора: попытка завершена, форма очищается.
    func finish() {
        endAttempt()
        sheet = nil
        // «Откуда» оставляем выбранным: это дефолт формы («Основной •• 4417»,
        // ТЗ 02 §3), а не введённые пользователем данные — очищать его незачем.
        storedDestinationAccountID = nil
        storedAmountText = ""
        storedComment = ""
    }

    /// Шит закрыт мимо кнопок (свайпом): применяет правило соответствующей кнопки.
    func dismissSheet() {
        switch sheet {
        case .confirmation, .none:
            // Подтверждение свайпом = «Отмена» на подтверждении: попытки ещё нет,
            // гасить нечего, форма остаётся как была.
            sheet = nil
        case .failure:
            cancelFailure()
        case .success, .duplicate:
            finish()
        }
    }

    // MARK: - Ключ операции

    /// Ключ для ближайшего вызова стора: у живой попытки — прежний, иначе новый.
    private func resolvedAttemptKey() -> UUID {
        // Ключ живёт до конца попытки: «Повторить» после ошибки выполнения
        // уходит именно с ним (ТЗ 02 §3).
        if let attemptKey = attemptKey { return attemptKey }
        #if DEBUG
        // «Симулировать повтор»: уходим в стор с ключом последнего успешного
        // перевода, и стор САМ вернёт .duplicate. Результат не подделывается,
        // проверяется настоящая идемпотентность (ТЗ 02 §2, §4).
        if simulatesDuplicate, let lastCompletedKey = lastCompletedKey { return lastCompletedKey }
        #endif
        return UUID()
    }

    /// Завершает текущую попытку: следующее подтверждение получит новый ключ.
    private func endAttempt() {
        attemptKey = nil
    }

    /// Нормализация ввода суммы.
    private static func sanitizedAmountText(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.count)
        var hasSeparator = false
        var fractionDigitCount = 0

        for character in text {
            switch character {
            case "-":
                // Ведущий минус оставляем сознательно: без него критерий приёмки
                // «сумма 0 или отрицательная → Введите сумму больше нуля» (ТЗ 02 §4)
                // был бы недостижим. Второй минус и минус в середине — мусор.
                if result.isEmpty { result.append("-") }
            case ",", ".":
                // Разделитель ровно один, и он всегда запятая: точку с цифровой
                // клавиатуры приводим к формату вывода (ТЗ 02 §2, `128 450,00 ₽`).
                guard !hasSeparator else { continue }
                hasSeparator = true
                result.append(",")
            case "0"..."9":
                // Копейки — максимум два знака: лишние просто не вводятся.
                if hasSeparator {
                    guard fractionDigitCount < 2 else { continue }
                    fractionDigitCount += 1
                }
                result.append(character)
            default:
                // Пробелы, буквы и всё остальное в поле суммы не попадают.
                continue
            }
        }
        return result
    }
}
