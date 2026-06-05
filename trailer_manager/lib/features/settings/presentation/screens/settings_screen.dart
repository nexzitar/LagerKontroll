import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_theme.dart';

/// Settings screen for app configuration
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme Settings Section
          _buildSectionHeader('Appearance'),
          _buildThemeOption(
            title: 'Light Mode',
            icon: Icons.light_mode,
            isSelected: themeMode == ThemeMode.light,
            onTap: () => themeNotifier.setLight(),
          ),
          _buildThemeOption(
            title: 'Dark Mode',
            icon: Icons.dark_mode,
            isSelected: themeMode == ThemeMode.dark,
            onTap: () => themeNotifier.setDark(),
          ),
          _buildThemeOption(
            title: 'System Default',
            icon: Icons.brightness_auto,
            isSelected: themeMode == ThemeMode.system,
            onTap: () => themeNotifier.setSystem(),
          ),

          const Divider(),

          // App Info Section
          _buildSectionHeader('About'),
          _buildInfoTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: _packageInfo != null
                ? '${_packageInfo!.version} (${_packageInfo!.buildNumber})'
                : 'Loading...',
          ),
          _buildInfoTile(
            icon: Icons.storage_outlined,
            title: 'API Endpoint',
            subtitle: AppConfig.apiBaseUrl,
          ),
          _buildInfoTile(
            icon: Icons.history,
            title: 'History Entries Limit',
            subtitle: '${AppConfig.defaultHistoryCount} entries',
          ),
          _buildInfoTile(
            icon: Icons.info_outline,
            title: 'OTA Updates',
            subtitle: 'Shorebird enabled - auto-updates active',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConfig.defaultPadding,
        AppConfig.largePadding,
        AppConfig.defaultPadding,
        AppConfig.smallPadding,
      ),
      child: Text(
        title,
        style: AppTheme.headingSmall.copyWith(
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : null,
      ),
      title: Text(title),
      trailing: isSelected
          ? const Icon(
              Icons.check_circle,
              color: AppTheme.primaryColor,
            )
          : null,
      selected: isSelected,
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
