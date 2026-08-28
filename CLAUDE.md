# MiniWallet — правила для агентов

Учебный проект: SwiftUI, только мок-данные. Без бэкенда, без сети, без авторизации,
без сторонних зависимостей (SPM не подключать).

## Контракт
- Общие модели и стор (контракт Core) команда создаёт сама отдельным согласованным PR
  в начале работы. После мержа контракт ЗАМОРОЖЕН: не редактировать. Если контракта
  не хватает — остановись и скажи об этом человеку; изменение — только отдельным PR,
  заранее согласованным в чате команды.
- `mini-wallet.xcodeproj/project.pbxproj` НИКОГДА не редактировать. Новые .swift-файлы
  просто кладутся в папку внутри `mini-wallet/mini-wallet/` — Xcode подхватывает их
  автоматически (synchronized folders). Ничего «добавлять в проект» не нужно.

## Карта владения
| Папка | Владелец |
|---|---|
| `mini-wallet/mini-wallet.xcodeproj/`, корневые файлы проекта | aerowow (только через согласование) |
| `mini-wallet/mini-wallet/Features/Accounts/` | Dev 1 (ветка `feature/accounts`) |
| `mini-wallet/mini-wallet/Features/Transfer/` | Dev 2 (ветка `feature/transfer`) |
| `mini-wallet/mini-wallet/Features/History/` | Dev 3 (ветка `feature/history`) |
| `docs/specs/` | PM (ветка `docs/spec`) |
| `sessions/<login>/`, `workflows/` | каждый пишет только в свои файлы |

Чужие папки не трогать даже «по мелочи» — это ломает параллельную работу.

## Процесс
- Ветки: `feature/accounts`, `feature/transfer`, `feature/history`, `docs/spec`.
  Прямые пуши в `main` запрещены (branch protection).
- Любое изменение — через PR по шаблону, минимум 1 approve от другого участника.
- Перед PR: сборка `xcodebuild -project mini-wallet/mini-wallet.xcodeproj -scheme mini-wallet
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`.
- Лог каждой рабочей сессии — файл в `sessions/<github-login>/` (формат в sessions/README.md).
- Markdown-файлы внутрь `mini-wallet/mini-wallet/` не класть (попадут в бандл приложения);
  документы — в `docs/`.

## Данные и стиль
- Только мок-данные. Деньги — только `Decimal`, никаких Double.
- UI-тексты на русском.
- Никаких секретов, ключей, `.env`, личных данных в репозитории.
