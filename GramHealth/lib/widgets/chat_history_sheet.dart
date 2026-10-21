import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_language.dart';
import '../models/chat_conversation.dart';
import '../services/chat_history_service.dart';
import '../theme/app_colors.dart';
import 'care_card.dart';
import 'empty_state.dart';

/// Opens the stored conversation list of the AI assistant.
void showChatHistorySheet(
  BuildContext context, {
  required String activeConversationId,
  required void Function(String conversationId) onSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.ground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    builder: (sheetContext) => ChatHistorySheet(
      activeConversationId: activeConversationId,
      onSelected: (id) {
        Navigator.of(sheetContext).pop();
        onSelected(id);
      },
    ),
  );
}

/// Bottom sheet listing the AI assistant conversations stored on the device.
class ChatHistorySheet extends StatefulWidget {
  final String activeConversationId;
  final void Function(String conversationId) onSelected;

  const ChatHistorySheet({
    super.key,
    required this.activeConversationId,
    required this.onSelected,
  });

  @override
  State<ChatHistorySheet> createState() => _ChatHistorySheetState();
}

class _ChatHistorySheetState extends State<ChatHistorySheet> {
  List<ChatConversation> _conversations = const <ChatConversation>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await ChatHistoryService.instance.listConversations();
      if (!mounted) return;
      setState(() {
        _conversations = items;
        _loading = false;
      });
    } catch (e) {
      print('[ChatHistory] Failed to list conversations: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  static const List<String> _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatStamp(DateTime value) {
    final now = DateTime.now();
    final isToday = value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = value.year == yesterday.year &&
        value.month == yesterday.month &&
        value.day == yesterday.day;

    final time =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

    if (isToday) return 'Today, $time';
    if (isYesterday) return 'Yesterday, $time';
    return '${value.day} ${_months[value.month - 1]}, $time';
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.ground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grab handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('chat_history'),
                    style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.inkMuted,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                ),
              ],
            ),
          ),
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.teal,
                      ),
                    ),
                  )
                : _conversations.isEmpty
                    ? EmptyState(
                        icon: Icons.forum_outlined,
                        title: context.tr('no_chat_history'),
                        subtitle: context.tr('no_chat_history_hint'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                        itemCount: _conversations.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return CareCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              color: AppColors.mint,
                              borderColor: AppColors.tealPale,
                              onTap: () => widget.onSelected(''),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: AppColors.teal,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      context.tr('new_chat'),
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.tealDeep,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final c = _conversations[i - 1];
                          final isActive = c.id == widget.activeConversationId;
                          return CareCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            borderColor:
                                isActive ? AppColors.tealPale : AppColors.borderLight,
                            color: isActive ? AppColors.mintLight : AppColors.surface,
                            onTap: () => widget.onSelected(c.id),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.teal
                                        : AppColors.groundAlt,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 16,
                                    color: isActive
                                        ? Colors.white
                                        : AppColors.inkMuted,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${_formatStamp(c.lastMessageAt)}  •  ${c.messageCount} ${context.tr('messages')}',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.inkFaint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isActive)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 18,
                                    color: AppColors.teal,
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
