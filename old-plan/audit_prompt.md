Perform a full Clone Blueprint audit of the Spendo Flutter project.
Work through the reading priority order defined in AGENTS.md.

For each section below, read the relevant source files first, then document findings.

---

## Constraints
- Read no more than 3 files before documenting that section.
- After every 3 sections, write partial output to CLONE_BLUEPRINT.md (append mode).
- Do not re-read files already read.

## AUDIT SECTIONS

### [1] TECH STACK & PUBSPEC
Read `pubspec.yaml`. List every dependency with its version and exact role in the app.
Flag any dependency that is non-trivial to set up (native plugin, OAuth, paid SDK).

### [2] PROJECT STRUCTURE
Read the top-level `lib/` folder tree. Explain the architecture pattern being used.
Map every subfolder to its responsibility.

### [3] FEATURE INVENTORY
For each folder inside `lib/features/`:
- Feature name
- Screens involved (list widget file names)
- Riverpod providers used (list provider names and types)
- PowerSync tables or Supabase tables touched
- Navigation routes used
- Complexity: Low / Medium / High

### [4] DATA MODELS
Read all model/entity classes. For each:
- Class name & file path
- All fields with types
- Whether it maps to a PowerSync local table, Supabase table, or both
- Serialization method (fromJson/toJson, freezed, json_serializable)

### [5] POWERSYNC SCHEMA
Find the PowerSync schema definition. List every table:
- Table name
- Columns with types
- Sync rules or filters (if defined)

### [6] SUPABASE INTEGRATION
Find all Supabase client calls. Document:
- Auth flows used (email, Google, etc.)
- All tables/views queried
- RLS assumptions (any `.from()` calls that imply row-level security)
- Edge Functions called (if any)

### [7] RIVERPOD STATE ARCHITECTURE
List all providers:
- Provider name, type (Provider / StateProvider / FutureProvider / NotifierProvider / etc.)
- What state it manages
- Dependencies (which other providers it watches/reads)
- Scope (global / feature-local)

### [8] NAVIGATION & SCREEN FLOW
Read the Go Router config. Document:
- Every named route + path
- Route guards / redirects
- Which screen each route renders
- Parameters passed per route
Draw a simple ASCII flow diagram of the main navigation tree.

### [9] EXTERNAL SERVICES
For each external service (Google Drive, SePay, Supabase, any analytics):
- Service name
- Package/SDK used
- Auth method
- Which features depend on it
- Error handling strategy found in code

### [10] BACKGROUND & ASYNC OPERATIONS
Document:
- Any isolates or compute() calls
- Scheduled tasks or local notifications
- Sync triggers (when does PowerSync sync fire?)
- Background upload/download logic

### [11] THEME & DESIGN SYSTEM
Read the theme config:
- Color palette (primary, secondary, surface, error colors with hex values)
- Typography scale
- Component overrides (buttons, cards, inputs)
- Any custom widgets in shared/widgets that form a design system

### [12] CI/CD & BUILD CONFIG
Read `.github/workflows/` and any `Makefile` or scripts:
- Build steps
- Signing config
- Release process
- Environment variable injection

### [13] CODE QUALITY OBSERVATIONS
While reading:
- Note any TODO/FIXME comments (quote them with file:line)
- Note repeated patterns that should be abstracted
- Note any inconsistency in naming, structure, or patterns
- Estimate overall code consistency: Excellent / Good / Needs Work

### [14] CLONE RECOMMENDATIONS
Based on all findings above:
- Recommended stack to rebuild Spendo (same or improved)
- Phase 1 features (MVP) vs Phase 2 features
- Top 5 implementation gotchas/risks
- Estimated dev time per feature (rough, in days)

---

## FINAL OUTPUT STRUCTURE

Save to `CLONE_BLUEPRINT.md` with exactly these H2 sections:
1. TL;DR Cheatsheet (tables: stack / features+complexity / services)
2. Tech Stack & Dependencies
3. Project Structure
4. Feature Inventory
5. Data Models
6. PowerSync Schema
7. Supabase Integration
8. State Architecture (Riverpod)
9. Navigation & Screen Flow
10. External Services
11. Background & Async
12. Theme & Design System
13. CI/CD
14. Code Quality
15. Clone Recommendations

Begin now. Read files in priority order. Do not summarize from memory.