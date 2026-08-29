import SwiftUI

/// Главная акцентная кнопка экрана «Перевод»: «Перевести», «Подтвердить»,
/// «Готово», «Повторить». В состоянии загрузки показывает индикатор и не нажимается
/// (ТЗ 02 §3, «Выполняется»).
/// Выключенность — стандартным `.disabled(true)` на месте вызова.
/// Префикс Transfer обязателен: все Features собираются в один модуль,
/// без него тип столкнётся с одноимённым у других фич.
struct TransferPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: TransferDesign.fieldSpacing) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
                Text(title)
            }
        }
        .buttonStyle(TransferPrimaryButtonStyle())
        // Второе нажатие в состоянии «Выполняется…» не должно уходить в стор.
        .allowsHitTesting(!isLoading)
    }
}

/// Вторичная кнопка шитов: «Отмена», «Открыть в истории».
struct TransferSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(TransferSecondaryButtonStyle())
    }
}

private struct TransferPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TransferDesign.bodySemiboldFont)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: TransferDesign.buttonHeight)
            .background(
                isEnabled ? TransferDesign.accent : TransferDesign.accent.opacity(0.4),
                in: .rect(cornerRadius: TransferDesign.buttonCornerRadius)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

private struct TransferSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TransferDesign.bodySemiboldFont)
            .foregroundStyle(isEnabled ? TransferDesign.textPrimary : TransferDesign.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: TransferDesign.buttonHeight)
            .background(
                TransferDesign.secondaryFill,
                in: .rect(cornerRadius: TransferDesign.buttonCornerRadius)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

#Preview {
    VStack(spacing: TransferDesign.fieldSpacing) {
        TransferPrimaryButton(title: "Перевести") {}
        TransferPrimaryButton(title: "Перевести") {}
            .disabled(true)
        TransferPrimaryButton(title: "Выполняется…", isLoading: true) {}
        TransferSecondaryButton(title: "Отмена") {}
    }
    .padding(.horizontal, TransferDesign.screenHPadding)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(TransferDesign.screenBackground)
}
