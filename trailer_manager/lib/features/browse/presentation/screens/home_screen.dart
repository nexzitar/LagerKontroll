import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../capture/presentation/screens/capture_screen.dart';

/// Home screen showing trailer list
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConfig.largePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_shipping,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppConfig.largePadding),
              Text(
                'Welcome to ${AppConstants.appName}',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConfig.defaultPadding),
              Text(
                'Track and manage your trailer storage',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConfig.largePadding * 2),
              _buildFeatureCard(
                context,
                icon: Icons.camera_alt,
                title: 'Capture',
                description: 'Take photos of trailers and their contents',
              ),
              const SizedBox(height: AppConfig.defaultPadding),
              _buildFeatureCard(
                context,
                icon: Icons.list,
                title: 'Browse',
                description: 'View and search all trailer entries',
              ),
              const SizedBox(height: AppConfig.defaultPadding),
              _buildFeatureCard(
                context,
                icon: Icons.map,
                title: 'Track',
                description: 'See trailer locations on the map',
              ),
              const SizedBox(height: AppConfig.largePadding * 2),
              Text(
                'App is ready! Core infrastructure implemented.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConfig.smallPadding),
              Text(
                'Next: Implement features (capture, browse, detail)',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CaptureScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_a_photo),
        label: const Text('New Entry'),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Text(description),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title feature coming soon!')),
          );
        },
      ),
    );
  }
}
