# Kế hoạch tích hợp SePay → Spendo

> Mục tiêu: Tự động đồng bộ biến động số dư ngân hàng (Vietcombank) vào Spendo
> qua SePay webhook, không cần backend server riêng, chi phí gần zero.

---

## Tổng quan kiến trúc

```
Vietcombank
    │  biến động số dư (API Banking, realtime)
    ▼
SePay (kết nối trực tiếp qua API với VCB)
    │  POST webhook
    ▼
Cloudflare Worker  ← receiver, always-on, free 100k req/ngày
    │  validate + forward
    ▼
Supabase Edge Function  ← xử lý logic, insert DB
    │  INSERT INTO transactions (Supabase Postgres)
    ▼
PowerSync  ← sync về app như bình thường (không cần thay đổi)
    ▼
Flutter App (Spendo)
```

> **Lưu ý về PowerSync**: Edge Function insert thẳng vào bảng `transactions`
> trên Supabase Postgres. PowerSync sẽ pull data về app theo cơ chế sync
> hiện tại — không cần sửa gì ở Flutter hay PowerSync layer.

---

## Giới hạn & Chi phí

| Service | Free limit | Nhu cầu thực tế | Đánh giá |
|---|---|---|---|
| SePay | 50 tx **tiền vào**/tháng | ~5–15 tx tiền vào/tháng (lương, thu nhập) | ✅ Thường đủ dùng cho cá nhân — tx tiền ra miễn phí, không tính quota |
| Cloudflare Workers | 100,000 req/ngày | ~5 req/ngày | ✅ Thoải mái |
| Supabase Edge Function | 500,000 invoke/tháng | ~20/tháng | ✅ Thoải mái |
| Supabase DB (free) | 500MB | Nhỏ | ✅ Đủ dùng |
| Supabase (pause) | Pause sau 7 ngày inactive | Cần keep-alive nếu ít giao dịch | ⚠️ Cần setup cron |

> **Lưu ý giá SePay**: SePay chỉ tính quota cho giao dịch **tiền vào**.
> Giao dịch tiền ra (chi tiêu hàng ngày) hoàn toàn miễn phí và không tính vào hạn mức.
> Cần xác nhận giá/tx vượt mức bằng cách vào dashboard my.sepay.vn trước khi quyết định.

---

## Schema cần thêm vào Supabase

### Bảng `sepay_bank_accounts`
Map tài khoản ngân hàng trong SePay với Wallet trong Spendo.

```sql
CREATE TABLE sepay_bank_accounts (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id),
  wallet_id     TEXT NOT NULL,
  account_number TEXT NOT NULL,
  bank_short_name TEXT NOT NULL,
  label         TEXT,
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE sepay_bank_accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only" ON sepay_bank_accounts
  USING (auth.uid() = user_id);
```

### Bảng `sepay_transactions` (raw log)
Lưu raw webhook từ SePay. Dùng để debug và dedup.

```sql
CREATE TABLE sepay_transactions (
  id                BIGINT PRIMARY KEY,     -- ID từ SePay, dùng luôn để dedup
  gateway           TEXT NOT NULL,
  account_number    TEXT NOT NULL,
  transfer_type     TEXT NOT NULL,          -- "in" | "out"
  transfer_amount   BIGINT NOT NULL,
  content           TEXT,
  transaction_date  TIMESTAMPTZ NOT NULL,
  accumulated       BIGINT,
  reference_code    TEXT,
  spendo_tx_id      TEXT,                   -- ID của transaction đã tạo trong Spendo
  created_at        TIMESTAMPTZ DEFAULT NOW()
);
-- Server-side only, không cần RLS — chỉ Edge Function write vào đây
```

### Migration `transactions` table (Supabase)
Thêm field `source` để phân biệt giao dịch tự động vs nhập tay:

```sql
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual';
-- 'manual' | 'sepay'
```

> **Lưu ý**: Cần đồng thời thêm field `source` vào `schema.dart` của PowerSync
> và chạy migration `ALTER TABLE` trên SQLite local (tương tự cách đã làm với `wallet_id`).

---

## Phase 1: Cloudflare Worker (Webhook Receiver)

**Mục đích**: Nhận POST từ SePay, validate, forward sang Supabase Edge Function.
Lý do tách riêng: Cloudflare luôn online (không bị pause như Supabase free tier),
là lớp bảo vệ đầu tiên, lọc request rác.

**File**: `cloudflare-worker/src/index.ts`

