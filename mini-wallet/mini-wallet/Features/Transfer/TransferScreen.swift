import SwiftUI

/// Экран «Перевод» (ТЗ 02): форма перевода между своими счетами.
/// Имя типа и init без параметров зафиксированы — на них ссылается RootTabView.
/// Заголовок — кастомный текст, как в AccountsScreen: NavigationStack не нужен,
/// навигации с экрана нет.
///
/// Шиты подтверждения/успеха/повтора/ошибки живут отдельно и подключаются
/// к `viewModel.sheet` поверх этого экрана — форма про них не знает.
struct TransferScreen: View {
    @Environment(WalletStore.self) private var store
    /// Нужен только для «Открыть в истории» в шитах успеха и повтора (ТЗ 02 §3).
    @Environment(AppRouter.self) private var router

    /// Вьюмодель принимается снаружи только ради превью состояний
    /// («заполнено» без ручного заполнения полей).
    @State private var viewModel: TransferViewModel

    init(viewModel: TransferViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    /// Отдельный init вместо значения по умолчанию: выражение дефолтного
    /// аргумента вычисляется вне MainActor, а TransferViewModel им изолирован
    /// (то же решение, что в HistoryScreen).
    init() {
        self.init(viewModel: TransferViewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            // Форма в ScrollView, кнопка — вне его: так «Перевести» прижата
            // к низу контента (ТЗ 02 §3) и остаётся видимой при поднятой
            // клавиатуре и крупном Dynamic Type.
            ScrollView {
                form
            }
            .scrollDismissesKeyboard(.interactively)
            // «Выполняется»: поля и кнопки неактивны (ТЗ 02 §3).
            .disabled(viewModel.isExecuting)

            TransferPrimaryButton(title: viewModel.isExecuting ? "Выполняется…" : "Перевести",
                                  isLoading: viewModel.isExecuting) {
                viewModel.submit(in: store)
            }
            // canSubmit сам возвращает false во время выполнения,
            // так что второй вызов в стор не уходит.
            .disabled(!viewModel.canSubmit(in: store))
            .padding(.horizontal, TransferDesign.screenHPadding)
            .padding(.top, TransferDesign.fieldSpacing)
            .padding(.bottom, TransferDesign.fieldSpacing)
        }
        .background(TransferDesign.screenBackground.ignoresSafeArea())
        // «Откуда» по умолчанию — первый счёт («Основной •• 4417», ТЗ 02 §3).
        .task { viewModel.prepareDefaults(in: store) }
        .sheet(item: sheetBinding) { kind in
            sheetContent(kind)
                .modifier(TransferSheetHeight())
        }
    }

    // MARK: - Шиты

    /// Один `.sheet` на все четыре состояния: подтверждение, успех, повтор, ошибка.
    /// Состояние «Выполняется» шитом не является — шит подтверждения к этому
    /// моменту уже закрыт вьюмоделью (ТЗ 02 §3, фрейм 07).
    ///
    /// Сеттер срабатывает только на закрытие свайпом; программное закрытие
    /// вьюмодель делает сама. Свайп приравнивается к кнопке этого же шита,
    /// иначе попытка осталась бы незавершённой, а форма — неочищенной.
    private var sheetBinding: Binding<TransferSheetKind?> {
        Binding(get: { viewModel.sheet },
                set: { newValue in
                    if newValue == nil { viewModel.dismissSheet() }
                })
    }

    @ViewBuilder
    private func sheetContent(_ kind: TransferSheetKind) -> some View {
        switch kind {
        case .confirmation:
            // Счета и сумма уже проверены canSubmit до открытия шита; если
            // состояние всё же разъехалось — закрываемся, а не показываем пустое.
            if let source = viewModel.sourceAccount(in: store),
               let destination = viewModel.destinationAccount(in: store),
               let amount = viewModel.amount {
                confirmationSheet(source: source, destination: destination, amount: amount)
            } else {
                Color.clear.onAppear { viewModel.dismissSheet() }
            }

        case .success(let operation):
            // Балансы читаем из стора: они уже обновлены переводом, а Operation
            // их не несёт (ТЗ 02 §3 требует показать новые балансы обоих счетов).
            TransferSuccessSheet(operation: operation,
                                 sourceAccount: account(for: operation.sourceAccountID),
                                 destinationAccount: account(for: operation.destinationAccountID),
                                 onOpenHistory: openInHistory,
                                 onDone: viewModel.finish)

        case .duplicate(let operation):
            // Та же выборка, но балансы здесь не менялись — перевод не выполнялся заново.
            TransferDuplicateSheet(operation: operation,
                                   sourceAccount: account(for: operation.sourceAccountID),
                                   destinationAccount: account(for: operation.destinationAccountID),
                                   onOpenHistory: openInHistory,
                                   onDone: viewModel.finish)

        case .failure(let reason):
            TransferFailureSheet(reason: reason,
                                 onRetry: { Task { await viewModel.retry(in: store) } },
                                 onCancel: viewModel.cancelFailure)
        }
    }

    /// Шит подтверждения. DEBUG-секция вставляется сюда, а не живёт внутри шита:
    /// в обычной сборке блок `#if DEBUG` пуст, `@ViewBuilder` сворачивает его
    /// в `EmptyView`, и тестовых переключателей в интерфейсе нет (ТЗ 02 §2).
    private func confirmationSheet(source: Account,
                                   destination: Account,
                                   amount: Decimal) -> some View {
        @Bindable var store = store
        @Bindable var viewModel = viewModel

        return TransferConfirmationSheet(
            source: source,
            destination: destination,
            amount: amount,
            comment: viewModel.comment.isEmpty ? nil : viewModel.comment,
            onConfirm: { Task { await viewModel.confirm(in: store) } },
            onCancel: viewModel.dismissSheet
        ) {
            #if DEBUG
            TransferDebugSection(
                simulatesExecutionFailure: $store.simulateExecutionFailure,
                simulatesDuplicate: $viewModel.simulatesDuplicate,
                canSimulateDuplicate: viewModel.canSimulateDuplicate
            )
            #endif
        }
    }

    private func account(for id: UUID?) -> Account? {
        guard let id else { return nil }
        return store.account(id: id)
    }

    /// «Открыть в истории»: попытка завершается ровно как по «Готово»,
    /// после чего активной становится вкладка «История» (ТЗ 02 §3).
    private func openInHistory() {
        viewModel.finish()
        router.selectedTab = .history
    }

    /// Поля формы сверху вниз (ТЗ 02 §3). Биндинги полей — через @Bindable:
    /// сеттеры вьюмодели нормализуют ввод и завершают текущую попытку.
    @ViewBuilder
    private var form: some View {
        @Bindable var viewModel = viewModel
        let sourceAccount = viewModel.sourceAccount(in: store)

        VStack(alignment: .leading, spacing: TransferDesign.sectionSpacing) {
            Text("Перевод")
                .font(TransferDesign.titleFont)
                .foregroundStyle(TransferDesign.textPrimary)

            VStack(alignment: .leading, spacing: TransferDesign.fieldSpacing) {
                TransferAccountPickerRow(title: "Откуда",
                                         account: sourceAccount,
                                         accounts: store.accounts) { account in
                    viewModel.sourceAccountID = account.id
                }

                TransferSwapButton { viewModel.swapAccounts() }
                    .disabled(!viewModel.canSwap)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Валютный счёт в «Куда» выбрать можно: ошибка о разных
                // валютах показывается уже после выбора (ТЗ 02 §3).
                TransferAccountPickerRow(title: "Куда",
                                         account: viewModel.destinationAccount(in: store),
                                         accounts: store.accounts,
                                         errorText: viewModel.accountsErrorText(in: store)) { account in
                    viewModel.destinationAccountID = account.id
                }
            }

            TransferAmountField(text: $viewModel.amountText,
                                currency: sourceAccount?.currency,
                                availableBalance: sourceAccount?.balance,
                                errorText: viewModel.amountErrorText(in: store))

            TransferCommentField(text: $viewModel.comment,
                                 limit: TransferViewModel.commentLimit)
        }
        .padding(.horizontal, TransferDesign.screenHPadding)
        .padding(.top, TransferDesign.cardPadding)
        .padding(.bottom, TransferDesign.fieldSpacing)
    }
}

/// Высота шита по его СОБСТВЕННОМУ контенту.
///
/// Общий детент на все четыре шита не работает: подтверждение с DEBUG-секцией
/// высокое, шит ошибки — три строки и две кнопки. `.medium` резал подтверждение
/// («Отмена» уезжала за край), `.large` оставлял полэкрана воздуха под ошибкой.
/// Поэтому высота считается замером: детент = высота контента + нижняя
/// безопасная зона (детент задаёт ПОЛНУЮ высоту шита, а контент измеряется уже
/// без неё — без добавки нижняя кнопка уходит под домашний индикатор).
///
/// В Release DEBUG-секции нет, подтверждение становится ниже — замер подстроится
/// сам, отдельной ветки под конфигурацию не нужно.
private struct TransferSheetHeight: ViewModifier {
    @State private var contentHeight: CGFloat = 0
    @State private var bottomInset: CGFloat = 0

