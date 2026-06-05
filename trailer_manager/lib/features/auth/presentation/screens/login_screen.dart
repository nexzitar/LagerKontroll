import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../providers/auth_provider.dart';

/// Login screen
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String _countryCode = '+47';

  @override
  void initState() {
    super.initState();
    // Load saved credentials if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedCreds = ref.read(authProvider.notifier).getSavedCredentials();
      if (savedCreds != null) {
        final phone = savedCreds['phoneNumber'] ?? '';
        // Split country code and phone number
        if (phone.startsWith('+')) {
          for (final code in ['+47', '+46', '+45', '+1', '+44']) {
            if (phone.startsWith(code)) {
              setState(() {
                _countryCode = code;
                _phoneController.text = phone.substring(code.length);
                _passwordController.text = savedCreds['password'] ?? '';
                _rememberMe = true;
              });
              break;
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final fullPhoneNumber = '$_countryCode${_phoneController.text.trim()}';

    await ref.read(authProvider.notifier).loginWithPhone(
          fullPhoneNumber,
          _passwordController.text,
          rememberMe: _rememberMe,
        );

    // Navigation will happen automatically because MaterialApp
    // watches authProvider and will rebuild with TrailerListScreen
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Show error message if any
    ref.listen(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConfig.defaultPadding * 2),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Title
                  Icon(
                    Icons.local_shipping,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Trailer Manager',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Phone number field
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
                        textInputAction: TextInputAction.next,
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

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Remember me checkbox
                  CheckboxListTile(
                    title: const Text('Remember me'),
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),

                  // Submit button
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
