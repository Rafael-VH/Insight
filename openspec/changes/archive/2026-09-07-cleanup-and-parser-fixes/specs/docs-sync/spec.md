# Docs Sync Specification

## Purpose

No documentation, skill index, or lockfile may reference systems that no longer exist in the codebase (Supabase, the `http` package, `.agents/skills`, the removed stats_bloc test path). The behavior of the change is undetectable except by grepping these files.

## Requirements

### Requirement: Remove Supabase entries from skills-lock.json

The system MUST remove both Supabase skill entries from skills-lock.json (lines 4-15: `supabase` and `supabase-postgres-best-practices`). The lockfile MUST contain no reference to `supabase`.

#### Scenario: Lockfile is Supabase-free

- GIVEN skills-lock.json containing only the two supabase entries
- WHEN the entries are removed
- THEN grep for `supabase` (case-insensitive) in skills-lock.json returns zero matches

### Requirement: Remove the http line from the architecture skill

The system MUST remove the `HTTP Client: http package` line from `.opencode/skills/insight-architecture/SKILL.md:41`, which documents a dependency that no longer exists.

#### Scenario: Skill file matches the stack

- GIVEN the architecture skill file
- WHEN the http line is removed from the Technology Stack section
- THEN the skill's dependency list matches the actual pubspec

### Requirement: Remove Supabase and .agents/skills references from GEMINI.md

The system MUST remove the Supabase references from GEMINI.md: the local skills priority note referencing `.agents/skills` and the supabase exclusion list (lines 6-9), and the `Backend: Supabase` line (line 17).

#### Scenario: Project instructions mention only live systems

- GIVEN GEMINI.md as currently written
- WHEN the stale lines are removed
- THEN grep for `supabase` and `.agents/skills` in GEMINI.md returns zero matches

### Requirement: Remove stale stats_bloc_test references from all_tests.dart

The system MUST remove the commented-out `stats_bloc_test.dart` import (all_tests.dart:22), the commented call (all_tests.dart:41), and the doc comment referencing the file (all_tests.dart:9), since that suite does not exist.

#### Scenario: Root test file has no dangling references

- GIVEN all_tests.dart with three stale `stats_bloc_test` references
- WHEN they are removed
- THEN grep for `stats_bloc` in test/all_tests.dart returns zero matches

### Requirement: No remaining stale references in docs/

The system MUST ensure `docs/` contains no reference to removed modules or packages. The only current file (`docs/funcionalidades-recomendadas.md`) is empty; the end state after the change MUST satisfy a repo-wide grep for `supabase`, `heroes`, `todos_page`, `http package` over doc files.

#### Scenario: Doc tree is stale-reference-free

- GIVEN `docs/` and GEMINI.md
- WHEN grep runs for `supabase|heroes|todos_page|stats_bloc` (case-insensitive) over both
- THEN zero matches remain

## Acceptance Criteria

- `git grep -i -E "supabase|heroes|todos_page|stats_bloc"` over documentation, lockfile, and skill files returns zero matches
- Note: GEMINI.md, docs/, and openspec/ are untracked; committing their edited state is at the user's discretion per the proposal (Out of Scope: "Committing untracked artifacts")