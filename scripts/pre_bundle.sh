#!/bin/bash
# pre_bundle.sh
# Gom toàn bộ context cần thiết vào 1 file để Codex đọc 1 lần

set -e

BUNDLE="audit/context_bundle.md"
mkdir -p audit
echo "# Spendo Context Bundle — $(date)" > "$BUNDLE"

separator() {
  echo -e "\n\n---\n## $1\n" >> "$BUNDLE"
}

# ── 1. File tree ──────────────────────────────────────────────
separator "FILE TREE (lib/)"
find lib/ \
  -type f \
  -name "*.dart" \
  ! -name "*.g.dart" \
  ! -name "*.freezed.dart" \
  ! -name "*.gr.dart" \
  ! -name "*.mocks.dart" \ | sort >> "$BUNDLE"

separator "FILE TREE (non-dart config)"
find . -maxdepth 3 \( -name "*.yaml" -o -name "*.json" -o -name "*.env*" \) \
  ! -path "*/node_modules/*" ! -path "*/.dart_tool/*" \
  ! -path "*/build/*" | sort >> "$BUNDLE"

# ── 2. Dependencies ───────────────────────────────────────────
separator "pubspec.yaml"
cat pubspec.yaml >> "$BUNDLE"

# ── 3. Entry point ────────────────────────────────────────────
separator "main.dart"
cat lib/main.dart >> "$BUNDLE"

# ── 4. Router (go_router) ─────────────────────────────────────
separator "ROUTER FILES"
find lib/ \( -name "*router*" -o -name "*route*" -o -name "*go_router*" \) \
  -name "*.dart" \
  ! -name "*.g.dart" \
  ! -name "*.freezed.dart" \
  ! -name "*.gr.dart" \
  ! -name "*.mocks.dart" | while read f; do
  echo -e "\n### $f" >> "$BUNDLE"
  cat "$f" >> "$BUNDLE"
done

# ── 5. All models / entities ──────────────────────────────────
separator "DATA MODELS"
find lib/ \( -path "*/model*" -o -path "*/entity*" -o -path "*/dto*" \) \
  -name "*.dart" \
  ! -name "*.g.dart" \
  ! -name "*.freezed.dart" \
  ! -name "*.gr.dart" \
  ! -name "*.mocks.dart" | while read f; do
  echo -e "\n### $f" >> "$BUNDLE"
  cat "$f" >> "$BUNDLE"
done

# ── 6. PowerSync schema ───────────────────────────────────────
separator "POWERSYNC SCHEMA"
find lib/ -name "*schema*" -o -name "*powersync*" | grep "\.dart$" | while read f; do
  echo -e "\n### $f" >> "$BUNDLE"
  cat "$f" >> "$BUNDLE"
done

# ── 7. Supabase client / service ─────────────────────────────
separator "SUPABASE INTEGRATION FILES"
find lib/ \( -name "*supabase*" -o -name "*database*" -o -name "*db*" \) \
  -name "*.dart" \
  ! -name "*.g.dart" \
  ! -name "*.freezed.dart" \
  ! -name "*.gr.dart" \
  ! -name "*.mocks.dart" | while read f; do
  echo -e "\n### $f" >> "$BUNDLE"
  cat "$f" >> "$BUNDLE"
done

# ── 8. All providers ─────────────────────────────────────────
separator "RIVERPOD PROVIDERS"
find lib/ -name "*provider*" \
  -name "*.dart" \
  ! -name "*.g.dart" \
  ! -name "*.freezed.dart" \
  ! -name "*.gr.dart" \
  ! -name "*.mocks.dart" | while read f; do
  echo -e "\n### $f" >> "$BUNDLE"
  cat "$f" >> "$BUNDLE"
done

# ── 9. Theme / design system ─────────────────────────────────
separator "THEME & DESIGN SYSTEM"
find lib/ \( -name "*theme*" -o -name "*color*" -o -name "*style*" \) \
  -name "*.dart" \
  ! -name "*.g.dart" \
  ! -name "*.freezed.dart" \
  ! -name "*.gr.dart" \
  ! -name "*.mocks.dart" | while read f; do
  echo -e "\n### $f" >> "$BUNDLE"
  cat "$f" >> "$BUNDLE"
done

# ── 10. CI/CD ────────────────────────────────────────────────
separator "CI/CD WORKFLOWS"
find .github/ -name "*.yml" 2>/dev/null | while read f; do
  echo -e "\n### $f" >> "$BUNDLE"
  cat "$f" >> "$BUNDLE"
done

# ── 11. Feature list (tên folder thôi) ───────────────────────
separator "FEATURE FOLDERS"
ls lib/features/ 2>/dev/null || echo "No features/ folder found" >> "$BUNDLE"

# ── Stats ─────────────────────────────────────────────────────
LINES=$(wc -l < "$BUNDLE")
SIZE=$(du -sh "$BUNDLE" | cut -f1)
echo ""
echo "✅ Bundle created: $BUNDLE"
echo "   Lines: $LINES | Size: $SIZE"