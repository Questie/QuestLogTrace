# QuestLogTrace Specs

This folder defines how to read QuestLogTrace saved data and reconstruct function outputs over time.

Use these files together:

- `specs/SCHEMA_SPEC.md`
  - Exact table layout for `QuestLogTrace` and `QuestLogTraceCharacter`.
  - Field-level meaning for each capture stream.
- `specs/FUNCTION_EMULATION_SPEC.md`
  - How to rebuild API/function values at a target timestamp.
  - Time normalization and lookup rules.
- `specs/EVENT_CATALOG.md`
  - Event categories and event names currently tracked by the addon.

Versioning:

- Current data schema version: `6`
- Saved in `QuestLogTrace.schemaVersion`
