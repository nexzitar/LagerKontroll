import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/sms_service.dart';
import '../providers/auth_provider.dart';
import '../providers/user_management_provider.dart';

/// Admin panel for managing users
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'user';
  String _countryCode = '+47'; // Default to Norway
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Load users when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userManagementProvider.notifier).getAllUsers();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendWelcomeSMS(
    String phoneNumber,
    String userName,
    String password,
  ) async {
    const downloadUrl = 'https://lassi.cloud/downloads/trailer-manager.apk';

    final message = '''Welcome to Trailer Manager, $userName!

Your Login:
Phone: $phoneNumber
Password: $password

Download the app:
$downloadUrl

Please change your password after first login.''';

    try {
      final smsService = SmsService();
      final success = await smsService.sendSms(
        phoneNumber: phoneNumber,
        message: message,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send SMS'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending SMS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changeUserRole(String userId, String userName, String currentRole, String newRole) async {
    try {
      final dioClient = ref.read(dioClientProvider);
      await dioClient.put(
        '/auth/users/$userId/role',
        data: {'role': newRole},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role changed to $newRole for $userName'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh user list
        ref.read(userManagementProvider.notifier).getAllUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId, String userName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete user "$userName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final dioClient = ref.read(dioClientProvider);
      await dioClient.delete('/auth/users/$userId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh user list
        ref.read(userManagementProvider.notifier).getAllUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final dioClient = ref.read(dioClientProvider);

      final fullPhoneNumber = '$_countryCode${_phoneController.text.trim()}';

      final data = {
        'name': _nameController.text.trim(),
        'phoneNumber': fullPhoneNumber,
        'role': _selectedRole,
      };

      final response = await dioClient.post('/auth/users', data: data);
      final success = response.statusCode == 201;

      if (mounted) {
        if (success) {
          // Get the generated password from response
          final generatedPassword = response.data['password'] as String;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User created! Sending SMS...'),
              backgroundColor: Colors.green,
            ),
          );

          // Send SMS with generated password
          await _sendWelcomeSMS(
            fullPhoneNumber,
            _nameController.text.trim(),
            generatedPassword,
          );

          // Clear form
          _nameController.clear();
          _phoneController.clear();
          setState(() {
            _selectedRole = 'user';
          });

          // Refresh user list
          ref.read(userManagementProvider.notifier).getAllUsers();
        } else {
          final error = ref.read(userManagementProvider).error ?? 'Failed to create user';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
          ref.read(userManagementProvider.notifier).clearError();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userManagementState = ref.watch(userManagementProvider);

    // Check if user is admin
    if (authState.user?.isAdmin != true) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
        ),
        body: const Center(
          child: Text('Access Denied: Admin privileges required'),
        ),
      );
    }

    // Show error if any
    ref.listen(userManagementProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(userManagementProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Create User Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConfig.defaultPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create New User',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Name field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          hintText: 'Enter user name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Password will be auto-generated',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Role selector
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          prefixIcon: Icon(Icons.admin_panel_settings),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'user',
                            child: Text('User'),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
                          DropdownMenuItem(
                            value: 'guest',
                            child: Text('Guest'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value ?? 'user';
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Country code selector
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _countryCode,
                            decoration: const InputDecoration(
                              labelText: 'Country Code',
                              prefixIcon: Icon(Icons.flag),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: '+47',
                                child: Text('+47 (Norway)'),
                              ),
                              DropdownMenuItem(
                                value: '+46',
                                child: Text('+46 (Sweden)'),
                              ),
                              DropdownMenuItem(
                                value: '+45',
                                child: Text('+45 (Denmark)'),
                              ),
                              DropdownMenuItem(
                                value: '+1',
                                child: Text('+1 (US/Canada)'),
                              ),
                              DropdownMenuItem(
                                value: '+44',
                                child: Text('+44 (UK)'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _countryCode = value ?? '+47';
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              hintText: '12345678',
                              prefixIcon: const Icon(Icons.phone),
                              prefix: Text(
                                '$_countryCode ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (value.length < 8) {
                                return 'Too short';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Create button
                      ElevatedButton(
                        onPressed: _isCreating ? null : _createUser,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: _isCreating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Create User'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // User List Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConfig.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Existing Users',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            ref.read(userManagementProvider.notifier).getAllUsers();
                          },
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (userManagementState.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (userManagementState.users.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'No users found',
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: userManagementState.users.length,
                        itemBuilder: (context, index) {
                          final user = userManagementState.users[index];
                          final dateFormat = DateFormat('MMM d, yyyy');
                          final isCurrentUser = user.id == authState.user?.id;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        child: Text(
                                          user.name[0].toUpperCase(),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    user.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: user.role == 'admin'
                                                        ? Colors.orange.withOpacity(0.2)
                                                        : user.role == 'guest'
                                                            ? Colors.grey.withOpacity(0.2)
                                                            : Colors.blue.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    user.role.toUpperCase(),
                                                    style: TextStyle(
                                                      color: user.role == 'admin'
                                                          ? Colors.orange
                                                          : user.role == 'guest'
                                                              ? Colors.grey[700]
                                                              : Colors.blue,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              user.phoneNumber ?? user.email,
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Created: ${dateFormat.format(user.createdAt.toLocal())}',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isCurrentUser)
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteUser(user.id, user.name),
                                          tooltip: 'Delete user',
                                        ),
                                    ],
                                  ),
                                  if (!isCurrentUser)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.admin_panel_settings, size: 16),
                                          const SizedBox(width: 8),
                                          const Text('Role:', style: TextStyle(fontSize: 13)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: DropdownButtonFormField<String>(
                                              value: user.role,
                                              decoration: const InputDecoration(
                                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                isDense: true,
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 'user',
                                                  child: Text('User', style: TextStyle(fontSize: 13)),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'admin',
                                                  child: Text('Admin', style: TextStyle(fontSize: 13)),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'guest',
                                                  child: Text('Guest', style: TextStyle(fontSize: 13)),
                                                ),
                                              ],
                                              onChanged: (newRole) {
                                                if (newRole != null && newRole != user.role) {
                                                  _changeUserRole(user.id, user.name, user.role, newRole);
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
