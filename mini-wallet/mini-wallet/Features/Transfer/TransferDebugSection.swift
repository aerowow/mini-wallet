#if DEBUG
import SwiftUI

/// DEBUG-конфигурация перевода: воспроизводит состояния «ошибка выполнения»
/// и «перевод уже выполнен» (ТЗ 02 §2).
///
/// Весь файл под `#if DEBUG`, поэтому в продуктовой сборке типа не существует —
/// это, а не проверка флага в рантайме, гарантирует критерий приёмки
/// «в обычной сборке тестовых переключателей на экране нет» (ТЗ 02 §4).
///
/// Скрытых триггеров по сумме или тексту комментария нет и быть не должно
/// (ТЗ 02 §2): оба состояния включаются только этими явными переключателями.
///
/// Вью «глупая»: биндинги приходят снаружи — `simulatesExecutionFailure`
/// от `WalletStore.simulateExecutionFailure`, `simulatesDuplicate`
/// от `TransferViewModel.simulatesDuplicate`.
struct TransferDebugSection: View {
    @Binding var simulatesExecutionFailure: Bool
    @Binding var simulatesDuplicate: Bool
    let canSimulateDuplicate: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: TransferDesign.fieldSpacing) {
            VStack(alignment: .leading, spacing: TransferDesign.textSpacing) {
                Label("Только для DEBUG", systemImage: "hammer.fill")
                    .font(TransferDesign.bodySemiboldFont)
                    .foregroundStyle(TransferDesign.accent)
                Text("В обычной сборке приложения этой секции нет: тестовым переключателям в продуктовом интерфейсе не место.")
                    .font(TransferDesign.captionFont)
                    .foregroundStyle(TransferDesign.textSecondary)
            }
            .accessibilityElement(children: .combine)

            Divider()
                .overlay(TransferDesign.border)

            Toggle(isOn: $simulatesExecutionFailure) {
                TransferDebugToggleLabel(
                    title: "Ошибка выполнения",
                    explanation: "Мок-ошибка одноразовая: ближайший перевод вернёт «Не удалось выполнить перевод» без списания, режим сбросится сам."
                )
            }
            .tint(TransferDesign.accent)

            Toggle(isOn: $simulatesDuplicate) {
                TransferDebugToggleLabel(
                    title: "Симулировать повтор",
                    // Не подделка результата: переключатель подставляет ключ
                    // последнего успешного перевода, и стор честно возвращает
                    // duplicate по своему реестру идемпотентности (ТЗ 02 §1).
                    explanation: canSimulateDuplicate
                        ? "Следующее подтверждение уйдёт с ключом последнего успешного перевода — стор вернёт «перевод уже выполнен»."
                        : "Нужен хотя бы один успешный перевод: без него нечего подставлять в ключ операции."
                )
            }
            .tint(TransferDesign.accent)
            .disabled(!canSimulateDuplicate)
        }
        .padding(TransferDesign.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .transferCardBackground()
    }
}

/// Подпись переключателя: название и пояснение, что именно он делает.
private struct TransferDebugToggleLabel: View {
    let title: String
    let explanation: String

    var body: some View {
        VStack(alignment: .leading, spacing: TransferDesign.textSpacing) {
            Text(title)
                .font(TransferDesign.bodyFont)
                .foregroundStyle(TransferDesign.textPrimary)
            Text(explanation)
                .font(TransferDesign.captionFont)
                .foregroundStyle(TransferDesign.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("DEBUG-секция — повтор доступен") {
    @Previewable @State var simulatesExecutionFailure = false
    @Previewable @State var simulatesDuplicate = false

    TransferDebugSection(
        simulatesExecutionFailure: $simulatesExecutionFailure,
        simulatesDuplicate: $simulatesDuplicate,
        canSimulateDuplicate: true
    )
    .padding(TransferDesign.sheetPadding)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(TransferDesign.screenBackground)
}

#Preview("DEBUG-секция — успешных переводов ещё не было") {
    @Previewable @State var simulatesExecutionFailure = true
    @Previewable @State var simulatesDuplicate = false

    TransferDebugSection(
        simulatesExecutionFailure: $simulatesExecutionFailure,
        simulatesDuplicate: $simulatesDuplicate,
        canSimulateDuplicate: false
    )
    .padding(TransferDesign.sheetPadding)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(TransferDesign.screenBackground)
}
#endif
