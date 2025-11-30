import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/analytics_service.dart';
import '../../models/sustainability_metrics.dart';

class SustainabilitySection extends StatelessWidget {
  const SustainabilitySection({super.key});

  @override
  Widget build(BuildContext context) {
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    
    return StreamBuilder<SustainabilityMetrics>(
      stream: analyticsService.sustainabilityMetricsStream(),
      builder: (context, snapshot) {
        final metrics = snapshot.data ?? SustainabilityMetrics(
          averageScore: 0.0,
          totalAssessments: 0,
          scoreDistribution: {},
          scoreTrends: [],
          environmentalImpact: {},
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sustainability Analytics',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Average Score',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${metrics.averageScore.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Assessments',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${metrics.totalAssessments}',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (metrics.scoreDistribution.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Score Distribution',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ...metrics.scoreDistribution.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text('${entry.key}%'),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: LinearProgressIndicator(
                                    value: entry.value / metrics.totalAssessments,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${entry.value}'),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              if (metrics.environmentalImpact.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Environmental Impact',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ...metrics.environmentalImpact.entries.map((entry) {
                          return ListTile(
                            leading: Icon(Icons.eco, color: Colors.green),
                            title: Text(entry.key),
                            trailing: Text(
                              entry.value.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

