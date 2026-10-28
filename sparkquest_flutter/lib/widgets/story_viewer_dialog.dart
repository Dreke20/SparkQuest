import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class StoryViewerDialog extends StatefulWidget {
  final String matchName;
  final String photoAsset;
  final List<String> tags;
  final Function(String replyText) onReplySent;

  const StoryViewerDialog({
    super.key,
    required this.matchName,
    required this.photoAsset,
    required this.tags,
    required this.onReplySent,
  });

  @override
  State<StoryViewerDialog> createState() => _StoryViewerDialogState();
}

class _StoryViewerDialogState extends State<StoryViewerDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  final TextEditingController _replyController = TextEditingController();

  String get _storyCaption {
    switch (widget.matchName.toLowerCase()) {
      case 'sophia':
        return 'Golden hour hike above the clouds 🏔️✨ Who’s joining next Sunday?';
      case 'jordan':
        return 'Spinning rare vinyls at the studio tonight 🎵☕ Matcha on deck!';
      case 'maya':
        return 'Post-yoga smoothie bowl & ocean breeze 🧘‍♀️🌊';
      default:
        return 'Out exploring hidden gems in the city ✨🔥';
    }
  }

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          Navigator.pop(context);
        }
      });
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _sendReaction(String reaction) {
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    widget.onReplySent('Reacted $reaction to your story: "$_storyCaption"');
  }

  void _sendTextReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    widget.onReplySent('💬 [Story Reply] $text');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Story Fullscreen Image
          Image.asset(
            widget.photoAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: AppTheme.bgDeep),
          ),

          // Gradient Overlays
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Top Progress Bar & User Info
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.neonCyan,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage(widget.photoAsset),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.matchName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified,
                                  color: AppTheme.neonCyan,
                                  size: 16,
                                ),
                              ],
                            ),
                            const Text(
                              '2h ago • Spark Moment',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Caption, Reactions & Reply Input
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: widget.tags
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.bgSurface.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.neonCyan.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      _storyCaption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Quick Reactions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['🔥', '😍', '⚡', '☕', '🙌']
                        .map(
                          (emoji) => GestureDetector(
                            onTap: () => _sendReaction(emoji),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.bgSurface.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          onTap: () => _progressController.stop(),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Reply to ${widget.matchName}\'s story...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: AppTheme.bgSurface.withValues(alpha: 0.9),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                          ),
                          onSubmitted: (_) => _sendTextReply(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppTheme.sparkCoral,
                        child: IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: _sendTextReply,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

