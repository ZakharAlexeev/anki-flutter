# anki_flutter

A local-first spaced-repetition flashcard app for iOS and Windows, compatible
with Anki's `.apkg` export format.

## Features

- Deck / note type / card CRUD, with a "Basic" and "Basic (and reversed
  card)" note type seeded on first launch.
- FSRS-6 scheduling with Anki-style learning/relearning steps, per-deck
  desired retention, stability/difficulty memory state, interval fuzz,
  leech detection, and daily new/review limits. Existing review history is
  replayed when migrating cards that predate FSRS state storage.
- `.apkg` import and export, including full scheduling state (interval,
  ease, due date, lapses, review history) - not just the notes/cards
  themselves. Import supports both the legacy JSON-based collection schema
  and the current protobuf-based one (schema v18+), and merges into an
  existing local collection by deck/note-type name rather than overwriting
  it.
- A statistics screen (today's counts, review forecast/history, card-status
  and interval/ease distributions) per deck or for the whole collection.
- Collection-wide duplicate search using the normalized first field, with
  safe removal of duplicate notes and their scheduling history.
- Card template rendering: field substitution, field modifiers
  (`{{text:}}`, `{{furigana:}}`, `{{hint:}}`, ...), conditional sections,
  the note type's own CSS, and local media (images inlined, audio flagged).

## Development

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

`build_runner` regenerates `lib/data/db/database.g.dart` from the Drift
table definitions in `lib/data/db/tables.dart` - run it again after editing
those.

## Project layout

- `lib/domain/scheduler/` - the pure scheduling algorithm and day-number
  calendar math, independent of persistence.
- `lib/domain/template_renderer.dart` - Anki card-template rendering.
- `lib/data/db/` - Drift (SQLite) schema and generated database code.
- `lib/data/import/`, `lib/data/export/` - `.apkg` read/write.
- `lib/data/repositories/` - the bridge between the pure scheduler/renderer
  and persisted state.
- `lib/ui/` - screens, organized by feature (decks, study, editor, stats,
  import, export).

## CI

`.github/workflows/ci.yml` runs `flutter analyze` and `flutter test` on
every push/PR touching `anki_flutter/`. `.github/workflows/ios-ipa.yml`
builds an unsigned iOS `.ipa` (no Apple Developer account needed) for
sideloading via AltStore/AltServer.
