import 'package:flutter/material.dart';

enum TxOperationType {
  hold(label: 'مسدود موقت', englishName: 'HOLD', color: Color(0xFFD97706)),
  capture(label: 'قطعی‌شده', englishName: 'CAPTURE', color: Color(0xFF16A34A)),
  release(label: 'آزادشده', englishName: 'RELEASE', color: Color(0xFF2563EB)),
  topUp(label: 'شارژ کیف پول', englishName: 'TOP_UP', color: Color(0xFF0D9488)),
  adjustment(label: 'اصلاحی / تسویه', englishName: 'ADJUSTMENT', color: Color(0xFF9333EA)),
  refund(label: 'استرداد وجه', englishName: 'REFUND', color: Color(0xFFDC2626));

  final String label;
  final String englishName;
  final Color color;

  const TxOperationType({
    required this.label,
    required this.englishName,
    required this.color,
  });
}

enum PaymentGatewayType {
  all(label: 'همه درگاه‌ها'),
  iap(label: 'خرید درون‌برنامه‌ای (IAP)'),
  stripe(label: 'استرایپ بین‌المللی (Stripe)'),
  crypto(label: 'درگاه کریپتو (USDT/TON)'),
  wallet(label: 'کیف پول داخلی (StyleCoin)');

  final String label;
  const PaymentGatewayType({required this.label});
}

enum TxStatus {
  settled(label: 'تسویه شده', color: Color(0xFF16A34A)),
  held(label: 'مسدود امانی', color: Color(0xFFD97706)),
  released(label: 'آزاد شده', color: Color(0xFF2563EB)),
  refunded(label: 'مرجوع شده', color: Color(0xFFDC2626));

  final String label;
  final Color color;
  const TxStatus({required this.label, required this.color});
}

class TransactionRecord {
  final String txId;
  final String idempotencyKey;
  final TxOperationType operationType;
  final String userId;
  final String userDisplayName;
  final PaymentGatewayType gateway;
  final int amountCoins;
  final double amountUsd;
  final double cloudAiCost;
  final TxStatus status;
  final DateTime timestamp;
  final String reconciliationAppStatus;
  final String reconciliationGatewayStatus;
  final String reconciliationLedgerStatus;
  final String notes;

  const TransactionRecord({
    required this.txId,
    required this.idempotencyKey,
    required this.operationType,
    required this.userId,
    required this.userDisplayName,
    required this.gateway,
    required this.amountCoins,
    required this.amountUsd,
    required this.cloudAiCost,
    required this.status,
    required this.timestamp,
    this.reconciliationAppStatus = 'CONFIRMED',
    this.reconciliationGatewayStatus = 'CAPTURED',
    this.reconciliationLedgerStatus = 'RECONCILED',
    this.notes = '',
  });

  TransactionRecord copyWith({
    String? txId,
    String? idempotencyKey,
    TxOperationType? operationType,
    String? userId,
    String? userDisplayName,
    PaymentGatewayType? gateway,
    int? amountCoins,
    double? amountUsd,
    double? cloudAiCost,
    TxStatus? status,
    DateTime? timestamp,
    String? reconciliationAppStatus,
    String? reconciliationGatewayStatus,
    String? reconciliationLedgerStatus,
    String? notes,
  }) {
    return TransactionRecord(
      txId: txId ?? this.txId,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      operationType: operationType ?? this.operationType,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      gateway: gateway ?? this.gateway,
      amountCoins: amountCoins ?? this.amountCoins,
      amountUsd: amountUsd ?? this.amountUsd,
      cloudAiCost: cloudAiCost ?? this.cloudAiCost,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      reconciliationAppStatus:
          reconciliationAppStatus ?? this.reconciliationAppStatus,
      reconciliationGatewayStatus:
          reconciliationGatewayStatus ?? this.reconciliationGatewayStatus,
      reconciliationLedgerStatus:
          reconciliationLedgerStatus ?? this.reconciliationLedgerStatus,
      notes: notes ?? this.notes,
    );
  }
}
