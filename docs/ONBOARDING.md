# Онбординг участника

## 1. Клонируй и проверь git-подпись
    git clone https://github.com/aerowow/mini-wallet.git
    cd mini-wallet
    git config user.name    # должно быть твоё имя
    git config user.email   # твой email (по коммитам собирается «кто что делал»)

Если пусто или чужое: `git config user.name "Имя"` и `git config user.email "you@example.com"`.
Email должен быть привязан к твоему GitHub-аккаунту (Settings → Emails), иначе коммиты
не засчитаются в Contributors. Принять приглашение в репозиторий (письмо от GitHub) —
иначе не сможешь пушить и ревьюить.

## 2. Собери и запусти
`open mini-wallet/mini-wallet.xcodeproj`, симулятор iPhone, Cmd+R.
Терминал:
    xcodebuild -project mini-wallet/mini-wallet.xcodeproj -scheme mini-wallet \
      -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build

## 3. Создай свою ветку
    git checkout -b feature/accounts   # Dev 1
    git checkout -b feature/transfer   # Dev 2
    git checkout -b feature/history    # Dev 3
    git checkout -b docs/spec          # PM

## 4. Правила (подробно — в CLAUDE.md)
- Работаешь только в своей папке `mini-wallet/mini-wallet/Features/<твоя>`.
  Общий контракт и `project.pbxproj` не трогаешь.
- Новые .swift-файлы просто клади в свою папку — проект подхватит сам.
- В `main` — только через PR по шаблону + 1 approve другого участника.
- Каждая сессия с агентом — лог в `sessions/<твой-login>/`, свой workflow — в `workflows/`.
- Прочитай своё ТЗ в `docs/specs/` до начала работы; вопросы к контракту — в чат,
  не «дописать по-тихому».
