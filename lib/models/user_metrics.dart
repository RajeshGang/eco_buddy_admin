import 'package:cloud_firestore/cloud_firestore.dart';

class UserMetrics {
  final int totalUsers;
  final int activeUsers;
  final int newUsers;
  final double retentionRate;
  final List<Map<String, dynamic>> userGrowth;

  UserMetrics({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsers,
    required this.retentionRate,
    required this.userGrowth,
  });

  factory UserMetrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserMetrics(
      totalUsers: data['totalUsers'] ?? 0,
      activeUsers: data['activeUsers'] ?? 0,
      newUsers: data['newUsers'] ?? 0,
      retentionRate: (data['retentionRate'] ?? 0.0).toDouble(),
      userGrowth: List<Map<String, dynamic>>.from(data['userGrowth'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'newUsers': newUsers,
        'retentionRate': retentionRate,
        'userGrowth': userGrowth,
      };
}
