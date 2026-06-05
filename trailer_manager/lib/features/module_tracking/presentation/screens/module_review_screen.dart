import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/sms_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/module_entry.dart';
import '../providers/module_tracking_provider.dart';

/// Default phone number for SMS sending (fallback if no last used number)
const String _defaultPhoneNumber = '+4740018402';

/// Storage key for last used phone number
const String _lastPhoneNumberKey = 'module_tracking_last_phone';

/// Screen for reviewing captured modules before sending
class ModuleReviewScreen extends ConsumerStatefulWidget {
  const ModuleReviewScreen({super.key});

  @override
  ConsumerState<ModuleReviewScreen> createState() => _ModuleReviewScreenState();
}

class _ModuleReviewScreenState extends ConsumerState<ModuleReviewScreen> {
  final _smsService = SmsService();
  bool _isSending = false;

  /// Get the last used phone number from storage
  String _getLastUsedPhoneNumber() {
    try {
      final box = Hive.box(AppConstants.settingsBoxName);
      final lastPhone = box.get(_lastPhoneNumberKey) as String?;
      return lastPhone ?? _defaultPhoneNumber;
    } catch (e) {
      logger.error('Error getting last phone number: $e');
      return _defaultPhoneNumber;
    }
  }

  /// Save the phone number to storage for next time
  Future<void> _saveLastUsedPhoneNumber(String phoneNumber) async {
    try {
      final box = Hive.box(AppConstants.settingsBoxName);
      await box.put(_lastPhoneNumberKey, phoneNumber);
      logger.info('Saved last used phone number');
    } catch (e) {
      logger.error('Error saving last phone number: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  Future<void> _copyToClipboard() async {
    final session = ref.read(moduleTrackingProvider);
    final formattedText = session.toFormattedText();

    await Clipboard.setData(ClipboardData(text: formattedText));
    _showSnackBar('Copied to clipboard');
    logger.info('Module list copied to clipboard');
  }

  void _showEditDialog(int index, ModuleEntry entry) {
    final licensePlateController = TextEditingController(text: entry.licensePlate);
    final containerIdController = TextEditingController(text: entry.containerId ?? '');
    final terminalController = TextEditingController(text: entry.terminal);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: licensePlateController,
                decoration: const InputDecoration(
                  labelText: 'License Plate *',
                  prefixIcon: Icon(Icons.directions_car),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: AppConfig.defaultPadding),
              TextField(
                controller: containerIdController,
                decoration: const InputDecoration(
                  labelText: 'Container ID (optional)',
                  prefixIcon: Icon(Icons.inventory),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: AppConfig.defaultPadding),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: entry.terminal),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return AppConfig.terminals;
                  }
                  return AppConfig.terminals.where((String option) {
                    return option.toLowerCase().contains(
                        textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  terminalController.text = selection;
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  // Sync with our controller
                  if (terminalController.text.isNotEmpty &&
                      textEditingController.text.isEmpty) {
                    textEditingController.text = terminalController.text;
                  }
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Terminal *',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) {
                      terminalController.text = value;
                    },
                  );
                },
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
              final licensePlate = licensePlateController.text.trim();
              final terminal = terminalController.text.trim();

              if (licensePlate.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('License plate is required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (terminal.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Terminal is required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final containerId = containerIdController.text.trim();
              final updatedEntry = entry.copyWith(
                licensePlate: licensePlate.toUpperCase(),
                containerId: containerId.isNotEmpty ? containerId : null,
                terminal: terminal.toUpperCase(),
              );

              ref.read(moduleTrackingProvider.notifier).updateEntry(index, updatedEntry);
              Navigator.of(context).pop();
              _showSnackBar('Entry updated');
              logger.info('Updated module entry at index $index');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteEntry(int index) {
    ref.read(moduleTrackingProvider.notifier).removeEntry(index);
    _showSnackBar('Entry deleted');
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Entries?'),
        content: const Text(
          'This will remove all captured modules from the current session. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(moduleTrackingProvider.notifier).clearSession();
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to capture screen
              _showSnackBar('Session cleared');
              logger.info('Module tracking session cleared');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showSendDialog() {
    final phoneController = TextEditingController(text: _getLastUsedPhoneNumber());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Module List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the phone number to send the module list to:'),
            const SizedBox(height: AppConfig.defaultPadding),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                hintText: '+47 12345678',
              ),
              keyboardType: TextInputType.phone,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final phoneNumber = phoneController.text.trim();
              if (!_smsService.isValidPhoneNumber(phoneNumber)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid phone number'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.of(context).pop();
              _sendSms(phoneNumber);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSms(String phoneNumber) async {
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      final session = ref.read(moduleTrackingProvider);
      final formattedText = session.toFormattedText();

      logger.info('Sending module list to $phoneNumber');
      final success = await _smsService.sendSms(
        phoneNumber: phoneNumber,
        message: formattedText,
      );

      if (success) {
        // Save the phone number for next time
        await _saveLastUsedPhoneNumber(phoneNumber);
        _showSnackBar('Module list sent successfully');
        logger.info('Module list sent successfully to $phoneNumber');
      } else {
        _showSnackBar('Failed to send SMS', isError: true);
        logger.error('Failed to send module list SMS');
      }
    } catch (e) {
      logger.error('Error sending SMS: $e');
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  // Find the actual index in the full entries list
  int _findEntryIndex(ModuleEntry entry, List<ModuleEntry> allEntries) {
    for (int i = 0; i < allEntries.length; i++) {
      if (allEntries[i] == entry) {
        return i;
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(moduleTrackingProvider);
    final entriesByTerminal = session.entriesByTerminal;
    final sortedTerminals = entriesByTerminal.keys.toList()..sort();
    final dateStr = DateFormat('yyyy-MM-dd').format(session.sessionStart);

    return Scaffold(
      appBar: AppBar(
        title: Text('Moduler ($dateStr)'),
        actions: [
          if (session.hasEntries)
            IconButton(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.copy),
              tooltip: 'Copy to clipboard',
            ),
          if (session.hasEntries)
            IconButton(
              onPressed: _showClearConfirmation,
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: session.hasEntries
          ? Column(
              children: [
                // Total count header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConfig.defaultPadding,
                    vertical: AppConfig.smallPadding,
                  ),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${session.entryCount} module${session.entryCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Continue Capture'),
                      ),
                    ],
                  ),
                ),

                // Entries grouped by terminal
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: sortedTerminals.length,
                    itemBuilder: (context, terminalIndex) {
                      final terminal = sortedTerminals[terminalIndex];
                      final entries = entriesByTerminal[terminal]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Terminal header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConfig.defaultPadding,
                              vertical: AppConfig.smallPadding,
                            ),
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Text(
                              terminal,
                              style: AppTheme.headingSmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),

                          // Entries for this terminal
                          ...entries.map((entry) {
                            final entryIndex = _findEntryIndex(entry, session.entries);
                            return Dismissible(
                              key: Key('${entry.licensePlate}_${entry.capturedAt.millisecondsSinceEpoch}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: AppTheme.errorColor,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: AppConfig.defaultPadding),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (direction) {
                                _deleteEntry(entryIndex);
                              },
                              child: ListTile(
                                leading: entry.photoPath != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.file(
                                          File(entry.photoPath!),
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 48,
                                              height: 48,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.broken_image,
                                                size: 24,
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Icon(
                                          Icons.local_shipping,
                                          color: Colors.grey,
                                        ),
                                      ),
                                title: Text(
                                  entry.toFormattedLine(),
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat('HH:mm').format(entry.capturedAt),
                                  style: AppTheme.bodySmall,
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _showEditDialog(entryIndex, entry),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),

                // Preview section
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ExpansionTile(
                    title: const Text('Preview Message'),
                    leading: const Icon(Icons.preview),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppConfig.defaultPadding),
                        margin: const EdgeInsets.all(AppConfig.smallPadding),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(AppConfig.defaultBorderRadius),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          session.toFormattedText(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppConfig.defaultPadding,
                          right: AppConfig.defaultPadding,
                          bottom: AppConfig.defaultPadding,
                        ),
                        child: OutlinedButton.icon(
                          onPressed: _copyToClipboard,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy to Clipboard'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: AppConfig.defaultPadding),
                  Text(
                    'No modules captured yet',
                    style: AppTheme.headingSmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppConfig.smallPadding),
                  Text(
                    'Go back to capture modules',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: AppConfig.largePadding),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Start Capturing'),
                  ),
                ],
              ),
            ),
      floatingActionButton: session.hasEntries
          ? FloatingActionButton.extended(
              onPressed: _isSending ? null : _showSendDialog,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSending ? 'Sending...' : 'Send'),
            )
          : null,
    );
  }
}
