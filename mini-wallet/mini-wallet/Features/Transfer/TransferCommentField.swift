import SwiftUI

/// Поле «Комментарий» — необязательное, до 100 символов (ТЗ 02 §3).
/// Обрезку до лимита делает сеттер вьюмодели: лишние символы просто
/// не вводятся, отдельной ошибки под полем НЕ показывается (ТЗ 02 §4).
/// Счётчик «12/100» — ненавязчивая подсказка, появляется только когда
/// в поле что-то есть.
struct TransferCommentField: View {
    @Binding var text: String
    /// Лимит символов. Приходит параметром (`TransferViewModel.commentLimit`),
    /// чтобы подпись и реальная обрезка не разъехались.
    let limit: Int

    var body: some View {
        VStack(alignment: .leading, spacing: TransferDesign.textSpacing) {
            Text("Комментарий")
                .font(TransferDesign.captionFont)
                .foregroundStyle(TransferDesign.textSecondary)

            // axis: .vertical — длинный комментарий переносится, а не уезжает
            // за край; потолок в три строки держит высоту формы предсказуемой.
            TextField("Необязательно", text: $text, axis: .vertical)
                .lineLimit(1...3)
                .font(TransferDesign.bodyFont)
                .foregroundStyle(TransferDesign.textPrimary)
                .padding(TransferDesign.cardPadding)
                .transferFieldBackground()

            if !text.isEmpty {
                Text("\(text.count)/\(limit)")
                    .font(TransferDesign.captionFont)
                    .foregroundStyle(TransferDesign.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

#Preview("Пустое поле") {
    @Previewable @State var text = ""
    TransferCommentField(text: $text, limit: TransferViewModel.commentLimit)
        .padding(.horizontal, TransferDesign.screenHPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TransferDesign.screenBackground)
}

#Preview("Заполнено") {
    @Previewable @State var text = "Отложить на отпуск"
    TransferCommentField(text: $text, limit: TransferViewModel.commentLimit)
        .padding(.horizontal, TransferDesign.screenHPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TransferDesign.screenBackground)
}
