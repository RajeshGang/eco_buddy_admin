import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          // Recent Receipts
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Receipts',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Icon(Icons.receipt_long, color: Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRecentReceipts(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Recent Leaderboard Updates
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Leaderboard Updates',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Icon(Icons.leaderboard, color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRecentLeaderboardUpdates(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReceipts() {
    // Get user IDs from leaderboard
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leaderboard')
          .limit(5)
          .snapshots(),
      builder: (context, leaderboardSnapshot) {
        if (!leaderboardSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userIds = leaderboardSnapshot.data!.docs.map((doc) => doc.id).toList();
        if (userIds.isEmpty) {
          return const Text('No users found');
        }

        // Get recent receipts from first user (for demo - in production, aggregate from all)
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userIds.first)
              .collection('receipts')
              .orderBy('timestamp', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No recent receipts'),
              );
            }

            final receipts = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: receipts.length,
              itemBuilder: (context, index) {
                final receipt = receipts[index].data() as Map<String, dynamic>;
                final score = receipt['overallScore'] ?? 
                             receipt['score'] ?? 
                             receipt['sustainabilityScore'] ?? 
                             0;
                final items = receipt['items'] as List<dynamic>?;
                final itemCount = items?.length ?? 0;
                final timestamp = receipt['timestamp'] as Timestamp? ?? 
                                 receipt['createdAt'] as Timestamp?;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getScoreColor(score),
                    child: Text(
                      score.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text('Receipt with $itemCount items'),
                  subtitle: Text(
                    timestamp != null
                        ? _formatTimestamp(timestamp)
                        : 'Unknown date',
                  ),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRecentLeaderboardUpdates() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leaderboard')
          .orderBy('lastUpdated', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No leaderboard updates'),
          );
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            final displayName = user['displayName'] ?? 'Unknown';
            final points = user['totalPoints'] ?? 0;
            final lastUpdated = user['lastUpdated'] as Timestamp?;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: Text(
                  displayName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(displayName),
              subtitle: Text(
                lastUpdated != null
                    ? _formatTimestamp(lastUpdated)
                    : 'Unknown',
              ),
              trailing: Chip(
                label: Text(
                  '$points pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.green[700],
              ),
            );
          },
        );
      },
    );
  }

  Color _getScoreColor(dynamic score) {
    final scoreNum = (score is num) ? score.toDouble() : 0.0;
    if (scoreNum >= 70) return Colors.green;
    if (scoreNum >= 50) return Colors.orange;
    return Colors.red;
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

