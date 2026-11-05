# AGENTS.md

Single-package Flutter app (`name: tapes`): a daily journal stored locally with Hive. There is no CI, pre-commit hook, or task runner, so verification is manual.

## Toolchain
- Verified with Flutter 3.38.0 (stable) and Dart 3.10, the revision recorded in `.metadata`. `pubspec.yaml` requires `sdk: ^3.10.0-290.4.beta`.
- Trust `pubspec.yaml`, `analysis_options.yaml` (flutter_lints), and `lib/` over the README. The README (Indonesian) calls codegen optional. It is required.

## Commands
On a fresh clone, run these in order. Analyze and test fail until codegen has run.
1. `flutter pub get`
2. `dart run build_runner build -d`
   - Generates `lib/note.g.dart`, which is gitignored and absent from a clone. Without it the app does not compile.
   - Keep `-d` (`--delete-conflicting-outputs`). Without it, build_runner prompts before overwriting outputs it does not recognize, and non-interactive shells cannot answer.
3. `flutter analyze`. Baseline: 1 info, `avoid_print` at `lib/content.dart:141`.
4. `flutter test`. Baseline: fails (see Testing).
- Single file: `flutter test test/widget_test.dart`. Single test: `flutter test --plain-name "<name>"`.
- Run: `flutter run -d linux` or `flutter run -d chrome`.
- Do not run `dart format` on the whole tree: 8 of 11 Dart files in `lib/` and `test/` would change. Format only files you edit, if at all.

## Testing
- `test/widget_test.dart` is the stock counter test. It fails at baseline because the app has no counter.
- `HomePage` and `ListTape` call `Hive.box('notebox')` in `initState`. Any test that pumps `InderPage` or either screen must open `notebox` first.

## Data and models
- Hive box `notebox` stores `Note.toMap()` maps keyed by note id. Read them with `Note.fromMap(Map<String, dynamic>.from(data))`. Store maps, not `Note` objects. `NoteAdapter` is registered in `main()` but not used for storage.
- Data lives on user devices and there are no migrations. Do not change `typeId: 0`, the `@HiveField` indexes, the map keys, or the `createdAt` string format without a migration.
- `lib/note.g.dart` is generated ("DO NOT MODIFY BY HAND"). Rerun codegen after editing `lib/note.dart`.

## Structure
- `lib/main.dart` initializes Hive, registers `NoteAdapter`, opens `notebox`, and runs `MaterialApp(home: InderPage)`.
- `lib/index.dart` (`InderPage`) is a 3-tab NavigationBar: `home.dart` (calendar and progress), `content.dart` (write note), `listtape.dart` (list, uses `listcard.dart`).
- Use `Hive.box('notebox')`. The global `box` in `lib/box.dart` is assigned in `main()` but never read.
- Not part of the app: `lib/service.dart` is empty, and `lib/config/`, `lib/core/`, `lib/features/` are empty directories that git does not track.
- No routes or theme. Colors and text styles are inline in each widget.
- UI reference: `desain yang harus di tiru sama persis.png` (the design to match exactly), at repo root.

## Conventions and gotchas
- New user-facing strings are Indonesian. Do not translate existing English strings unless asked.
- Dates: no locale data is initialized, so `DateFormat` output is en_US (English day and month names). For Indonesian dates, `await initializeDateFormatting('id')` (from `package:intl/date_symbol_data_local.dart`) in `main()` before using `'id'`. Otherwise intl throws `LocaleDataException`.
- `fontFamily: 'inter'` (in `content.dart`, `listcard.dart`) has no declared or bundled font. Text falls back to the default font.
- `assets/logo.png` is not listed under `flutter: assets:` in `pubspec.yaml`, so it is not bundled. It is used only by the `flutter_icons:` config.
- Android release builds are signed with the debug key and use the placeholder applicationId `com.example.tapes` (TODOs in `android/app/build.gradle.kts`).


## Behavioral Guidelines & Decision Protocols

1. Simplicity First
- Minimum code that solves the problem. No unrequested helpers, abstractions, or error handling for impossible scenarios.
- Example: If asked to format a date, write one pure function in-place. Do NOT create an abstract DateService with dependency injection.

2. Surgical Changes (Zero Tolerance on Adjacent Edits)
- Touch ONLY what was requested.
- BAD:
  - Fixing indentation or reordering imports in unedited sections.
  - Deleting unused legacy files (`service.dart`, empty folders).
  - Running global `dart format`.
- GOOD:
  - Every line in `git diff` traces 100% directly to the user's prompt.
- Hard Invariant: `notebox` stores Maps, not Note objects. Never touch `typeId: 0` or `@HiveField`.

3. Goal-Driven Execution Loop
- Transform tasks into verifiable checks BEFORE coding:
  - "Perbaiki save path" -> Plan: edit `lib/content.dart` -> verify: `flutter analyze` (0 issues).
  - "Edit model" -> Plan: edit `lib/note.dart` -> verify: `dart run build_runner build -d` -> `flutter analyze`.

4. Uncertainty Escalation Gate (Tiered Kepo Protocol)
- Routine/Low-Impact: Make provisional micro-decisions and execute directly.
- High-Impact Trigger (modifying database schema, deleting files, changing pubspec.yaml):
  MANDATORY: Invoke tool `read_file` on `.opencode/skills/kepo.md` BEFORE taking action.

Reference: Minimal diff style patterns are documented in `examples.md`. Consult ONLY if unsure how to format surgical diffs.