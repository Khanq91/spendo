#!/bin/bash
# scripts/run_screenshots.sh
#
# Chạy toàn bộ pipeline: test → screenshot → report
#
# Cách dùng:
#   chmod +x scripts/run_screenshots.sh
#   ./scripts/run_screenshots.sh
#   ./scripts/run_screenshots.sh --device "emulator-5554" --out report.html

set -e

DEVICE=""
# Generated output only. The hand-curated captures live in screenshots/live_app
# and must never sit under the folder this script wipes.
SCREENSHOT_DIR="screenshots/generated"
OUT_FILE="report.html"
OPEN_BROWSER=true

# ── Parse args ───────────────────────────────────────────────────────
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --device)   DEVICE="$2";          shift ;;
    --dir)      SCREENSHOT_DIR="$2";  shift ;;
    --out)      OUT_FILE="$2";        shift ;;
    --no-open)  OPEN_BROWSER=false ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
  shift
done

# ── Colors ───────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

log()  { echo -e "${GREEN}▶${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
err()  { echo -e "${RED}✖${NC}  $1"; exit 1; }

# ── Kiểm tra môi trường ──────────────────────────────────────────────
command -v flutter &>/dev/null || err "Flutter không tìm thấy. Cài đặt tại https://flutter.dev"
command -v dart    &>/dev/null || err "Dart không tìm thấy."

log "Dọn thư mục screenshots cũ..."
rm -rf "$SCREENSHOT_DIR"
mkdir -p "$SCREENSHOT_DIR"

# ── Chọn device ─────────────────────────────────────────────────────
DEVICE_FLAG=""
if [ -n "$DEVICE" ]; then
  DEVICE_FLAG="-d $DEVICE"
  log "Dùng device: $DEVICE"
else
  log "Tự động chọn device khả dụng..."
  AVAILABLE=$(flutter devices 2>/dev/null | grep -v "^No devices" | tail -n +2 | head -1)
  if [ -z "$AVAILABLE" ]; then
    warn "Không tìm thấy device. Khởi động emulator..."
    flutter emulators --launch $(flutter emulators 2>/dev/null | awk 'NR==1{print $1}') 2>/dev/null || true
    sleep 5
  fi
fi

# ── Chạy integration test ────────────────────────────────────────────
log "Chạy Flutter integration test..."
SCREENSHOT_DIR="$SCREENSHOT_DIR" flutter drive \
  --no-pub \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshot_test.dart \
  $DEVICE_FLAG \
  --dart-define=SCREENSHOT_DIR="$SCREENSHOT_DIR" \
  --dart-define=SCREENSHOT_SEED_DATA=true \
  2>&1 | tee /tmp/flutter_test.log

if [ ${PIPESTATUS[0]} -ne 0 ]; then
  err "Integration test thất bại. Xem log ở /tmp/flutter_test.log"
fi

# ── Lấy screenshot từ device (nếu dùng --screenshot-path) ───────────
# Flutter 3.x: ảnh lưu vào $SCREENSHOT_DIR qua binding.takeScreenshot()
# Nếu cần pull từ device:
# adb pull /sdcard/Android/data/<package>/files/screenshots/ "$SCREENSHOT_DIR/" 2>/dev/null || true

# -- Generate HTML report ─────────────────────────────────────────────
log "Tạo HTML report..."
dart scripts/generate_report.dart --dir="$SCREENSHOT_DIR" --out="$OUT_FILE"

echo ""
echo -e "${GREEN}✅ Hoàn thành!${NC}"
echo "   Report: $OUT_FILE"
echo "   Ảnh:    $SCREENSHOT_DIR/"

# ── Mở browser ──────────────────────────────────────────────────────
if [ "$OPEN_BROWSER" = true ]; then
  if command -v open &>/dev/null; then
    open "$OUT_FILE"           # macOS
  elif command -v xdg-open &>/dev/null; then
    xdg-open "$OUT_FILE"       # Linux
  elif command -v start &>/dev/null; then
    start "$OUT_FILE"          # Windows
  fi
fi
