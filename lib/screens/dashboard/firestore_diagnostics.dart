import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Diagnostic screen to see what's actually in Firestore
class FirestoreDiagnostics extends StatelessWidget {
  const FirestoreDiagnostics({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Diagnostics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Collections in Firestore',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCollectionInfo('users', 'users'),
            const SizedBox(height: 16),
            _buildCollectionInfo('scans', 'scans'),
            const SizedBox(height: 16),
            _buildCollectionInfo('sustainability_assessments', 'sustainability_assessments'),
            const SizedBox(height: 16),
            _buildCollectionInfo('leaderboard', 'leaderboard'),
            const SizedBox(height: 16),
            _buildCollectionInfo('receipts', 'receipts'),
            const SizedBox(height: 16),
            _buildCollectionInfo('receipt_history', 'receipt_history'),
            const SizedBox(height: 16),
            _buildCollectionInfo('progress', 'progress'),
            const SizedBox(height: 16),
            _buildCollectionInfo('user_progress', 'user_progress'),
            const SizedBox(height: 16),
            _buildCollectionInfo('scores', 'scores'),
            const SizedBox(height: 16),
            _buildCollectionInfo('calculations', 'calculations'),
            const SizedBox(height: 16),
            _buildCollectionInfo('user_scores', 'user_scores'),
            const SizedBox(height: 16),
            _buildCollectionInfo('score_breakdown', 'score_breakdown'),
            const SizedBox(height: 16),
            _buildCollectionInfo('admins', 'admins'),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionInfo(String collectionName, String key) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Collection: $collectionName',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(collectionName)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text(
                    '⚠️ Collection is empty or does not exist',
                    style: TextStyle(color: Colors.orange),
                  );
                }

                final docs = snapshot.data!.docs;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Found ${docs.length} document(s) (showing first 5)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...docs.map((doc) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Document ID: ${doc.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fields: ${(doc.data() as Map<String, dynamic>).keys.join(", ")}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sample data: ${doc.data().toString().substring(0, doc.data().toString().length > 200 ? 200 : doc.data().toString().length)}...',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        )),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

