import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

class ReportBlockDialog extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final VoidCallback onUserBlocked;

  const ReportBlockDialog({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    required this.onUserBlocked,
  });

  @override
  State<ReportBlockDialog> createState() => _ReportBlockDialogState();
}

class _ReportBlockDialogState extends State<ReportBlockDialog> {
  String _selectedReason = 'Inappropriate Content';
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Inappropriate Content',
    'Harassment or Bullying',
    'Fake Profile / Catfish',
    'Spam or Scam',
    'Underage User',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReportAndBlock({required bool alsoReport}) async {
    setState(() => _isSubmitting = true);
    HapticFeedback.heavyImpact();

    if (alsoReport) {
      await SupabaseService.instance.reportUser(
        reportedId: widget.targetUserId,
        reason: _selectedReason,
        details: _detailsController.text.trim(),
      );
    }

    await SupabaseService.instance.blockUser(widget.targetUserId);
    await StorageService.instance.blockUser(widget.targetUserId);

    if (mounted) {
      Navigator.pop(context);
      widget.onUserBlocked();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          const Icon(Icons.report_gmailerrorred, color: AppTheme.sparkCoral),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Report or Block ${widget.targetUserName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a reason for reporting this account. Blocked users cannot see your profile or message you.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ..._reasons.map((r) {
              final selected = _selectedReason == r;
              return GestureDetector(
                onTap: () => setState(() => _selectedReason = r),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppTheme.sparkCoral : Colors.white10,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        r,
                        style: TextStyle(
                          color: selected ? Colors.white : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.sparkCoral,
                          size: 16,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Optional details for our moderation team...',
                hintStyle: const TextStyle(color: AppTheme.textDim, fontSize: 12),
                filled: true,
                fillColor: AppTheme.bgCard,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppTheme.textDim),
          ),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white24),
          ),
          onPressed: _isSubmitting
              ? null
              : () => _submitReportAndBlock(alsoReport: false),
          child: const Text(
            'Block Only',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.sparkCoral),
          onPressed: _isSubmitting
              ? null
              : () => _submitReportAndBlock(alsoReport: true),
          child: const Text(
            'Report & Block',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class DeleteAccountDialog extends StatefulWidget {
  final VoidCallback onAccountDeleted;

  const DeleteAccountDialog({super.key, required this.onAccountDeleted});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  bool _confirmed = false;
  bool _isDeleting = false;

  Future<void> _executeDeletion() async {
    setState(() => _isDeleting = true);
    HapticFeedback.heavyImpact();
    await SupabaseService.instance.deleteUserAccount();
    await StorageService.instance.clearAllData();
    if (mounted) {
      Navigator.pop(context);
      widget.onAccountDeleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Row(
        children: [
          Icon(Icons.delete_forever, color: AppTheme.sparkCoral),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Delete Account & Data',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'In compliance with Google Play & App Store Data Safety policies, this action permanently deletes your profile, photos, swipes, matches, Embers, and chat history from Supabase and this device.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _confirmed,
            activeColor: AppTheme.sparkCoral,
            onChanged: (val) => setState(() => _confirmed = val ?? false),
            title: const Text(
              'I understand this action is permanent and cannot be undone.',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppTheme.textDim),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.sparkCoral,
            disabledBackgroundColor: Colors.white12,
          ),
          onPressed: (_confirmed && !_isDeleting) ? _executeDeletion : null,
          child: Text(
            _isDeleting ? 'Wiping Data...' : 'Delete Permanently',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Phase 6: In-App Privacy Policy, Terms of Service & UGC Safety Guidelines
class LegalCenterDialog extends StatefulWidget {
  final int initialTab;
  const LegalCenterDialog({super.key, this.initialTab = 0});

  @override
  State<LegalCenterDialog> createState() => _LegalCenterDialogState();
}

class _LegalCenterDialogState extends State<LegalCenterDialog> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ['Privacy Policy', 'Terms of Use', 'UGC Safety'];
    return Dialog(
      backgroundColor: AppTheme.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppTheme.neonCyan, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.policy, color: AppTheme.neonCyan, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Legal & Trust Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(tabs.length, (i) {
                final active = _selectedTab == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTab = i);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.electricViolet : AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active ? AppTheme.neonCyan : Colors.white12,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tabs[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: active ? FontWeight.bold : FontWeight.normal,
                          color: active ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    _tabBody(_selectedTab),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Acknowledge & Close',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _tabBody(int index) {
    if (index == 0) {
      return 'SPARKQUEST PRIVACY POLICY (2026)\n\n'
          '1. Data Collection & Purpose: We collect your profile name, age, bio, uploaded photos/voice notes (stored in encrypted Supabase Storage buckets), and approximate check-in coordinates to power Radar discovery and Co-Op Quests.\n\n'
          '2. Comfort Blur & Liveness Privacy: Video calls start with Comfort Blur enabled by default. Liveness verification selfies are used solely for anti-catfish badge verification.\n\n'
          '3. Right to Erasure (Account Deletion): You may permanently erase your account and all cloud records (profiles, matches, messages, stories, swipes, check-ins) at any time via Profile → Delete Account & Data (`delete_user_account` RPC).';
    } else if (index == 1) {
      return 'TERMS OF SERVICE & ELIGIBILITY\n\n'
          '1. Age Requirement: You must be at least 18 years old to create a SparkQuest account.\n\n'
          '2. Virtual Items (Embers & Spark Pass): Embers, Spotlight Boosts, and Spark Pass tiers are digital items licensed for in-app use via Google Play Billing.\n\n'
          '3. Real-World Meetups: Always use Date Shield 2.0 Guardian tools, verify your match, and meet in public Safe Haven partner venues.';
    } else {
      return 'USER-GENERATED CONTENT (UGC) & SAFETY RULES\n\n'
          '1. Zero Tolerance Policy: SparkQuest enforces zero tolerance for harassment, hate speech, non-consensual content, impersonation, or spam.\n\n'
          '2. 1-Tap Reporting & Blocking: Every profile card and chat thread includes a Report & Block icon. Blocking immediately removes the user from your feed and chat list and logs a moderation record in `public.blocks` and `public.reports`.\n\n'
          '3. 24-Hour Moderation SLA: Flagged content is reviewed and removed within 24 hours.';
    }
  }
}


