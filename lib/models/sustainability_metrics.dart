import 'package:cloud_firestore/cloud_firestore.dart';

class SustainabilityMetrics {
  final double averageScore;
  final int totalAssessments;
  final Map<String, double> scoreDistribution;
  final List<Map<String, dynamic>> scoreTrends;
  final Map<String, dynamic> environmentalImpact;

  SustainabilityMetrics({
    required this.averageScore,
    required this.totalAssessments,
    required this.scoreDistribution,
    required this.scoreTrends,
    required this.environmentalImpact,
  });

  factory SustainabilityMetrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SustainabilityMetrics(
      averageScore: (data['averageScore'] ?? 0.0).toDouble(),
      totalAssessments: data['totalAssessments'] ?? 0,
      scoreDistribution: Map<String, double>.from(data['scoreDistribution'] ?? {}),
      scoreTrends: List<Map<String, dynamic>>.from(data['scoreTrends'] ?? []),
      environmentalImpact: Map<String, dynamic>.from(data['environmentalImpact'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'averageScore': averageScore,
        'totalAssessments': totalAssessments,
        'scoreDistribution': scoreDistribution,
        'scoreTrends': scoreTrends,
        'environmentalImpact': environmentalImpact,
      };
}