```typescript
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // 1. Chỉ nhận POST
    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    // 2. Validate SePay API Key header
    const authHeader = request.headers.get("Authorization");
    if (authHeader !== `Apikey ${env.SEPAY_API_KEY}`) {
      return new Response("Unauthorized", { status: 401 });
    }

    // 3. Parse body
    const body = await request.json();

    // 4. Forward sang Supabase Edge Function (fire-and-forget)
    fetch(env.SUPABASE_WEBHOOK_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${env.SUPABASE_SERVICE_KEY}`,
      },
      body: JSON.stringify(body),
    }).catch(() => {}); // Không block response

    // 5. Trả về 200 ngay cho SePay (SePay cần 200 trong vòng timeout)
    return new Response("OK", { status: 200 });
  },
};

interface Env {
  SEPAY_API_KEY: string;
  SUPABASE_WEBHOOK_URL: string;
  SUPABASE_SERVICE_KEY: string;
}
```

**Cấu hình** (`wrangler.toml`):
```toml
name = "spendo-sepay-receiver"
main = "src/index.ts"
compatibility_date = "2024-01-01"
```

**Deploy**:
```bash
npm create cloudflare@latest spendo-sepay-receiver
cd spendo-sepay-receiver
wrangler secret put SEPAY_API_KEY
wrangler secret put SUPABASE_WEBHOOK_URL
wrangler secret put SUPABASE_SERVICE_KEY
wrangler deploy
# → https://spendo-sepay-receiver.<subdomain>.workers.dev
```

---

## Phase 2: Supabase Edge Function (Business Logic)

**Mục đích**: Nhận data đã validated từ Cloudflare Worker, xử lý logic,
insert vào Supabase DB (PowerSync sẽ tự sync về app).

**File**: `supabase/functions/sepay-webhook/index.ts`

```typescript
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

Deno.serve(async (req) => {
  const payload = await req.json();

  const {
    id,
    gateway,
    accountNumber,
    transferType,
    transferAmount,
    content,
    transactionDate,
    accumulated,
    referenceCode,
  } = payload;

  // ── Bước 1: Dedup — bỏ qua nếu đã xử lý ─────────────────────────────
  const { data: existing } = await supabase
    .from("sepay_transactions")
    .select("id")
    .eq("id", id)
    .single();

  if (existing) {
    return new Response("Already processed", { status: 200 });
  }

  // ── Bước 2: Lưu raw log ───────────────────────────────────────────────
  await supabase.from("sepay_transactions").insert({
    id,
    gateway,
    account_number: accountNumber,
    transfer_type: transferType,
    transfer_amount: transferAmount,
    content,
    transaction_date: transactionDate,
    accumulated,
    reference_code: referenceCode,
  });

  // ── Bước 3: Tìm mapping wallet + user ────────────────────────────────
  const { data: bankAccount } = await supabase
    .from("sepay_bank_accounts")
    .select("user_id, wallet_id")
    .eq("account_number", accountNumber)
    .eq("is_active", true)
    .single();

  if (!bankAccount) {
    return new Response("No matching account", { status: 200 });
  }

  // ── Bước 4: Tìm category fallback ────────────────────────────────────
  // Ưu tiên match keyword từ content. Nếu không match → fallback "Khác".
  // Không kỳ vọng cao vào auto-categorize vì content chuyển khoản ngân hàng
  // thường ngắn và không chứa keyword đủ rõ ràng.
  const isIncome = transferType === "in";
  const categoryId = await guessCategoryId(
    bankAccount.user_id,
    content ?? "",
    isIncome
  );

  // ── Bước 5: Insert vào transactions ──────────────────────────────────
  const { data: tx } = await supabase.from("transactions").insert({
    id: crypto.randomUUID(),
    amount: transferAmount.toString(),
    type: isIncome ? "income" : "expense",
    category_id: categoryId,
    note: content ?? "",
    created_at: new Date(transactionDate).getTime().toString(),
    wallet_id: bankAccount.wallet_id,
    user_id: bankAccount.user_id,
    source: "sepay",
  }).select().single();

  // ── Bước 6: Update sepay_transactions với spendo_tx_id ───────────────
  if (tx) {
    await supabase
      .from("sepay_transactions")
      .update({ spendo_tx_id: tx.id })
      .eq("id", id);
  }

  return new Response("OK", { status: 200 });
});

