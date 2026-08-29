import SwiftUI

/// Шит ошибки выполнения: состояние «Ошибка выполнения» (ТЗ 02 §3), макет — фрейм 10.
/// Это отдельное состояние, не связанное с четырьмя ошибками валидации:
/// те показываются прямо в форме и до подтверждения.
///
/// «Глупая» вью: причина и оба действия приходят снаружи. «Повторить» уходит
/// в стор с ПРЕЖНИМ ключом попытки, «Отмена» завершает попытку — но и то,
/// и другое решает экран, шит только зовёт замыкания.
struct TransferFailureSheet: View {
    let reason: OperationFailureReason
    let onRetry: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TransferDesign.sectionSpacing) {
            VStack(spacing: TransferDesign.fieldSpacing) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: TransferDesign.sheetIconSize))
                    // Красный — только для ошибок (pen-dev-prompt, шаг 2).
                    .foregroundStyle(TransferDesign.negative)
                    .accessibilityHidden(true)

                Text("Не удалось выполнить перевод")
                    .font(TransferDesign.sheetTitleFont)
                    .foregroundStyle(TransferDesign.textPrimary)
                    .multilineTextAlignment(.center)

                // Пояснение берём из контракта: для .executionFailed это ровно
                // «Деньги не списаны, попробуйте ещё раз» (ТЗ 02 §3).
                // Дублировать текст строкой нельзя — разъедется с историей.
                Text(reason.displayText)
                    .font(TransferDesign.subtitleFont)
                    .foregroundStyle(TransferDesign.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)

            // Сноска фрейма 10 макета: повтор безопасен, потому что уходит с тем же
            // ключом операции. Ключ по ТЗ скрытый, поэтому в интерфейсе говорим
            // о следствии, а не о механике.
            Text("Повтор безопасен: второй перевод не создастся.")
                .font(TransferDesign.captionFont)
                .foregroundStyle(TransferDesign.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)

            // Spacer'а нет намеренно: высота шита считается по контенту
            // (TransferSheetHeight на месте вызова), поэтому корень должен
            // иметь СВОЮ высоту, а не растягиваться на весь экран.
            VStack(spacing: TransferDesign.fieldSpacing) {
                // Порядок кнопок — как в ТЗ 02 §3: «Повторить» и «Отмена».
                TransferPrimaryButton(title: "Повторить", action: onRetry)
                TransferSecondaryButton(title: "Отмена", action: onCancel)
            }
        }
        .padding(TransferDesign.sheetPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TransferDesign.screenBackground)
    }
}

#Preview("Ошибка выполнения") {
    TransferFailureSheet(reason: .executionFailed, onRetry: {}, onCancel: {})
}

#Preview("Разные валюты") {
    // Кейс из контракта: формой такой перевод не пропускается,
    // но шит обязан корректно отрисовать любую причину.
    TransferFailureSheet(reason: .differentCurrencies, onRetry: {}, onCancel: {})
}
