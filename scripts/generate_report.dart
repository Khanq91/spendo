#!/usr/bin/env dart
// scripts/generate_report.dart
//
// Đọc screenshots/ + meta.json → tạo file report.html
//
// Cách chạy:
//   dart scripts/generate_report.dart
//   dart scripts/generate_report.dart --dir=screenshots --out=report.html

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  // ── Parse args ──────────────────────────────────────────────────────
  String screenshotDir = 'screenshots';
  String outputFile = 'report.html';

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--dir=')) {
      screenshotDir = arg.substring(6);
    } else if (arg == '--dir' && i + 1 < args.length) {
      screenshotDir = args[++i];
    } else if (arg.startsWith('--out=')) {
      outputFile = arg.substring(6);
    } else if (arg == '--out' && i + 1 < args.length) {
      outputFile = args[++i];
    }
  }

  // ── Đọc meta.json ───────────────────────────────────────────────────
  final metaFile = File('$screenshotDir/meta.json');
  if (!metaFile.existsSync()) {
    stderr.writeln('❌ Không tìm thấy $screenshotDir/meta.json');
    stderr.writeln('   Hãy chạy integration test trước:');
    stderr.writeln(
        '   flutter test integration_test/screenshot_test.dart');
    exit(1);
  }

  final List<dynamic> screens = jsonDecode(metaFile.readAsStringSync());

  // ── Encode ảnh thành base64 ─────────────────────────────────────────
  final cards = StringBuffer();
  int count = 0;

  for (final screen in screens) {
    final id = screen['id'] as String;
    final title = screen['title'] as String;
    final description = screen['description'] as String;
    final file = screen['file'] as String;

    final imgFile = File('$screenshotDir/$file');
    String imgSrc;
    if (imgFile.existsSync()) {
      final bytes = imgFile.readAsBytesSync();
      final b64 = base64Encode(bytes);
      imgSrc = 'data:image/png;base64,$b64';
    } else {
      // Placeholder nếu ảnh chưa có
      imgSrc = 'data:image/svg+xml;base64,${base64Encode(utf8.encode(_placeholder(title)))}';
    }

    count++;
    cards.write('''
      <div class="card" id="card-$id">
        <div class="badge">$count</div>
        <div class="phone-frame">
          <div class="phone-notch"></div>
          <img class="screen-img" src="$imgSrc" alt="$title" loading="lazy" />
        </div>
        <div class="card-info">
          <h3>$title</h3>
          <p>$description</p>
          <span class="chip">$id</span>
        </div>
      </div>
''');
  }

  // ── Tạo HTML ────────────────────────────────────────────────────────
  final now = DateTime.now();
  final timestamp =
      '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

  final html = _buildHtml(
    cards: cards.toString(),
    count: count,
    timestamp: timestamp,
  );

  File(outputFile).writeAsStringSync(html);
  stdout.writeln('✅ Report tạo thành công: $outputFile ($count màn hình)');
  stdout.writeln('   Mở file trong trình duyệt để xem.');
}

