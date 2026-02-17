# UI Architecture and Visual Language

## 1. Architecture Pattern (MVVM)

Use MVVM for all page-level screens.

- `View`: Compose SwiftUI layout and forward user intents.
- `ViewModel`: Own UI state, derived display state, async side effects, and business-flow decisions.
- `Model`: SwiftData domain models and repository/service abstractions.

Rules:

- Page-level views should not embed repository business logic directly.
- View models should expose intent methods such as `save`, `refresh`, `toggle`, `dismiss`, and `sync`.
- Views should prefer bindings to `@StateObject` / `@ObservedObject` view model properties.

## 2. Folder Structure

Use feature-first organization.

- `UI/<Feature>/Views/<Feature>View.swift` for main page view.
- `UI/<Feature>/Views/Components/` for reusable child views used by that page.
- `UI/<Feature>/ViewModels/` for view model types.
- Keep domain-only utilities in `UI/<Feature>/Models/` only when they are not views.

When a view grows beyond a few cohesive sections, split those sections into component views.

## 3. Preview Standard

Every SwiftUI view file must include at least one `#Preview`.

- Use `PreviewFixtures` for sample model objects and in-memory model containers.
- Main pages that depend on `@Query` should use:
  - `PreviewFixtures.inMemoryContainerWithSeedData()`
- Component previews should be lightweight and isolated.

## 4. Visual Language

Preserve the app’s established style direction.

- Use `DeferTheme` for palette, spacing, and semantic colors.
- Keep card surfaces using `glassCard()` or equivalent rounded translucent surfaces.
- Maintain atmospheric background layers (soft gradients + blurred radial shapes).
- Avoid introducing unrelated typography systems; use the existing SF-based styling conventions.

## 5. Interaction Standards

- Use `AppHaptics` for key toggles, state transitions, and confirmations.
- Keep destructive actions explicit and confirmed.
- Keep accessibility labels/hints on tappable custom controls and badges.

## 6. Naming and Responsibility

- Name page view models as `<Feature>ViewModel`.
- Name child components with feature prefix (`Home...`, `Achievement...`, `History...`).
- Keep business rules in repositories/services or view models, not deeply nested in rendering code.

## 7. Refactor Checklist

Before finalizing UI changes:

1. Confirm MVVM ownership is clear.
2. Confirm large sections are extracted to `Views/Components`.
3. Confirm every view file has a `#Preview`.
4. Confirm colors/spacing use `DeferTheme`.
5. Confirm no duplicated business logic was introduced.
