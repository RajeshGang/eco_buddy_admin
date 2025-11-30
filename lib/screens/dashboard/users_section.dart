import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersSection extends StatelessWidget {
  const UsersSection({super.key});

  // Get users stream - tries users collection first, falls back to leaderboard
  Stream<QuerySnapshot> _getUsersStream() {
    // Try leaderboard first (where the actual data is)
    // If users collection exists and has data, it will be used instead
    return FirebaseFirestore.instance
        .collection('leaderboard')
        .orderBy('lastUpdated', descending: true)
        .limit(50)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Activity & Analytics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot>(
            stream: _getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                final error = snapshot.error.toString();
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Permission Error',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Refresh the page
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const UsersSection(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Make sure you are logged in as an admin.\nYour user UID must exist in the "admins" collection.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No user data available'),
                  ),
                );
              }
              
              final users = snapshot.data!.docs;
              
              return Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Recent User Activity',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Chip(
                            label: Text('${users.length} users'),
                            backgroundColor: Colors.green[100],
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index].data() as Map<String, dynamic>;
                        final userId = users[index].id;
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(
                              (user['displayName'] ?? user['email'] ?? 'U')
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),
                            ),
                          ),
                          title: Text(
                            user['displayName'] ?? user['email'] ?? 'Unknown User',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (user['email'] != null)
                                Text(user['email']),
                              if (user['totalPoints'] != null)
                                Text(
                                  '${user['totalPoints']} points',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (user['lastActive'] != null || user['lastUpdated'] != null)
                                Text(
                                  _formatTimestamp(user['lastActive'] ?? user['lastUpdated']),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              if (user['isActive'] == true || user['isActive'] == 'true')
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            _showUserDetails(context, userId, user);
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Never';
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is Map) {
        final seconds = timestamp['_seconds'];
        dateTime = (seconds is int)
            ? DateTime.fromMillisecondsSinceEpoch(seconds * 1000)
            : DateTime.now();
      } else {
        return 'Unknown';
      }
      
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
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showUserDetails(BuildContext context, String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(userData['displayName'] ?? 'User Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('User ID', userId),
              _buildDetailRow('Email', userData['email'] ?? 'N/A'),
              _buildDetailRow('Display Name', userData['displayName'] ?? 'N/A'),
              if (userData['totalPoints'] != null)
                _buildDetailRow('Total Points', userData['totalPoints'].toString()),
              _buildDetailRow('Created', _formatTimestamp(userData['createdAt'])),
              _buildDetailRow('Last Active', _formatTimestamp(userData['lastActive'] ?? userData['lastUpdated'])),
              _buildDetailRow('Active', userData['isActive'] == true ? 'Yes' : 'No'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
