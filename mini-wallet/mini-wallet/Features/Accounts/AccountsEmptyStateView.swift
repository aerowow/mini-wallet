import SwiftUI

/// Пустое состояние экрана «Счета»: иконка и пояснение,
/// показывается, когда в сторе нет ни одного счёта.
struct AccountsEmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard")
                .font(.system(size: 40))
                .foregroundStyle(AccountsDesign.textSecondary)

            VStack(spacing: 4) {
                Text("Пока нет счетов")
                    .font(AccountsDesign.bodySemiboldFont)
                    .foregroundStyle(AccountsDesign.textPrimary)
                Text("Счета появятся здесь, когда их добавят")
                    .font(AccountsDesign.subtitleFont)
                    .foregroundStyle(AccountsDesign.textSecondary)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}