// ── HTML template ────────────────────────────────────────────────────
String _buildHtml({
  required String cards,
  required int count,
  required String timestamp,
}) =>
    '''<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>App Screenshot Report</title>
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  :root {
    --bg: #f8f7f4;
    --surface: #ffffff;
    --border: #e4e2dc;
    --text: #1a1a18;
    --text-muted: #6b6b66;
    --accent: #6c63ff;
    --accent-light: #ededfd;
    --radius: 16px;
    --phone-w: 200px;
    --phone-h: 420px;
  }

  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #18181a;
      --surface: #232326;
      --border: #38383c;
      --text: #f0efea;
      --text-muted: #9b9b94;
      --accent-light: #2a2850;
    }
  }

  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    background: var(--bg);
    color: var(--text);
    min-height: 100vh;
  }

  header {
    padding: 40px 32px 32px;
    border-bottom: 1px solid var(--border);
    display: flex;
    align-items: flex-end;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 12px;
  }

  header h1 {
    font-size: 26px;
    font-weight: 700;
    letter-spacing: -0.5px;
  }

  header h1 span {
    color: var(--accent);
  }

  .meta {
    font-size: 13px;
    color: var(--text-muted);
    line-height: 1.8;
    text-align: right;
  }

  .search-bar {
    padding: 20px 32px;
    border-bottom: 1px solid var(--border);
    display: flex;
    gap: 10px;
    align-items: center;
  }

  .search-bar input {
    flex: 1;
    max-width: 360px;
    padding: 9px 14px;
    border: 1px solid var(--border);
    border-radius: 8px;
    background: var(--surface);
    color: var(--text);
    font-size: 14px;
    outline: none;
    transition: border-color .15s;
  }

  .search-bar input:focus { border-color: var(--accent); }

  .count-badge {
    font-size: 13px;
    color: var(--text-muted);
    margin-left: auto;
  }

  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
    gap: 24px;
    padding: 32px;
  }

  .card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    overflow: hidden;
    transition: transform .15s, box-shadow .15s;
    position: relative;
    cursor: default;
  }

  .card:hover {
    transform: translateY(-3px);
    box-shadow: 0 8px 24px rgba(0,0,0,.10);
  }

  .badge {
    position: absolute;
    top: 12px;
    left: 12px;
    background: var(--accent);
    color: #fff;
    font-size: 11px;
    font-weight: 700;
    width: 24px;
    height: 24px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 2;
  }

  .phone-frame {
    background: #1a1a1e;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 28px 0 20px;
    position: relative;
  }

  .phone-notch {
    position: absolute;
    top: 8px;
    left: 50%;
    transform: translateX(-50%);
    width: 80px;
    height: 6px;
    background: #333;
    border-radius: 3px;
  }

  .screen-img {
    width: var(--phone-w);
    height: var(--phone-h);
    object-fit: cover;
    object-position: top;
    border-radius: 8px;
    display: block;
    border: 1px solid #333;
  }

  .card-info {
    padding: 18px 20px 20px;
  }

  .card-info h3 {
    font-size: 15px;
    font-weight: 600;
    margin-bottom: 6px;
  }

  .card-info p {
    font-size: 13px;
    color: var(--text-muted);
    line-height: 1.6;
    margin-bottom: 12px;
  }

  .chip {
    display: inline-block;
    background: var(--accent-light);
    color: var(--accent);
    font-size: 11px;
    font-family: monospace;
    padding: 3px 8px;
    border-radius: 4px;
    font-weight: 600;
  }

  .hidden { display: none !important; }

  footer {
    text-align: center;
    padding: 32px;
    font-size: 12px;
    color: var(--text-muted);
    border-top: 1px solid var(--border);
  }
</style>
</head>
<body>

<header>
  <div>
    <h1>App <span>Screenshots</span></h1>
  </div>
  <div class="meta">
    <div>Tổng: <strong>$count</strong> màn hình</div>
    <div>Tạo lúc: $timestamp</div>
  </div>
</header>

<div class="search-bar">
  <input
    type="text"
    id="search"
    placeholder="Tìm màn hình theo tên hoặc mô tả..."
    oninput="filterCards(this.value)"
    autocomplete="off"
  />
  <span class="count-badge" id="result-count">$count kết quả</span>
</div>

<div class="grid" id="grid">
$cards
</div>

<footer>Được tạo tự động bởi Flutter Screenshot Tool</footer>

<script>
  function filterCards(query) {
    const q = query.toLowerCase().trim();
    const cards = document.querySelectorAll('.card');
    let visible = 0;
    cards.forEach(card => {
      const text = card.textContent.toLowerCase();
      const match = !q || text.includes(q);
      card.classList.toggle('hidden', !match);
      if (match) visible++;
    });
    document.getElementById('result-count').textContent =
      visible + ' kết quả';
  }
</script>
</body>
</html>
''';

String _placeholder(String title) => '''
<svg xmlns="http://www.w3.org/2000/svg" width="200" height="420"
     style="background:#1e1e2e;font-family:sans-serif">
  <text x="100" y="200" text-anchor="middle"
        font-size="13" fill="#6c63ff">$title</text>
  <text x="100" y="220" text-anchor="middle"
        font-size="11" fill="#555">screenshot pending</text>
</svg>
''';
