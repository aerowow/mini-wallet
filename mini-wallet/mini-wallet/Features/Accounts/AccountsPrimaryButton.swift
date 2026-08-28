import SwiftUI

/// Главная акцентная кнопка экрана «Счета» («Перевести»).
/// Выключенность управляется стандартным `.disabled(true)` на месте вызова.
/// Префикс Accounts обязателен: все Features собираются в один модуль,
/// и без него тип столкнётся с одноимённым у других фич.
struct AccountsPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(AccountsPrimaryButtonStyle())
    }
}

/// Стиль главной кнопки: акцентная заливка, белый текст,
/// приглушение при нажатии и в выключенном состоянии.
private struct AccountsPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AccountsDesign.bodySemiboldFont)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AccountsDesign.buttonHeight)
            .background(
                isEnabled ? AccountsDesign.accent : AccountsDesign.accent.opacity(0.4),
                in: .rect(cornerRadius: AccountsDesign.buttonCornerRadius)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

#Preview {
    VStack(spacing: AccountsDesign.sectionSpacing) {
        AccountsPrimaryButton(title: "Перевести") {}
        AccountsPrimaryButton(title: "Перевести") {}
            .disabled(true)
    }
    .padding(.horizontal, AccountsDesign.screenHPadding)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AccountsDesign.screenBackground)
}
