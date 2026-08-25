import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_colors.dart';
import '../providers/opportunity_provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/security_service.dart';
import '../widgets/header_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  int _defaultSnooze = 60;
  final _importController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final notifs = await StorageService.getNotificationsEnabled();
    final snooze = await StorageService.getDefaultSnoozeMinutes();
    setState(() {
      _notificationsEnabled = notifs;
      _defaultSnooze = snooze;
    });
  }

  void _showSetPinDialog(BuildContext context, {bool isChange = false}) {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.pin_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                isChange ? 'Change 4-Digit PIN' : 'Set 4-Digit Screen PIN',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a 4-digit numeric PIN to protect your reminders and opportunities:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Enter 4-Digit PIN',
                  hintText: '••••',
                  counterText: '',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm 4-Digit PIN',
                  hintText: '••••',
                  counterText: '',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 8),
                Text(
                  dialogError!,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final pin = pinController.text.trim();
                final confirm = confirmController.text.trim();

                if (pin.length != 4 || int.tryParse(pin) == null) {
                  setDialogState(() => dialogError = 'PIN must be exactly 4 numeric digits.');
                  return;
                }

                if (pin != confirm) {
                  setDialogState(() => dialogError = 'PINs do not match. Please re-enter.');
                  return;
                }

                final security = context.read<SecurityService>();
                final success = await security.setPin(pin);
                if (success && ctx.mounted) {
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text('4-Digit Screen PIN saved and enabled! ✓', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        backgroundColor: Color(0xFF15803D),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OpportunityProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const MarakadheyHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'App Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Customize your reminder defaults, alarms, and data backup.',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 16),

                      // User Account Profile Card
                      Consumer<AuthService>(
                        builder: (context, auth, _) {
                          final user = auth.currentUser;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: AppColors.primaryLight,
                                  child: Icon(Icons.person, color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            user?.displayName ?? 'Account',
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.secondary),
                                          ),
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: () {
                                              final nameController = TextEditingController(text: user?.displayName ?? '');
                                              showDialog(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                  title: const Text('Edit Display Name', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                                  content: TextField(
                                                    controller: nameController,
                                                    autofocus: true,
                                                    decoration: InputDecoration(
                                                      labelText: 'Your Name',
                                                      hintText: 'e.g. Mom, Anitha, Alex',
                                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                                      onPressed: () async {
                                                        final newName = nameController.text.trim();
                                                        if (newName.isNotEmpty) {
                                                          await auth.updateDisplayName(newName);
                                                          if (ctx.mounted) Navigator.pop(ctx);
                                                        }
                                                      },
                                                      child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            child: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        user?.email ?? 'Signed In',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => auth.logout(),
                                  child: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Screen PIN Lock Section
                      _buildSectionHeader('Screen PIN Security'),
                      Consumer<SecurityService>(
                        builder: (context, security, _) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  secondary: const Icon(Icons.pin_rounded, color: AppColors.primary, size: 26),
                                  title: const Text('App Screen PIN Lock', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                  subtitle: Text(
                                    security.isPinEnabled
                                        ? 'Protected with 4-digit PIN (App locks when closed or backgrounded)'
                                        : 'Set a 4-digit PIN to lock and protect your reminders',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                  value: security.isPinEnabled,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: (val) async {
                                    if (val) {
                                      _showSetPinDialog(context);
                                    } else {
                                      await security.disablePin();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Screen PIN Lock disabled.'),
                                            backgroundColor: Color(0xFF64748B),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                if (security.isPinEnabled) ...[
                                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                  ListTile(
                                    leading: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                                    title: const Text('Change 4-Digit PIN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    subtitle: const Text('Update your current screen PIN', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                                    onTap: () => _showSetPinDialog(context, isChange: true),
                                  ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Notifications Section
                        _buildSectionHeader('Notifications & Alarms'),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: const Text('Push Notifications & Alarms', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                subtitle: const Text('Ring device alarm when opportunities reach deadline', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                value: _notificationsEnabled,
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) async {
                                  setState(() => _notificationsEnabled = val);
                                  await StorageService.setNotificationsEnabled(val);
                                  if (val) {
                                    await NotificationService.requestPermissions();
                                  }
                                },
                              ),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              ListTile(
                                leading: const Icon(Icons.battery_charging_full_rounded, color: Color(0xFF0284C7), size: 20),
                                title: const Text('Phone Permissions & Battery Optimization', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                subtitle: const Text('Allow background alarms & uncheck battery restrictions', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF0284C7)),
                                onTap: () => openAppSettings(),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Default Preferences Section
                      _buildSectionHeader('Preferences'),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Default Snooze Duration', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.surfaceBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _defaultSnooze,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: 15, child: Text('15 Minutes')),
                                    DropdownMenuItem(value: 30, child: Text('30 Minutes')),
                                    DropdownMenuItem(value: 60, child: Text('1 Hour (Default)')),
                                    DropdownMenuItem(value: 180, child: Text('3 Hours')),
                                    DropdownMenuItem(value: 1440, child: Text('1 Day (Tomorrow)')),
                                  ],
                                  onChanged: (v) async {
                                    if (v != null) {
                                      setState(() => _defaultSnooze = v);
                                      await StorageService.setDefaultSnoozeMinutes(v);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Extension Workflow Automation Preferences (Matching Chrome Extension)
                      // 1. Mark reminder completed after opening
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.surfaceBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CheckboxListTile(
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text(
                            'Mark reminder completed after opening',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                          ),
                          subtitle: const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Automatically mark reminders as completed when clicking "Open Link" from either the Inbox or notification.',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.35),
                            ),
                          ),
                          value: provider.markCompletedOnOpen,
                          onChanged: (val) async {
                            if (val != null) {
                              await provider.setMarkCompletedOnOpen(val);
                            }
                          },
                        ),
                      ),

                      // 2. Hide completed reminders from Inbox
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.surfaceBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CheckboxListTile(
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text(
                            'Hide completed reminders from Inbox',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                          ),
                          subtitle: const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Hide completed reminders from the Inbox list while keeping them stored.',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.35),
                            ),
                          ),
                          value: provider.hideCompletedFromInbox,
                          onChanged: (val) async {
                            if (val != null) {
                              await provider.setHideCompletedFromInbox(val);
                            }
                          },
                        ),
                      ),

                      // 3. Auto-delete completed reminders older than 90 days
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.surfaceBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CheckboxListTile(
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text(
                            'Auto-delete completed reminders older than 90 days',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                          ),
                          subtitle: const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Keep your workspace clean. Automatically delete completed reminders 90 days after they are completed.',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.35),
                            ),
                          ),
                          value: provider.autoDelete90Days,
                          onChanged: (val) async {
                            if (val != null) {
                              await provider.setAutoDelete90Days(val);
                            }
                          },
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'Completed reminders remain available under the Completed filter.',
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Backup & Restore Section
                      _buildSectionHeader('Backup & Data Transfer'),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.file_download_outlined, color: AppColors.primary),
                              title: const Text('Export JSON Backup', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              subtitle: const Text('Export all saved deadlines and notes to a file or share', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              onTap: () async {
                                final auth = context.read<AuthService>();
                                final jsonStr = await StorageService.exportBackup(userId: auth.currentUser?.uid);
                                if (!context.mounted) return;

                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: Row(
                                      children: [
                                        const Icon(Icons.file_download_outlined, color: AppColors.primary, size: 22),
                                        const SizedBox(width: 8),
                                        Text('Export Backup (${provider.totalCount} Items)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Export your ${provider.totalCount} saved opportunities and notes as a portable JSON backup.',
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Text(
                                            'Format: JSON\nUser: ${auth.currentUser?.displayName ?? 'Local'}\nCount: ${provider.totalCount} reminders',
                                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF334155)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.copy_rounded, size: 16),
                                        label: const Text('Copy JSON'),
                                        onPressed: () async {
                                          await Clipboard.setData(ClipboardData(text: jsonStr));
                                          if (ctx.mounted) Navigator.pop(ctx);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Backup JSON copied to clipboard! ✓')),
                                            );
                                          }
                                        },
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
                                        label: const Text('Share Backup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        onPressed: () async {
                                          if (ctx.mounted) Navigator.pop(ctx);
                                          await Share.share(jsonStr, subject: 'Marakadhey Backup JSON');
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1, color: AppColors.surfaceBorder),
                            ListTile(
                              leading: const Icon(Icons.file_upload_outlined, color: AppColors.primary),
                              title: const Text('Import Backup JSON', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              subtitle: const Text('Restore previously exported deadlines and checklists', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: const Row(
                                      children: [
                                        Icon(Icons.file_upload_outlined, color: AppColors.primary, size: 22),
                                        SizedBox(width: 8),
                                        Text('Import Backup JSON', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: _importController,
                                          maxLines: 6,
                                          decoration: InputDecoration(
                                            hintText: 'Paste backup JSON here...',
                                            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            contentPadding: const EdgeInsets.all(12),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            icon: const Icon(Icons.paste_rounded, size: 14),
                                            label: const Text('Paste from Clipboard', style: TextStyle(fontSize: 11)),
                                            onPressed: () async {
                                              final data = await Clipboard.getData(Clipboard.kTextPlain);
                                              if (data?.text != null) {
                                                _importController.text = data!.text!;
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          _importController.clear();
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () async {
                                          final rawText = _importController.text.trim();
                                          if (rawText.isEmpty) return;
                                          final success = await provider.importData(rawText);
                                          _importController.clear();
                                          if (ctx.mounted) Navigator.pop(ctx);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                                content: Text(success ? 'Opportunities imported successfully! ✓' : 'Invalid or malformed backup JSON.'),
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text('Import Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1, color: AppColors.surfaceBorder),
                            ListTile(
                              leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                              title: const Text('Clear All Opportunities', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.red)),
                              subtitle: const Text('Delete all tracked opportunities permanently', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              onTap: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Clear All Data?'),
                                    content: const Text('Are you sure you want to delete all saved opportunities? This cannot be undone.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Delete All', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await provider.resetAllData();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('All data has been cleared.')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // About Section
                      _buildSectionHeader('About Marakadhey'),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Marakadhey Mobile', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                            SizedBox(height: 4),
                            Text(
                              'Designed for students, job seekers, and developers to never miss critical deadlines, internships, and opportunities.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.secondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
