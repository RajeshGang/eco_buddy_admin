import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/auth_service.dart';
import '../screens/dashboard/dashboard_screen.dart';

class AdminStatusWidget extends StatelessWidget {
  const AdminStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<bool>(
      future: authService.isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final isAdmin = snapshot.data ?? false;

        if (!isAdmin) {
          return Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Admin Access Required',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your account (${currentUser.email}) is not in the admins collection.',
                  style: TextStyle(color: Colors.orange[800]),
                ),
                const SizedBox(height: 8),
                Text(
                  'To fix this:\n1. Go to Firebase Console → Firestore → admins collection\n2. Add a document with ID: ${currentUser.uid}\n3. Refresh this page',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final authService = Provider.of<AuthService>(context, listen: false);
                      await authService.addSelfToAdmins();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully added to admins! Refreshing...'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Small delay to show the message, then refresh
                      await Future.delayed(const Duration(milliseconds: 500));
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const DashboardScreen(),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Add Me to Admins (Auto)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

