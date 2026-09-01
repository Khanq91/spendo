import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum LoanType {
  borrowed, // tôi vay
  lent;     // tôi cho vay

  String get label => switch (this) {
    LoanType.borrowed => 'Tôi đang vay',
    LoanType.lent => 'Tôi cho vay',
  };
}

/// How a loan is paid back.
///
/// A missing column reads as [free], so every loan that existed before the
/// schedule feature keeps behaving exactly as it did.
enum RepaymentMode {
  free,
  installment;

  String get label => switch (this) {
    RepaymentMode.free => 'Trả tự do',
    RepaymentMode.installment => 'Trả theo đợt',
  };

  static RepaymentMode fromDb(String? value) =>
      value == RepaymentMode.installment.name
          ? RepaymentMode.installment
          : RepaymentMode.free;
}

enum LoanStatus {
  active,   // đang còn nợ
  upcoming, // sắp đến hạn (≤ 7 ngày)
  overdue,  // quá hạn
  closed;   // đã tất toán
}

class Loan {
  final String id;
  final String title;
  final LoanType type;
  final int principal;       // số tiền gốc
  final String contactName;  // tên người liên quan
  final DateTime startDate;
  final DateTime? dueDate;   // nullable — vay không kỳ hạn
  final String? note;
  final String colorHex;
  final bool isClosed;
  final RepaymentMode repaymentMode;

  /// The transaction written when the principal was booked into a wallet —
  /// null for every loan whose money never moved through the app (giai đoạn 2).
  final String? fundingTransactionId;

  const Loan({
    required this.id,
    required this.title,
    required this.type,
    required this.principal,
    required this.contactName,
    required this.startDate,
    this.dueDate,
    this.note,
    required this.colorHex,
    required this.isClosed,
    this.repaymentMode = RepaymentMode.free,
    this.fundingTransactionId,
  });

  Color get color => AppColors.fromHex(colorHex);

  LoanStatus get status {
    if (isClosed) return LoanStatus.closed;
    if (dueDate == null) return LoanStatus.active;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final diff = due.difference(today).inDays;
    if (diff < 0) return LoanStatus.overdue;
    if (diff <= 7) return LoanStatus.upcoming;
    return LoanStatus.active;
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] as String,
      title: map['title'] as String,
      type: LoanType.values.firstWhere(
            (t) => t.name == map['type'],
        orElse: () => LoanType.borrowed,
      ),
      principal: int.tryParse(map['principal'] as String? ?? '0') ?? 0,
      contactName: map['contact_name'] as String? ?? '',
      startDate: DateTime.parse(map['start_date'] as String),
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'] as String)
          : null,
      note: map['note'] as String?,
      colorHex: map['color_hex'] as String,
      isClosed: (map['is_closed'] as int) == 1,
      repaymentMode: RepaymentMode.fromDb(map['repayment_mode'] as String?),
      fundingTransactionId: map['funding_transaction_id'] as String?,
    );
  }

  /// The same loan wearing the id the database gave it — the form builds a
  /// [Loan] before it knows its id, then needs the real one to keep going.
  Loan copyWithId(String newId) => Loan(
    id: newId,
    title: title,
    type: type,
    principal: principal,
    contactName: contactName,
    startDate: startDate,
    dueDate: dueDate,
    note: note,
    colorHex: colorHex,
    isClosed: isClosed,
    repaymentMode: repaymentMode,
    fundingTransactionId: fundingTransactionId,
  );

  Loan copyWith({
    RepaymentMode? repaymentMode,
    String? fundingTransactionId,
  }) {
    return Loan(
      id: id,
      title: title,
      type: type,
      principal: principal,
      contactName: contactName,
      startDate: startDate,
      dueDate: dueDate,
      note: note,
      colorHex: colorHex,
      isClosed: isClosed,
      repaymentMode: repaymentMode ?? this.repaymentMode,
      fundingTransactionId: fundingTransactionId ?? this.fundingTransactionId,
    );
  }
}

class LoanPayment {
  final String id;
  final String loanId;
  final int amount;
  final DateTime paidAt;
  final String? note;

  /// The transaction this payment wrote into a wallet (giai đoạn 2) — null for
  /// payments recorded before the two were linked.
  final String? transactionId;

  const LoanPayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.paidAt,
    this.note,
    this.transactionId,
  });

  factory LoanPayment.fromMap(Map<String, dynamic> map) {
    return LoanPayment(
      id: map['id'] as String,
      loanId: map['loan_id'] as String,
      amount: int.tryParse(map['amount'] as String? ?? '0') ?? 0,
      paidAt: DateTime.parse(map['paid_at'] as String),
      note: map['note'] as String?,
      transactionId: map['transaction_id'] as String?,
    );
  }
}

/// One planned instalment.
///
/// Instalments are a *plan*: they never take part in the money arithmetic
/// (`remaining` stays `principal − SUM(payments)`), only in what the schedule
/// shows and what gets reminded. Whether one counts as paid is derived from
/// the payments by the waterfall in `installment_status.dart`.
class LoanInstallment {
  final String id;
  final String loanId;

  /// 1-based position in the schedule — the "3" of "Đợt 3/12".
  final int seq;
  final int amount;
  final DateTime dueDate;

  const LoanInstallment({
    required this.id,
    required this.loanId,
    required this.seq,
    required this.amount,
    required this.dueDate,
  });

  factory LoanInstallment.fromMap(Map<String, dynamic> map) {
    return LoanInstallment(
      id: map['id'] as String,
      loanId: map['loan_id'] as String,
      seq: map['seq'] as int,
      amount: int.tryParse(map['amount'] as String? ?? '0') ?? 0,
      dueDate: DateTime.parse(map['due_date'] as String),
    );
  }

  LoanInstallment copyWith({int? seq, int? amount, DateTime? dueDate}) {
    return LoanInstallment(
      id: id,
      loanId: loanId,
      seq: seq ?? this.seq,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}