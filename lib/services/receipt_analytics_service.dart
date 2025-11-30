import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ReceiptAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all receipts from users subcollections
  Future<List<QueryDocumentSnapshot>> _getAllReceipts() async {
    final allReceipts = <QueryDocumentSnapshot>[];
    final userIds = <String>[];

    // Get user IDs from users or leaderboard
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      userIds.addAll(usersSnapshot.docs.map((doc) => doc.id));
    } catch (e) {
      if (kDebugMode) {
        print('Users collection not accessible: $e');
      }
    }

    if (userIds.isEmpty) {
      try {
        final leaderboardSnapshot = await _firestore.collection('leaderboard').get();
        userIds.addAll(leaderboardSnapshot.docs.map((doc) => doc.id));
      } catch (e) {
        if (kDebugMode) {
          print('Leaderboard collection not accessible: $e');
        }
      }
    }

    // Query receipts from each user
    for (var userId in userIds) {
      try {
        final receiptsSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('receipts')
            .get();
        allReceipts.addAll(receiptsSnapshot.docs);
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching receipts for user $userId: $e');
        }
      }
    }

    return allReceipts;
  }

  // Get receipt analytics
  Future<Map<String, dynamic>> getReceiptAnalytics() async {
    try {
      final receipts = await _getAllReceipts();
      
      if (receipts.isEmpty) {
        return {
          'totalReceipts': 0,
          'totalItems': 0,
          'averageItemsPerReceipt': 0.0,
          'averageScore': 0.0,
          'categoryBreakdown': <String, int>{},
          'receiptTrends': <Map<String, dynamic>>[],
          'totalValue': 0.0,
        };
      }

      int totalItems = 0;
      double totalScore = 0.0;
      double totalValue = 0.0;
      final categoryCounts = <String, int>{};
      final trendMap = <String, Map<String, int>>{};

      for (var receiptDoc in receipts) {
        final receiptData = receiptDoc.data() as Map<String, dynamic>;

        // Get overall score
        final score = (receiptData['overallScore'] ??
                     receiptData['score'] ??
                     receiptData['sustainabilityScore'] ??
                     0.0).toDouble();
        totalScore += score;

        // Get total value if available
        final value = (receiptData['total'] ??
                      receiptData['totalValue'] ??
                      receiptData['amount'] ??
                      0.0).toDouble();
        totalValue += value;

        // Process items
        final items = receiptData['items'] as List<dynamic>?;
        if (items != null) {
          totalItems += items.length;
          
          for (var item in items) {
            if (item is Map<String, dynamic>) {
              final category = item['category'] as String? ?? 'Unknown';
              categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
            }
          }
        }

        // Track trends by date
        final timestamp = receiptData['timestamp'] as Timestamp? ??
                         receiptData['createdAt'] as Timestamp? ??
                         receiptData['date'] as Timestamp?;
        if (timestamp != null) {
          final dateKey = timestamp.toDate().toIso8601String().substring(0, 10);
          if (!trendMap.containsKey(dateKey)) {
            trendMap[dateKey] = {'count': 0, 'items': 0};
          }
          trendMap[dateKey]!['count'] = (trendMap[dateKey]!['count'] ?? 0) + 1;
          trendMap[dateKey]!['items'] = (trendMap[dateKey]!['items'] ?? 0) + (items?.length ?? 0);
        }
      }

      // Convert trend map to list
      final receiptTrends = trendMap.entries.map((entry) {
        return {
          'date': entry.key,
          'receipts': entry.value['count'] ?? 0,
          'items': entry.value['items'] ?? 0,
        };
      }).toList();
      receiptTrends.sort((a, b) {
        final dateA = a['date'] as String? ?? '';
        final dateB = b['date'] as String? ?? '';
        return dateA.compareTo(dateB);
      });

      return {
        'totalReceipts': receipts.length,
        'totalItems': totalItems,
        'averageItemsPerReceipt': receipts.isNotEmpty ? (totalItems / receipts.length) : 0.0,
        'averageScore': receipts.isNotEmpty ? (totalScore / receipts.length) : 0.0,
        'categoryBreakdown': categoryCounts,
        'receiptTrends': receiptTrends,
        'totalValue': totalValue,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting receipt analytics: $e');
      }
      return {
        'totalReceipts': 0,
        'totalItems': 0,
        'averageItemsPerReceipt': 0.0,
        'averageScore': 0.0,
        'categoryBreakdown': <String, int>{},
        'receiptTrends': <Map<String, dynamic>>[],
        'totalValue': 0.0,
      };
    }
  }

  // Stream for real-time updates
  Stream<Map<String, dynamic>> receiptAnalyticsStream() {
    return _firestore
        .collection('leaderboard')
        .snapshots()
        .asyncMap((snapshot) => getReceiptAnalytics());
  }
}