async function guessCategoryId(
  userId: string,
  content: string,
  isIncome: boolean
): Promise<string> {
  // Lấy categories của user từ Supabase
  const { data: categories } = await supabase
    .from("categories")
    .select("id, name, icon_name")
    .eq("user_id", userId)
    .eq("is_income", isIncome ? 1 : 0);

  if (!categories?.length) return "";

  // Keyword → icon_name mapping (port từ category_matcher.dart)
  // Lưu ý: content chuyển khoản thường ngắn, match rate thực tế thấp.
  // Phần lớn sẽ fall về "Khác" — user tự chỉnh sau.
  const rules: Record<string, string> = {
    "ăn": "restaurant", "uống": "restaurant", "cơm": "restaurant",
    "cà phê": "restaurant", "cafe": "restaurant", "trà sữa": "restaurant",
    "grab": "directions_car", "taxi": "directions_car", "xăng": "directions_car",
    "shopee": "shopping_bag", "lazada": "shopping_bag", "siêu thị": "shopping_bag",
    "học": "school", "khóa": "school", "sách": "school",
    "thuốc": "favorite", "khám": "favorite", "gym": "favorite",
    "lương": "work", "thưởng": "work",
    "điện": "home", "nước": "home", "nhà": "home",
  };

  const lower = content.toLowerCase();
  for (const [keyword, iconName] of Object.entries(rules)) {
    if (lower.includes(keyword)) {
      const matched = categories.find((c: any) => c.icon_name === iconName);
      if (matched) return matched.id;
    }
  }

  // Fallback: "Khác" hoặc category đầu tiên trong list
  const fallback = categories.find((c: any) => c.icon_name === "more_horiz");
  return fallback?.id ?? categories[0]?.id ?? "";
}
```

**Deploy**:
```bash
supabase functions deploy sepay-webhook --no-verify-jwt
```

---

## Phase 3: Keep-alive cho Supabase

Supabase free tier pause sau 7 ngày không có request. Nếu đã có SePay webhook
chạy hàng ngày thì không cần. Nhưng nếu ít giao dịch → cần ping định kỳ.

**Cách setup với cron-job.org (free)**:
1. Vào https://cron-job.org → tạo tài khoản
2. Tạo cronjob: `GET https://<project>.supabase.co/rest/v1/categories?limit=1`
3. Header: `apikey: <supabase_anon_key>`
4. Schedule: mỗi 3 ngày 1 lần

> Không cần code gì thêm. Chỉ cần setup 1 lần trên cron-job.org.

---

## Phase 4: Flutter UI trong Spendo

### 4.1 — Schema PowerSync (nếu dùng field `source`)

```dart
// lib/core/db/schema.dart — thêm vào Table('transactions', [...])
Column.text('source'),  // 'manual' | 'sepay' — nullable, default 'manual'
```

Migration SQLite local (tương tự wallet_id):
```dart
// lib/core/db/powersync_db.dart — thêm vào openDatabase()
Future<void> _migrateSource() async {
  try {
    await db.execute("ALTER TABLE transactions ADD COLUMN source TEXT DEFAULT 'manual'");
  } catch (_) {}
}
```

### 4.2 — Màn hình "Kết nối ngân hàng" trong Settings

```dart
// lib/features/settings/presentation/screens/settings_screen.dart
_SectionHeader(title: 'Kết nối ngân hàng'),
const SepayConnectionSection(),
```

### 4.3 — SepayConnectionSection widget

```dart
// lib/features/settings/presentation/widgets/sepay_connection_section.dart

class SepayConnectionSection extends ConsumerWidget {
  const SepayConnectionSection({super.key});

  static const _sepayDashboardUrl = 'https://my.sepay.vn';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final connectedAccounts = ref.watch(sepayAccountsProvider);

    return Material(
      color: cs.surface,
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.landmark, size: 18,
                  color: Color(0xFF1E88E5)),
            ),
            title: const Text('Quản lý kết nối SePay',
                style: TextStyle(fontSize: 14)),
            subtitle: Text(
              'Đăng nhập SePay để kết nối tài khoản ngân hàng',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            trailing: Icon(LucideIcons.externalLink, size: 16,
                color: cs.onSurfaceVariant),
            onTap: () => _openSepayDashboard(context),
          ),
          connectedAccounts.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (accounts) => Column(
              children: accounts.map((account) => _AccountTile(
                account: account,
                onToggle: (isActive) => ref
                    .read(sepayAccountsProvider.notifier)
                    .toggleActive(account.id, isActive),
              )).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Sau khi kết nối trên SePay, quay lại đây để gán tài khoản '
              'ngân hàng với nguồn tiền trong Spendo.',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSepayDashboard(BuildContext context) async {
    final uri = Uri.parse(_sepayDashboardUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
```

