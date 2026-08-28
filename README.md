# Mini Wallet

Учебное командное задание (ДЗ №2 курса по AI-агентам): мини-кошелёк на SwiftUI
с мок-данными. Три экрана — счета, перевод с идемпотентностью, история операций.
Без бэкенда и авторизации. Вся работа велась через AI-агентов, параллельными
субагентами, с PR-флоу и кросс-ревью.

## Как запустить
Нужен Xcode с поддержкой проекта (см. deployment target в настройках таргета).

    git clone https://github.com/aerowow/mini-wallet.git
    cd mini-wallet
    open mini-wallet/mini-wallet.xcodeproj   # затем Cmd+R на любом симуляторе iPhone

Проверка сборки из терминала:

    xcodebuild -project mini-wallet/mini-wallet.xcodeproj -scheme mini-wallet \
      -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build

## Команда: кто что делал
| Участник | GitHub | Роль | Что сделал | Ветка |
|---|---|---|---|---|
| | aerowow | Владелец репо, bootstrap, Dev 1 | Проект, структура, процесс; экран счетов | main (bootstrap), feature/accounts |
| | | Dev 2 | Перевод с идемпотентностью | feature/transfer |
| | | Dev 3 | История, фильтры, поиск | feature/history |
| | | PM | ТЗ на три экрана + финальный PDF | docs/spec |

## Структура
- `mini-wallet/` — Xcode-проект; `mini-wallet/mini-wallet/Features/` — по папке на разработчика
- `docs/specs/` — ТЗ от PM, `docs/` — итоговый PDF (`docs/MiniWallet-specs.pdf`)
- `design/` — макеты (pen.dev)
- `sessions/` — журналы сессий с агентами (промпты дословно)
- `workflows/` — сохранённые workflow каждого участника (минимум один на человека)
- `REPORT.md` — отчёт: что делали, что не сработало, замеры
- `CLAUDE.md` — правила для агентов, `.github/pull_request_template.md` — шаблон PR
