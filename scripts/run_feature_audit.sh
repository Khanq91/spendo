#!/bin/bash
# run_feature_audit.sh
# Audit từng feature folder riêng biệt, append vào CLONE_BLUEPRINT.md

set -e

BLUEPRINT="audit/CLONE_BLUEPRINT.md"
FEATURES_DIR="lib/features"

# Danh sách features (auto-detect hoặc hardcode)
FEATURES=$(ls "$FEATURES_DIR")

echo "🔍 Found features: $FEATURES"
echo ""

for feature in $FEATURES; do
  FEATURE_PATH="$FEATURES_DIR/$feature"
  echo "📦 Auditing: $feature..."

  codex \
  --sandbox workspace-write \
  --ask-for-approval never \
  exec \
  -C . \
"
You are auditing ONE feature of the Spendo Flutter app.

Feature path: $FEATURE_PATH

Instructions:
1. List ALL .dart files inside $FEATURE_PATH (recursive).
2. Read EVERY file inside $FEATURE_PATH.
3. Do NOT read files outside $FEATURE_PATH.
4. Document the following and append to $BLUEPRINT:

## Feature: $feature

### Files Involved
List all files with 1-line descriptions.

### What It Does
User-facing description of the feature.

### Screens & Widgets
List every screen/widget class found. Include file path.

### Riverpod Providers
For each provider found:
- Name, type (Provider/Notifier/FutureProvider/etc.)
- What state it manages

### Data Flow
Input → processing steps → output/side-effects

### PowerSync / Supabase Tables Touched
List exact table names referenced in this feature.

### Navigation
Routes used, how user enters/exits this feature.

### Complexity Rating
Low / Medium / High — with 1-sentence justification.

### TODOs / Known Issues
Quote any TODO or FIXME comments found (with file:line).

---
Append this section to: $BLUEPRINT
Do NOT overwrite. Use append mode (>>).
"

  echo "✅ Done: $feature"
  sleep 2  # throttle
done

echo ""
echo "🎉 All features audited → $BLUEPRINT"