### 4.4 — Provider cho SePay accounts

```dart
// lib/features/settings/presentation/providers/sepay_provider.dart

class SepayBankAccount {
  final String id;
  final String walletId;
  final String accountNumber;
  final String bankShortName;
  final String? label;
  final bool isActive;

  const SepayBankAccount({
    required this.id,
    required this.walletId,
    required this.accountNumber,
    required this.bankShortName,
    this.label,
    required this.isActive,
  });

  factory SepayBankAccount.fromJson(Map<String, dynamic> json) =>
    SepayBankAccount(
      id: json['id'],
      walletId: json['wallet_id'],
      accountNumber: json['account_number'],
      bankShortName: json['bank_short_name'],
      label: json['label'],
      isActive: json['is_active'] ?? true,
    );
}

final sepayAccountsProvider =
    AsyncNotifierProvider<SepayAccountsNotifier, List<SepayBankAccount>>(
  SepayAccountsNotifier.new,
);

class SepayAccountsNotifier extends AsyncNotifier<List<SepayBankAccount>> {
  @override
  Future<List<SepayBankAccount>> build() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await Supabase.instance.client
        .from('sepay_bank_accounts')
        .select()
        .eq('user_id', userId);

    return (response as List)
        .map((e) => SepayBankAccount.fromJson(e))
        .toList();
  }

  Future<void> toggleActive(String id, bool isActive) async {
    await Supabase.instance.client
        .from('sepay_bank_accounts')
        .update({'is_active': isActive})
        .eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> addMapping({
    required String accountNumber,
    required String bankShortName,
    required String walletId,
    String? label,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client
        .from('sepay_bank_accounts')
        .upsert({
          'user_id': userId,
          'account_number': accountNumber,
          'bank_short_name': bankShortName,
          'wallet_id': walletId,
          'label': label,
          'is_active': true,
        });
    ref.invalidateSelf();
  }
}
```

### 4.5 — Badge "auto" trên transaction list item

Thêm visual indicator nhỏ để phân biệt giao dịch từ SePay:

```dart
// Trong transaction list item widget, bọc category icon trong Stack
if (transaction.source == 'sepay')
  Positioned(
    bottom: 0, right: 0,
    child: Container(
      width: 14, height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: const Icon(Icons.bolt, size: 8, color: Colors.white),
    ),
  ),
```

---

## Phase 5: Setup SePay (thực hiện thủ công 1 lần)

1. Đăng ký tài khoản tại `my.sepay.vn`
2. Thêm tài khoản Vietcombank → kết nối qua API Banking (không cần SMS)
3. Vào **Tích hợp Webhooks** → Thêm webhook mới:
   - URL: `https://spendo-sepay-receiver.<subdomain>.workers.dev`
   - Xác thực: **API Key**
   - API Key: random secret (điền vào Cloudflare Worker secret `SEPAY_API_KEY`)
   - Loại: **Tất cả** (tiền vào + tiền ra)
4. Test bằng "Giả lập giao dịch" trong SePay dashboard

---

## Rủi ro & Hướng xử lý

### R1: Auto-categorize thường không chính xác
**Vấn đề**: Nội dung chuyển khoản ngân hàng thường là "NGUYEN VAN A chuyen tien" hoặc mã tham chiếu — không chứa keyword như "grab", "cafe". Match rate thực tế sẽ thấp, phần lớn fall về "Khác".

**Đề xuất**: Chấp nhận ngay từ đầu. Không cố làm thông minh. UX flow đúng là: transaction tự động vào, user vào Spendo review và đổi category nếu cần. Có thể thêm filter "Chưa phân loại" trong transaction list để user review nhanh.

---

### R2: SePay webhook retry gây duplicate
**Vấn đề**: Nếu Cloudflare Worker fail (hiếm), SePay retry → có thể gọi lại Edge Function với cùng `id`.

**Đề xuất**: Đã handled bởi dedup check `SELECT id FROM sepay_transactions WHERE id = ?` trong Edge Function. Đảm bảo bước insert raw log vào `sepay_transactions` xảy ra **trước** khi insert vào `transactions` — đây là source of truth cho dedup.

---

