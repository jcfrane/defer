# Defer Agent Rules

- Before making UI changes, read `/Users/jcfrane/projects/Defer/Defer/Docs/UI_ARCHITECTURE_AND_VISUAL_LANGUAGE.md`.
- Follow MVVM for every page-level screen (`Content`, `Home`, `Achievements`, `History`, `Settings`, `DeferForm`, `DeferDetail`).
- Keep feature files organized as:
  - `UI/<Feature>/Views/<MainView>.swift`
  - `UI/<Feature>/Views/Components/*.swift`
  - `UI/<Feature>/ViewModels/*.swift`
- Every SwiftUI view file must include a working `#Preview`.
- Use `DeferTheme` tokens for colors, spacing, and card styles to preserve visual consistency.
