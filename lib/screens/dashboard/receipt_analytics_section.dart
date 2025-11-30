import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../services/receipt_analytics_service.dart';

class ReceiptAnalyticsSection extends StatelessWidget {
  const ReceiptAnalyticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final receiptService = Provider.of<ReceiptAnalyticsService>(context, listen: false);
    
    return StreamBuilder<Map<String, dynamic>>(
      stream: receiptService.receiptAnalyticsStream(),
      builder: (context, snapshot) {
        final analytics = snapshot.data ?? {
          'totalReceipts': 0,
          'totalItems': 0,
          'averageItemsPerReceipt': 0.0,
          'averageScore': 0.0,
          'categoryBreakdown': <String, int>{},
          'receiptTrends': <Map<String, dynamic>>[],
          'totalValue': 0.0,
        };

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Receipt Analytics',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              // Key Metrics Cards
              GridView.count(
                crossAxisCount: _calculateCrossAxisCount(context),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatCard(
                    context,
                    title: 'Total Receipts',
                    value: '${analytics['totalReceipts']}',
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                    subtitle: 'Analyzed receipts',
                  ),
                  _buildStatCard(
                    context,
                    title: 'Total Items',
                    value: '${analytics['totalItems']}',
                    icon: Icons.shopping_cart,
                    color: Colors.orange,
                    subtitle: 'Items scanned',
                  ),
                  _buildStatCard(
                    context,
                    title: 'Avg Items/Receipt',
                    value: '${(analytics['averageItemsPerReceipt'] as num).toStringAsFixed(1)}',
                    icon: Icons.list,
                    color: Colors.purple,
                    subtitle: 'Per receipt',
                  ),
                  _buildStatCard(
                    context,
                    title: 'Avg Score',
                    value: '${(analytics['averageScore'] as num).toStringAsFixed(1)}',
                    icon: Icons.star,
                    color: Colors.green,
                    subtitle: 'Sustainability',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Receipt Trends Chart
              if ((analytics['receiptTrends'] as List).isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receipt Trends',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildReceiptTrendChart(analytics['receiptTrends'] as List<Map<String, dynamic>>),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              // Category Breakdown
              if ((analytics['categoryBreakdown'] as Map).isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category Breakdown',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ...(analytics['categoryBreakdown'] as Map<String, int>).entries.map((entry) {
                          final total = (analytics['totalItems'] as int);
                          final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: total > 0 ? entry.value / total : 0.0,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(entry.key)),
                                ),
                              ],
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

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 2;
    return 1;
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

  Widget _buildReceiptTrendChart(List<Map<String, dynamic>> trends) {
    if (trends.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No receipt trend data available'),
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
                  if (value >= 0 && value < trends.length) {
                    final date = trends[value.toInt()]['date'] as String? ?? '';
                    if (date.length >= 10) {
                      return Text(date.substring(5, 10));
                    }
                    return Text(date);
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString());
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: trends.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  (entry.value['receipts'] ?? 0).toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withValues(alpha: 0.1),
              ),
            ),
          ],
          minY: 0,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food & Grocery': Colors.green,
      'Personal Care': Colors.pink,
      'General': Colors.grey,
      'Unknown': Colors.grey,
    };
    return colors[category] ?? Colors.blue;
  }
}

