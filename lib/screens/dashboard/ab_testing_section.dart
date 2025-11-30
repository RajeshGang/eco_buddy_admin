import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class ABTestingSection extends StatefulWidget {
  const ABTestingSection({super.key});

  @override
  State<ABTestingSection> createState() => _ABTestingSectionState();
}

class _ABTestingSectionState extends State<ABTestingSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  @override
  void initState() {
    super.initState();
    _initializeRemoteConfig();
  }

  Future<void> _initializeRemoteConfig() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing Remote Config: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'A/B Testing & Feature Flags',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddFeatureFlagDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Feature Flag'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('feature_flags')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.flag, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No feature flags configured',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click "Add Feature Flag" to create one',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              
              final flags = snapshot.data!.docs;
              
              return Column(
                children: flags.map((doc) {
                  final flag = doc.data() as Map<String, dynamic>;
                  return _buildFeatureFlagCard(context, doc.id, flag);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureFlagCard(BuildContext context, String flagId, Map<String, dynamic> flag) {
    final isEnabled = flag['enabled'] ?? false;
    final variant = flag['variant'] ?? 'control';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flag['name'] ?? flagId,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        flag['description'] ?? 'No description',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (value) {
                    _updateFeatureFlag(flagId, {'enabled': value});
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Chip(
                  label: Text('Variant: $variant'),
                  backgroundColor: variant == 'control' 
                      ? Colors.blue[100] 
                      : Colors.green[100],
                ),
                const SizedBox(width: 8),
                if (flag['targetPercentage'] != null)
                  Chip(
                    label: Text('${flag['targetPercentage']}% users'),
                    backgroundColor: Colors.orange[100],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditFeatureFlagDialog(context, flagId, flag),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteFeatureFlag(context, flagId),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFeatureFlagDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final targetPercentageController = TextEditingController(text: '50');
    String selectedVariant = 'control';
    bool isEnabled = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Feature Flag'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Flag Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedVariant,
                  decoration: const InputDecoration(
                    labelText: 'Variant',
                    border: OutlineInputBorder(),
                  ),
                  items: ['control', 'variant_a', 'variant_b']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedVariant = value ?? 'control');
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetPercentageController,
                  decoration: const InputDecoration(
                    labelText: 'Target Percentage (0-100)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Enabled'),
                    const Spacer(),
                    Switch(
                      value: isEnabled,
                      onChanged: (value) {
                        setState(() => isEnabled = value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _createFeatureFlag(
                  nameController.text,
                  descriptionController.text,
                  selectedVariant,
                  int.tryParse(targetPercentageController.text) ?? 50,
                  isEnabled,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFeatureFlagDialog(BuildContext context, String flagId, Map<String, dynamic> flag) {
    final nameController = TextEditingController(text: flag['name'] ?? '');
    final descriptionController = TextEditingController(text: flag['description'] ?? '');
    final targetPercentageController = TextEditingController(
      text: (flag['targetPercentage'] ?? 50).toString(),
    );
    String selectedVariant = flag['variant'] ?? 'control';
    bool isEnabled = flag['enabled'] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Feature Flag'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Flag Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedVariant,
                  decoration: const InputDecoration(
                    labelText: 'Variant',
                    border: OutlineInputBorder(),
                  ),
                  items: ['control', 'variant_a', 'variant_b']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedVariant = value ?? 'control');
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetPercentageController,
                  decoration: const InputDecoration(
                    labelText: 'Target Percentage (0-100)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Enabled'),
                    const Spacer(),
                    Switch(
                      value: isEnabled,
                      onChanged: (value) {
                        setState(() => isEnabled = value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateFeatureFlag(flagId, {
                  'name': nameController.text,
                  'description': descriptionController.text,
                  'variant': selectedVariant,
                  'targetPercentage': int.tryParse(targetPercentageController.text) ?? 50,
                  'enabled': isEnabled,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createFeatureFlag(
    String name,
    String description,
    String variant,
    int targetPercentage,
    bool enabled,
  ) async {
    try {
      await _firestore.collection('feature_flags').add({
        'name': name,
        'description': description,
        'variant': variant,
        'targetPercentage': targetPercentage,
        'enabled': enabled,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feature flag created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating feature flag: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateFeatureFlag(String flagId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('feature_flags').doc(flagId).update(updates);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feature flag updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating feature flag: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFeatureFlag(BuildContext context, String flagId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feature Flag'),
        content: const Text('Are you sure you want to delete this feature flag?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('feature_flags').doc(flagId).delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Feature flag deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting feature flag: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
