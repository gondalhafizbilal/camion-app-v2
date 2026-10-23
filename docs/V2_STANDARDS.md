# Camion V2 Standards Baseline

## 1. Flavoring

- Keep all run/build commands flavor-explicit.
- Use dedicated app ids per flavor.
- Store per-flavor Firebase files under `android/app/src/<flavor>/google-services.json`.
- Keep per-flavor env files:
  - `.env.development`
  - `.env.production`

## 2. App Bootstrap

- Use a single bootstrap pipeline in `lib/bootstrap.dart`.
- Initialize in this order:
  1. Flutter binding
  2. app config (`AppConfig`)
  3. DI (`setupServiceLocator`)
  4. cache and migration defaults
  5. env loading
  6. `runApp`
  7. async post-bootstrap (Firebase, notifications, guest id)

## 3. API Standards

- Read base URLs from `AppConfig`, not hardcoded `kDebugMode` checks.
- Keep a single API consumer (`DioConsumer`) registered in DI.
- Log network traffic only when `ENABLE_NETWORK_LOGS=true` or debug default.
- Inject common request context centrally (guest id, language, currency).

## 4. Localization Standards

- Keep localization state centralized in `LocalizationsCubit`.
- Avoid direct hardcoded strings for user-facing copy in new V2 screens.
- Add all new copy to AR/EN localization resources before UI merge.

## 5. Routing Standards

- Keep route names centralized under `AppRouter`.
- Avoid direct navigation strings in feature code.
- For guarded routes, use a single source of truth in router generation.

## 6. Feature Layering

- Keep feature boundaries:
  - `data` (models/repositories/data-sources)
  - `presentation` (screens/widgets/state)
  - `logic` (cubits/use-cases if introduced)
- Keep cross-feature utilities under `core`.

## 7. Quality Gates

- Required before merging V2 chunks:
  - `flutter analyze`
  - smoke run in `development` flavor
  - smoke run in `production` flavor
  - manual check for localization fallback and currency formatting