### R3: Supabase pause khi ít giao dịch
**Vấn đề**: Nếu không có giao dịch ngân hàng nào trong 7 ngày, Supabase free tier pause → webhook tiếp theo bị drop cho đến khi Supabase wake up (vài giây đến vài phút).

**Đề xuất**: Setup keep-alive cron trên cron-job.org (xem Phase 3). Cloudflare Worker return 200 ngay cho SePay bất kể Supabase có đang wake hay không → SePay không thấy lỗi. Nếu Supabase chưa wake kịp, Edge Function gọi bị fail → transaction bị mất. Giải pháp triệt để hơn: thêm retry logic trong Cloudflare Worker (retry 3 lần với delay 2s nếu Supabase trả lỗi).

---

### R4: `category_id` không hợp lệ vì categories là local PowerSync data
**Vấn đề**: Categories được tạo local trên thiết bị với UUID random. Khi PowerSync upload lên Supabase, `user_id` không tự động được gán (xem `uploadData` trong `powersync_connector.dart` — chỉ upsert với `user_id` từ session). Edge Function query `categories WHERE user_id = ?` có thể không tìm thấy nếu categories chưa sync lên hoặc schema Supabase thiếu `user_id` trên bảng categories.

**Đề xuất**: Kiểm tra Supabase categories table có column `user_id` không. Nếu không có, `guessCategoryId` sẽ luôn trả về empty string → transaction insert với `category_id = ""` → lỗi FK constraint. Fix đơn giản nhất: bỏ FK constraint trên `category_id` hoặc cho phép null, fallback về empty string và user tự assign sau.

---

### R5: Multi-user vs personal use
**Vấn đề**: Kiến trúc bảng `sepay_bank_accounts` hỗ trợ multi-user (lookup theo `account_number → user_id`). Nhưng Spendo hiện tại là personal app.

**Đề xuất**: Không cần thay đổi gì. Bảng multi-user-ready nhưng thực tế chỉ có 1 user → không phát sinh vấn đề. Nếu muốn đơn giản hóa hoàn toàn, có thể hardcode `user_id` vào Supabase Edge Function env var và bỏ bảng `sepay_bank_accounts` — nhưng không cần thiết vì bảng này nhỏ và đơn giản.

---

## Tóm tắt file cần tạo mới

```
cloudflare-worker/
├── src/index.ts                         ← Phase 1
└── wrangler.toml

supabase/
└── functions/
    └── sepay-webhook/
        └── index.ts                     ← Phase 2

lib/
├── core/
│   └── db/
│       └── schema.dart                  ← Thêm Column.text('source') vào transactions
│       └── powersync_db.dart            ← Thêm _migrateSource()
└── features/
    └── settings/
        ├── presentation/
        │   ├── providers/
        │   │   └── sepay_provider.dart  ← Phase 4.4
        │   └── widgets/
        │       └── sepay_connection_section.dart  ← Phase 4.3
        └── domain/
            └── sepay_bank_account.dart  ← Model
```

---

## Thứ tự thực hiện

```
[0] Vào my.sepay.vn xác nhận giá/tx vượt mức free tier (nếu cần)
[1] Tạo bảng Supabase (SQL migration: sepay_bank_accounts, sepay_transactions, ALTER transactions)
[2] Kiểm tra bảng categories trên Supabase có user_id không → xử lý FK nếu thiếu
[3] Deploy Cloudflare Worker
[4] Deploy Supabase Edge Function
[5] Setup keep-alive cron trên cron-job.org
[6] Cấu hình SePay webhook → trỏ vào Cloudflare Worker URL
[7] Test với SePay giả lập giao dịch → verify data chạy đúng qua pipeline
[8] Thêm schema.dart + migration source field trong Flutter
[9] Thêm Flutter UI (SepayConnectionSection)
[10] Thêm mapping: account_number ↔ wallet_id qua UI hoặc insert thủ công vào Supabase
[11] Test end-to-end thật với Vietcombank (chuyển 10k)
```

---

## Những thứ KHÔNG cần làm

- Không cần sửa PowerSync sync logic (data tự chảy từ Supabase về app)
- Không cần backend server riêng (Cloudflare + Supabase đủ rồi)
- Không cần OAuth với SePay (API Key là đủ)
- Không cần app SePay riêng (user quản lý qua my.sepay.vn)
- Không cần xử lý realtime push từ Supabase xuống app (PowerSync tự pull)
- Không cần bỏ PowerSync hay migrate sang Supabase REST
