import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_metrics.dart';
import '../models/scan_metrics.dart';
import '../models/sustainability_metrics.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Metrics - calculates from users or leaderboard collection
  Future<UserMetrics> getUserMetrics() async {
    try {
      // Try to get from analytics collection first (if pre-aggregated)
      final analyticsDoc = await _firestore.collection('analytics').doc('user_metrics').get();
      if (analyticsDoc.exists) {
        return UserMetrics.fromFirestore(analyticsDoc);
      }
      
      // Try users collection first
      QuerySnapshot? usersSnapshot;
      try {
        usersSnapshot = await _firestore.collection('users').get();
      } catch (e) {
        if (kDebugMode) {
          print('Users collection not accessible: $e');
        }
      }
      
      // If users collection is empty or doesn't exist, try leaderboard collection
      if (usersSnapshot == null || usersSnapshot.docs.isEmpty) {
        try {
          usersSnapshot = await _firestore.collection('leaderboard').get();
        } catch (e) {
          if (kDebugMode) {
            print('Leaderboard collection not accessible: $e');
          }
        }
      }
      
      if (usersSnapshot == null || usersSnapshot.docs.isEmpty) {
        return UserMetrics(
          totalUsers: 0,
          activeUsers: 0,
          newUsers: 0,
          retentionRate: 0.0,
          userGrowth: [],
        );
      }
      
      final totalUsers = usersSnapshot.docs.length;
      
      // Calculate active users (last active within 7 days)
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      int activeUsers = 0;
      int newUsers = 0;
      
      final userGrowth = <Map<String, dynamic>>[];
      final growthMap = <String, int>{};
      
      for (var doc in usersSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        
        // Support both 'users' and 'leaderboard' collection structures
        final createdAt = userData['createdAt'] as Timestamp?;
        final lastActive = (userData['lastActive'] ?? userData['lastUpdated']) as Timestamp?;
        
        // Count active users
        if (lastActive != null && lastActive.toDate().isAfter(sevenDaysAgo)) {
          activeUsers++;
        }
        
        // Count new users (created in last 7 days)
        // For leaderboard, use lastUpdated as proxy for createdAt if createdAt doesn't exist
        final userCreatedAt = createdAt ?? lastActive;
        if (userCreatedAt != null && userCreatedAt.toDate().isAfter(sevenDaysAgo)) {
          newUsers++;
        }
        
        // Build growth data
        if (userCreatedAt != null) {
          final dateKey = userCreatedAt.toDate().toIso8601String().substring(0, 10);
          growthMap[dateKey] = (growthMap[dateKey] ?? 0) + 1;
        }
      }
      
      // Convert growth map to list
      growthMap.forEach((date, count) {
        userGrowth.add({'date': date, 'count': count});
      });
      userGrowth.sort((a, b) => a['date'].compareTo(b['date']));
      
      // Calculate retention rate (simplified)
      final retentionRate = totalUsers > 0 ? (activeUsers / totalUsers) : 0.0;
      
      return UserMetrics(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        newUsers: newUsers,
        retentionRate: retentionRate,
        userGrowth: userGrowth,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user metrics: $e');
      }
      return UserMetrics(
        totalUsers: 0,
        activeUsers: 0,
        newUsers: 0,
        retentionRate: 0.0,
        userGrowth: [],
      );
    }
  }

  // Scan Metrics - calculates from actual scans collection
  Future<ScanMetrics> getScanMetrics() async {
    try {
      // Try to get from analytics collection first (if pre-aggregated)
      final analyticsDoc = await _firestore.collection('analytics').doc('scan_metrics').get();
      if (analyticsDoc.exists) {
        return ScanMetrics.fromFirestore(analyticsDoc);
      }
      
      // Otherwise, calculate from scans collection
      final scansSnapshot = await _firestore.collection('scans').get();
      final totalScans = scansSnapshot.docs.length;
      int successfulScans = 0;
      int failedScans = 0;
      final productCounts = <String, int>{};
      final scanTrends = <Map<String, dynamic>>[];
      final trendMap = <String, int>{};
      
      for (var doc in scansSnapshot.docs) {
        final scanData = doc.data();
        final isSuccessful = scanData['success'] == true || 
                            scanData['status'] == 'success';
        
        if (isSuccessful) {
          successfulScans++;
        } else {
          failedScans++;
        }
        
        // Track products
        final productName = scanData['productName'] as String?;
        if (productName != null) {
          productCounts[productName] = (productCounts[productName] ?? 0) + 1;
        }
        
        // Track trends
        final timestamp = scanData['timestamp'] as Timestamp? ?? 
                         scanData['createdAt'] as Timestamp?;
        if (timestamp != null) {
          final dateKey = timestamp.toDate().toIso8601String().substring(0, 10);
          trendMap[dateKey] = (trendMap[dateKey] ?? 0) + 1;
        }
      }
      
      // Convert product counts to top products list
      final topProducts = productCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topProductsList = topProducts.take(10).map((e) => {
        'name': e.key,
        'count': e.value,
      }).toList();
      
      // Convert trend map to list
      trendMap.forEach((date, count) {
        scanTrends.add({'date': date, 'count': count});
      });
      scanTrends.sort((a, b) => a['date'].compareTo(b['date']));
      
      final successRate = totalScans > 0 ? (successfulScans / totalScans) : 0.0;
      
      return ScanMetrics(
        totalScans: totalScans,
        successfulScans: successfulScans,
        failedScans: failedScans,
        successRate: successRate,
        topProducts: topProductsList,
        scanTrends: scanTrends,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting scan metrics: $e');
      }
      return ScanMetrics(
        totalScans: 0,
        successfulScans: 0,
        failedScans: 0,
        successRate: 0.0,
        topProducts: [],
        scanTrends: [],
      );
    }
  }

  // Sustainability Metrics - calculates from receipts and assessments collections
  Future<SustainabilityMetrics> getSustainabilityMetrics() async {
    try {
      // Try to get from analytics collection first (if pre-aggregated)
      final analyticsDoc = await _firestore.collection('analytics').doc('sustainability_metrics').get();
      if (analyticsDoc.exists) {
        return SustainabilityMetrics.fromFirestore(analyticsDoc);
      }
      
      // Try to get scores from receipts subcollections under users
      // Receipts are stored as: users/{userId}/receipts/{receiptId}
      final allReceipts = <QueryDocumentSnapshot>[];
      final userIds = <String>[];
      
      try {
        // First, try to get user IDs from users collection
        final usersSnapshot = await _firestore.collection('users').get();
        userIds.addAll(usersSnapshot.docs.map((doc) => doc.id));
      } catch (e) {
        if (kDebugMode) {
          print('Users collection not accessible: $e');
        }
      }
      
      // If users collection is empty, get user IDs from leaderboard collection
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
      
      // Now query receipts from each user's subcollection
      for (var userId in userIds) {
        try {
          final receiptsSnapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('receipts')
              .get();
          allReceipts.addAll(receiptsSnapshot.docs);
          if (kDebugMode && receiptsSnapshot.docs.isNotEmpty) {
            print('Found ${receiptsSnapshot.docs.length} receipts for user $userId');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error fetching receipts for user $userId: $e');
          }
        }
      }
      
      // Also try top-level receipts collection as fallback
      if (allReceipts.isEmpty) {
        try {
          final receiptsSnapshot = await _firestore.collection('receipts').get();
          allReceipts.addAll(receiptsSnapshot.docs);
        } catch (e) {
          if (kDebugMode) {
            print('Top-level receipts collection not accessible: $e');
          }
        }
      }
      
      if (kDebugMode) {
        print('Total receipts found: ${allReceipts.length}');
      }
      
      // Also try sustainability_assessments collection
      QuerySnapshot? assessmentsSnapshot;
      try {
        assessmentsSnapshot = await _firestore
            .collection('sustainability_assessments')
            .get();
      } catch (e) {
        if (kDebugMode) {
          print('Sustainability assessments collection not accessible: $e');
        }
      }
      
      // Combine data from both collections
      final allScores = <double>[];
      final scoreDistribution = <String, double>{};
      final scoreTrends = <Map<String, dynamic>>[];
      final trendMap = <String, List<double>>{};
      final environmentalImpact = <String, double>{};
      
      // Process receipts from subcollections
      if (allReceipts.isNotEmpty) {
        for (var doc in allReceipts) {
          final receiptData = doc.data() as Map<String, dynamic>;
          
          // Get overall score from receipt
          final overallScore = (receiptData['overallScore'] ?? 
                               receiptData['score'] ?? 
                               receiptData['sustainabilityScore'] ?? 
                               0.0).toDouble();
          
          if (overallScore > 0) {
            allScores.add(overallScore);
            
            // Score distribution (rounded to nearest 10)
            final scoreBucket = ((overallScore / 10).floor() * 10).toString();
            scoreDistribution[scoreBucket] = ((scoreDistribution[scoreBucket] ?? 0.0) + 1.0);
            
            // Track trends
            final timestamp = receiptData['timestamp'] as Timestamp? ?? 
                             receiptData['createdAt'] as Timestamp? ??
                             receiptData['date'] as Timestamp?;
            if (timestamp != null) {
              final dateKey = timestamp.toDate().toIso8601String().substring(0, 10);
              if (!trendMap.containsKey(dateKey)) {
                trendMap[dateKey] = [];
              }
              trendMap[dateKey]!.add(overallScore);
            }
          }
          
          // Process individual items if they exist
          final items = receiptData['items'] as List<dynamic>?;
          if (items != null) {
            for (var item in items) {
              if (item is Map<String, dynamic>) {
                final itemScore = (item['score'] ?? 
                                  item['sustainabilityScore'] ?? 
                                  0.0).toDouble();
                if (itemScore > 0) {
                  allScores.add(itemScore);
                  final scoreBucket = ((itemScore / 10).floor() * 10).toString();
                  scoreDistribution[scoreBucket] = ((scoreDistribution[scoreBucket] ?? 0.0) + 1.0);
                }
              }
            }
          }
        }
      }
      
      // Process sustainability_assessments collection
      if (assessmentsSnapshot != null) {
        for (var doc in assessmentsSnapshot.docs) {
          final assessmentData = doc.data() as Map<String, dynamic>;
          final score = (assessmentData['score'] ?? 
                        assessmentData['sustainabilityScore'] ?? 
                        0.0).toDouble();
          
          if (score > 0) {
            allScores.add(score);
            
            // Score distribution
            final scoreBucket = ((score / 10).floor() * 10).toString();
            scoreDistribution[scoreBucket] = ((scoreDistribution[scoreBucket] ?? 0.0) + 1.0);
            
            // Track trends
            final timestamp = assessmentData['timestamp'] as Timestamp? ?? 
                             assessmentData['createdAt'] as Timestamp?;
            if (timestamp != null) {
              final dateKey = timestamp.toDate().toIso8601String().substring(0, 10);
              if (!trendMap.containsKey(dateKey)) {
                trendMap[dateKey] = [];
              }
              trendMap[dateKey]!.add(score);
            }
            
            // Environmental impact metrics
            final impact = assessmentData['environmentalImpact'] as Map<String, dynamic>?;
            if (impact != null) {
              impact.forEach((key, value) {
                final numValue = (value is num) ? value.toDouble() : 0.0;
                environmentalImpact[key] = (environmentalImpact[key] ?? 0.0) + numValue;
              });
            }
          }
        }
      }
      
      final totalAssessments = allScores.length;
      if (totalAssessments == 0) {
        return SustainabilityMetrics(
          averageScore: 0.0,
          totalAssessments: 0,
          scoreDistribution: {},
          scoreTrends: [],
          environmentalImpact: {},
        );
      }
      
      // Convert trend map to average scores per day
      trendMap.forEach((date, scores) {
        final avgScore = scores.reduce((a, b) => a + b) / scores.length;
        scoreTrends.add({'date': date, 'score': avgScore as double});
      });
      scoreTrends.sort((a, b) => a['date'].compareTo(b['date']));
      
      final totalScore = allScores.reduce((a, b) => a + b);
      final averageScore = totalScore / totalAssessments;
      
      return SustainabilityMetrics(
        averageScore: averageScore,
        totalAssessments: totalAssessments,
        scoreDistribution: scoreDistribution,
        scoreTrends: scoreTrends,
        environmentalImpact: environmentalImpact,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting sustainability metrics: $e');
      }
      return SustainabilityMetrics(
        averageScore: 0.0,
        totalAssessments: 0,
        scoreDistribution: {},
        scoreTrends: [],
        environmentalImpact: {},
      );
    }
  }

  // Real-time updates for dashboard - listens to actual data collections
  Stream<UserMetrics> userMetricsStream() {
    // Listen to leaderboard collection (where the actual data is)
    // The getUserMetrics() function will check both users and leaderboard collections
    return _firestore
        .collection('leaderboard')
        .snapshots()
        .asyncMap((snapshot) => getUserMetrics());
  }

  Stream<ScanMetrics> scanMetricsStream() {
    // Listen to scans collection changes and recalculate metrics
    return _firestore
        .collection('scans')
        .snapshots()
        .asyncMap((snapshot) => getScanMetrics());
  }

  Stream<SustainabilityMetrics> sustainabilityMetricsStream() {
    // Listen to users collection changes to detect new receipts in subcollections
    // When users change, we'll recalculate metrics from all receipt subcollections
    return _firestore
        .collection('users')
        .snapshots()
        .asyncMap((snapshot) => getSustainabilityMetrics());
  }
  
  // Get score statistics (average, best, total)
  Future<Map<String, dynamic>> getScoreStatistics() async {
    try {
      // Get receipts from users subcollections
      final allReceipts = <QueryDocumentSnapshot>[];
      final userIds = <String>[];
      
      // Get user IDs from users collection or leaderboard
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
      
      // Fallback to top-level receipts collection
      if (allReceipts.isEmpty) {
        try {
          final receiptsSnapshot = await _firestore.collection('receipts').get();
          allReceipts.addAll(receiptsSnapshot.docs);
        } catch (e) {
          if (kDebugMode) {
            print('Top-level receipts collection not accessible: $e');
          }
        }
      }
      
      final scores = <double>[];
      
      for (var doc in allReceipts) {
        final receiptData = doc.data() as Map<String, dynamic>;
        final overallScore = (receiptData['overallScore'] ?? 
                            receiptData['score'] ?? 
                            receiptData['sustainabilityScore'] ?? 
                            0.0).toDouble();
        if (overallScore > 0) {
          scores.add(overallScore);
        }
      }
      
      if (scores.isEmpty) {
        return {
          'average': 0.0,
          'best': 0.0,
          'total': 0,
          'min': 0.0,
        };
      }
      
      scores.sort();
      return {
        'average': scores.reduce((a, b) => a + b) / scores.length,
        'best': scores.last,
        'total': scores.length,
        'min': scores.first,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting score statistics: $e');
      }
      return {
        'average': 0.0,
        'best': 0.0,
        'total': 0,
        'min': 0.0,
      };
    }
  }
}
