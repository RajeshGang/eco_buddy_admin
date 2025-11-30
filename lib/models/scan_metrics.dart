import 'package:cloud_firestore/cloud_firestore.dart';

class ScanMetrics {
  final int totalScans;
  final int successfulScans;
  final int failedScans;
  final double successRate;
  final List<Map<String, dynamic>> topProducts;
  final List<Map<String, dynamic>> scanTrends;

  ScanMetrics({
    required this.totalScans,
    required this.successfulScans,
    required this.failedScans,
    required this.successRate,
    required this.topProducts,
    required this.scanTrends,
  });

  factory ScanMetrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScanMetrics(
      totalScans: data['totalScans'] ?? 0,
      successfulScans: data['successfulScans'] ?? 0,
      failedScans: data['failedScans'] ?? 0,
      successRate: (data['successRate'] ?? 0.0).toDouble(),
      topProducts: List<Map<String, dynamic>>.from(data['topProducts'] ?? []),
      scanTrends: List<Map<String, dynamic>>.from(data['scanTrends'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalScans': totalScans,
        'successfulScans': successfulScans,
        'failedScans': failedScans,
        'successRate': successRate,
        'topProducts': topProducts,
        'scanTrends': scanTrends,
      };
}
