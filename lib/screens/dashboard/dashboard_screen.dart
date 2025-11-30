import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import 'overview_section.dart';
import 'users_section.dart';
import 'ab_testing_section.dart';
import 'sustainability_section.dart';
import 'system_section.dart';
import 'firestore_diagnostics.dart';
import '../../widgets/admin_status_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final analyticsService = Provider.of<AnalyticsService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoSustain Admin'),
        actions: [
          // Show current user info
          FutureBuilder(
            future: Provider.of<AuthService>(context, listen: false).getUserProfile(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final profile = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Center(
                    child: Text(
                      profile['email'] ?? 'Admin',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.signOut();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Overview'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.eco),
                label: Text('Sustainability'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.science),
                label: Text('A/B Testing'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.monitor_heart),
                label: Text('System'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bug_report),
                label: Text('Diagnostics'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Column(
              children: [
                const AdminStatusWidget(),
                Expanded(
                  child: _SelectedPage(
                    selectedIndex: _selectedIndex,
                    analyticsService: analyticsService,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedPage extends StatelessWidget {
  final int selectedIndex;
  final AnalyticsService analyticsService;

  const _SelectedPage({
    required this.selectedIndex,
    required this.analyticsService,
  });

  @override
  Widget build(BuildContext context) {
    switch (selectedIndex) {
      case 0:
        return OverviewSection(analyticsService: analyticsService);
      case 1:
        return const UsersSection();
      case 2:
        return const SustainabilitySection();
      case 3:
        return const ABTestingSection();
      case 4:
        return const SystemSection();
      case 5:
        return const FirestoreDiagnostics();
      default:
        return OverviewSection(analyticsService: analyticsService);
    }
  }
}