    func body(content: Content) -> some View {
        ScrollView {
            content
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    contentHeight = height
                }
        }
        // Прокрутка — страховка на крупный Dynamic Type: если контент выше экрана,
        // детент упрётся в потолок и шит станет прокручиваемым вместо обрезанного.
        // Когда контент помещается целиком, пружинить он не должен.
        .scrollBounceBehavior(.basedOnSize)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.safeAreaInsets.bottom
        } action: { inset in
            bottomInset = inset
        }
        // Фон и на ScrollView: полоса нижней безопасной зоны контентом
        // не закрыта, без этого там просвечивает системный фон шита.
        .background(TransferDesign.screenBackground)
        .presentationDetents(detents)
    }

    private var detents: Set<PresentationDetent> {
        // До первого замера — один кадр на .medium, дальше высота уточняется.
        guard contentHeight > 0 else { return [.medium] }
        // .large запасной: если замер упёрся в потолок экрана, шит можно растянуть.
        return [.height(contentHeight + bottomInset), .large]
    }
}

/// Кнопка-иконка «поменять местами» между строками счетов (ТЗ 02 §3).
/// Читает `isEnabled` из окружения, чтобы гаснуть и когда своп невозможен,
/// и когда вся форма заблокирована состоянием «Выполняется».
private struct TransferSwapButton: View {
    @Environment(\.isEnabled) private var isEnabled
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.up.arrow.down")
                .font(TransferDesign.bodySemiboldFont)
                .foregroundStyle(isEnabled ? TransferDesign.accent : TransferDesign.textSecondary)
                // Зона нажатия 44×44 — минимум из макета.
                .frame(width: TransferDesign.iconButtonSize,
                       height: TransferDesign.iconButtonSize)
                .background(TransferDesign.secondaryFill, in: .circle)
        }
        .accessibilityLabel("Поменять счета местами")
    }
}

#Preview("Пустая форма") {
    TransferScreen()
        .environment(WalletStore())
        .environment(AppRouter())
}

#Preview("Заполнено") {
    TransferScreen(viewModel: TransferViewModel(
        sourceAccountID: MockData.accounts[0].id,
        destinationAccountID: MockData.accounts[1].id,
        amountText: "5000",
        comment: "Отложить на отпуск"
    ))
    .environment(WalletStore())
    .environment(AppRouter())
}

#Preview("Разные валюты") {
    TransferScreen(viewModel: TransferViewModel(
        sourceAccountID: MockData.accounts[0].id,
        destinationAccountID: MockData.accounts[2].id,
        amountText: "1000"
    ))
    .environment(WalletStore())
    .environment(AppRouter())
}
