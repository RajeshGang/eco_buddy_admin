import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/analytics_service.dart';
import '../../models/user_metrics.dart';
import '../../models/scan_metrics.dart';
import '../../models/sustainability_metrics.dart';

class OverviewSection extends StatelessWidget {
  final AnalyticsService analyticsService;
  
  const OverviewSection({super.key, required this.analyticsService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserMetrics>(
      stream: analyticsService.userMetricsStream(),
      builder: (context, userSnapshot) {
        return StreamBuilder<ScanMetrics>(
          stream: analyticsService.scanMetricsStream(),
          builder: (context, scanSnapshot) {
            return StreamBuilder<SustainabilityMetrics>(
              stream: analyticsService.sustainabilityMetricsStream(),
              builder: (context, sustainabilitySnapshot) {
                final userMetrics = userSnapshot.data ?? UserMetrics(
                  totalUsers: 0,
                  activeUsers: 0,
                  newUsers: 0,
                  retentionRate: 0.0,
                  userGrowth: [],
                );
                
                final scanMetrics = scanSnapshot.data ?? ScanMetrics(
                  totalScans: 0,
                  successfulScans: 0,
                  failedScans: 0,
                  successRate: 0.0,
                  topProducts: [],
                  scanTrends: [],
                );
                
                final sustainabilityMetrics = sustainabilitySnapshot.data ?? SustainabilityMetrics(
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
                        'Dashboard Overview',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: _calculateCrossAxisCount(context),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildStatCard(
                            context,
                            title: 'Total Users',
                            value: '${userMetrics.totalUsers}',
                            icon: Icons.people,
                            color: Colors.blue,
                            subtitle: '${userMetrics.newUsers} new this week',
                          ),
                          _buildStatCard(
                            context,
                            title: 'Active Users',
                            value: '${userMetrics.activeUsers}',
                            icon: Icons.trending_up,
                            color: Colors.green,
                            subtitle: '${(userMetrics.retentionRate * 100).toStringAsFixed(1)}% retention',
                          ),
                          _buildStatCard(
                            context,
                            title: 'Total Scans',
                            value: '${scanMetrics.totalScans}',
                            icon: Icons.qr_code_scanner,
                            color: Colors.orange,
                            subtitle: '${(scanMetrics.successRate * 100).toStringAsFixed(1)}% success rate',
                          ),
                          _buildStatCard(
                            context,
                            title: 'Avg. Sustainability',
                            value: '${sustainabilityMetrics.averageScore.toStringAsFixed(1)}%',
                            icon: Icons.eco,
                            color: Colors.teal,
                            subtitle: '${sustainabilityMetrics.totalAssessments} assessments',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (userMetrics.userGrowth.isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User Growth Trend',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                _buildUserGrowthChart(userMetrics.userGrowth),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 2;
    return 1;
  }
  
  Widget _buildUserGrowthChart(List<Map<String, dynamic>> growthData) {
    if (growthData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No growth data available'),
        ),
      );
    }
    
    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value >= 0 && value < growthData.length) {
                    return Text(growthData[value.toInt()]['date'] ?? '');
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: growthData.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  (entry.value['count'] ?? 0).toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
