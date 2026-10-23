import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/offline_status_indicator.dart';
import '../widgets/offline_setup_card.dart';
import '../models/local_model_status.dart';
import '../models/chat_message.dart';
import '../services/connectivity_service.dart';
import '../services/ai_service.dart';
import '../services/offline_ai_service.dart';
import '../services/chat_history_service.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  StreamSubscription<LocalModelStatus>? _modelSub;
  StreamSubscription<NetworkStatus>? _connSub;
  bool _showSetupCard = true;
  bool _historyLoading = true;
  bool _isSending = false;
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    unawaited(_initialiseOfflineAi());
    unawaited(_loadConversation());

    _connSub = ConnectivityService.instance.statusStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initialiseOfflineAi() async {
    try {
      await OfflineAiService.instance.initialise();
      _modelSub?.cancel();
      _modelSub = OfflineAiService.instance.statusStream.listen((_) {
        if (mounted) setState(() {});
      });
      await OfflineAiService.instance.ensureModelLoaded();
      if (mounted) setState(() {});
    } catch (_) {
      // The lexicon fallback and online route remain usable if the native
      // offline model cannot be initialised on this device.
    }
  }

  ChatMessage _greetingMessage() {
    return ChatMessage(
      id: ChatHistoryService.instance.newMessageId(),
      text: "${context.tr('greeting')} ${context.tr('dihati_assistant')}. ${context.tr('ask_health')}",
      sender: 'ai',
      timestamp: DateTime.now(),
    );
  }

  Future<void> _loadConversation({String? conversationId}) async {
    try {
      final history = ChatHistoryService.instance;
      final conversations = await history.listConversations();
      final selected = conversationId == null
          ? (conversations.isNotEmpty ? conversations.first : await history.createConversation())
          : conversations.firstWhere(
              (conversation) => conversation.id == conversationId,
              orElse: () => throw StateError('Chat conversation not found.'),
            );
      var messages = await history.loadMessages(selected.id);

      if (messages.isEmpty) {
        final greeting = _greetingMessage();
        await history.saveMessage(conversationId: selected.id, message: greeting);
        messages = [greeting];
      }

      if (!mounted) return;
      setState(() {
        _conversationId = selected.id;
        _messages
          ..clear()
          ..addAll(messages);
        _historyLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      // Keep the chat usable even if the local database is temporarily
      // unavailable; authenticated requests still use the normal AI route.
      setState(() {
        _conversationId = null;
        _messages
          ..clear()
          ..add(_greetingMessage());
        _historyLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _modelSub?.cancel();
    _connSub?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String get _statusSubtitle {
    final isOnline = ConnectivityService.instance.currentStatus != NetworkStatus.offline;
    if (isOnline) return 'AI • Online';
    
    final offlineService = OfflineAiService.instance;
    final status = offlineService.modelStatus;
    switch (status) {
      case LocalModelStatus.downloading:
        return 'Offline AI • Downloading ${(offlineService.downloadProgress * 100).toInt()}%';
      case LocalModelStatus.verifying:
        return 'Offline AI • Verifying';
      case LocalModelStatus.verified:
        return 'Offline AI • Verified';
      case LocalModelStatus.compatible:
        return 'Offline AI • Compatible';
      case LocalModelStatus.loadable:
      case LocalModelStatus.ready:
        return 'Offline AI • Ready';
      case LocalModelStatus.loading:
        return 'Offline AI • Starting';
      case LocalModelStatus.generating:
        return 'Offline AI • Thinking';
      case LocalModelStatus.lexiconOnly:
        return 'Offline AI • Knowledge mode';
      case LocalModelStatus.checking:
        return 'Offline AI • Checking';
      case LocalModelStatus.pending:
        return 'Offline AI • Download pending';
      case LocalModelStatus.error:
        return 'Offline AI • Retry pending';
      default:
        return 'AI • Offline';
    }
  }

  Color get _statusColor {
    final isOnline = ConnectivityService.instance.currentStatus != NetworkStatus.offline;
    return isOnline ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);
  }

  Future<void> _handleSend() async {
    if (_historyLoading || _isSending) return;
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    final userMsg = ChatMessage(
      id: ChatHistoryService.instance.newMessageId(),
      text: text,
      sender: 'user',
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _inputCtrl.clear();
      _isSending = true;
    });

    await _persistMessage(userMsg);
    _scrollToBottom();

    try {
      final aiResponse = await AiService.query(text);
      
      if (!mounted) return;
      
      String responseText = aiResponse.answer ?? "I'm sorry, I couldn't understand that.";
      if (aiResponse.urgency == 'emergency') {
        responseText = "🚨 EMERGENCY 🚨\n$responseText";
      } else if (aiResponse.requiresProfessionalReview == true) {
        responseText = "⚠️ Please consult a professional.\n$responseText";
      }

      final bool isOffline = (aiResponse.agent == 'offline_ai_router') ||
          (aiResponse.routingMethod?.contains('offline') ?? false);

       final aiMsg = ChatMessage(
         id: ChatHistoryService.instance.newMessageId(),
         text: responseText,
         sender: 'ai',
         timestamp: DateTime.now(),
        isOffline: isOffline,
      );
      
       setState(() {
         _messages.add(aiMsg);
         _isSending = false;
       });
       await _persistMessage(aiMsg);
       _scrollToBottom();
     } catch (e) {
       if (!mounted) return;
       final errorMsg = ChatMessage(
         id: ChatHistoryService.instance.newMessageId(),
         text: "Sorry, I encountered an error: ${e.toString()}",
         sender: 'ai',
         timestamp: DateTime.now(),
      );
       setState(() {
         _messages.add(errorMsg);
         _isSending = false;
       });
       await _persistMessage(errorMsg);
       _scrollToBottom();
     }
  }

  Future<void> _persistMessage(ChatMessage message) async {
    final conversationId = _conversationId;
    if (conversationId == null) return;
    try {
      await ChatHistoryService.instance.saveMessage(
        conversationId: conversationId,
        message: message,
      );
    } catch (_) {
      // Persistence must not make the clinical request fail. The UI remains
      // usable and the next app launch will retry from the active history.
    }
  }

  Future<void> _startNewConversation() async {
    if (_isSending) return;
    try {
      final conversation = await ChatHistoryService.instance.createConversation();
      final greeting = _greetingMessage();
      await ChatHistoryService.instance.saveMessage(
        conversationId: conversation.id,
        message: greeting,
      );
      if (!mounted) return;
      setState(() {
        _conversationId = conversation.id;
        _messages
          ..clear()
          ..add(greeting);
      });
      _scrollToBottom();
    } catch (_) {
      // Keep the current conversation when a new local history entry cannot
      // be created.
    }
  }

  Future<void> _openHistory() async {
    if (_historyLoading) return;
    try {
      final conversations = await ChatHistoryService.instance.listConversations();
      if (!mounted) return;
      final selectedId = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, color: AppColors.primaryAccent),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Chat history',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'New chat',
                        onPressed: () => Navigator.of(sheetContext).pop('__new__'),
                        icon: const Icon(Icons.add_comment_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (conversations.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No saved chats yet.')),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: conversations.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final conversation = conversations[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE8F5E9),
                              child: Icon(Icons.chat_bubble_outline, color: AppColors.primaryAccent),
                            ),
                            title: Text(
                              conversation.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${conversation.messageCount} messages • ${_formatHistoryDate(conversation.updatedAt)}',
                            ),
                            onTap: () => Navigator.of(sheetContext).pop(conversation.id),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );

      if (selectedId == '__new__') {
        await _startNewConversation();
      } else if (selectedId != null && selectedId != _conversationId) {
        setState(() => _historyLoading = true);
        await _loadConversation(conversationId: selectedId);
      }
    } catch (_) {
      // History remains optional to the live chat request.
    }
  }

  String _formatHistoryDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.chevron_left, size: 24, color: AppColors.textDark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.insights, size: 20, color: AppColors.primaryAccent),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('dihati_assistant'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                      ),
                      Text(
                        _statusSubtitle,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor),
                      ),
                    ],
                  ),
                   const Spacer(),
                   IconButton(
                     tooltip: 'Chat history',
                     onPressed: _openHistory,
                     icon: const Icon(Icons.history, size: 20, color: AppColors.textDark),
                   ),
                   IconButton(
                     tooltip: 'New chat',
                     onPressed: _startNewConversation,
                     icon: const Icon(Icons.add_comment_outlined, size: 20, color: AppColors.textDark),
                   ),
                   OfflineStatusIndicator(
                    isOnline: ConnectivityService.instance.currentStatus != NetworkStatus.offline,
                  ),
                ],
              ),
            ),

            // Optional Offline Setup Banner
            if (_showSetupCard &&
                ConnectivityService.instance.currentStatus == NetworkStatus.offline &&
                OfflineAiService.instance.modelStatus != LocalModelStatus.ready &&
                OfflineAiService.instance.modelStatus != LocalModelStatus.loaded &&
                OfflineAiService.instance.modelStatus != LocalModelStatus.generating &&
                OfflineAiService.instance.modelStatus != LocalModelStatus.lexiconOnly) ...[
              OfflineSetupCard(
                onDismiss: () => setState(() => _showSetupCard = false),
              ),
            ],

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                   final msg = _messages[index];
                  final isUser = msg.sender == 'user';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(right: 8, top: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.memory, size: 14, color: Colors.white),
                          ),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isUser ? AppColors.textDark : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: Radius.circular(isUser ? 20 : 4),
                                bottomRight: Radius.circular(isUser ? 4 : 20),
                              ),
                              boxShadow: const [
                                BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (!isUser) ...[
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: msg.isOffline
                                          ? const Color(0xFFFF9800).withValues(alpha: 0.15)
                                          : const Color(0xFF4CAF50).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      msg.isOffline ? 'AI • Offline' : 'AI • Online',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: msg.isOffline ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ),
                                ],
                                Text(
                                  msg.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isUser ? Colors.white : AppColors.textDark,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isUser ? Colors.white60 : Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Input Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                borderRadius: 24,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        maxLines: 4,
                        minLines: 1,
                        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                        decoration: InputDecoration(
                          hintText: context.tr('ask_health'),
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                         onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _inputCtrl,
                      builder: (context, value, child) {
                         final hasText = value.text.trim().isNotEmpty && !_historyLoading && !_isSending;
                        return GestureDetector(
                          onTap: hasText ? _handleSend : null,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasText ? AppColors.primaryAccent : const Color(0xFFCCCCCC),
                            ),
                            child: const Icon(Icons.send, size: 20, color: Colors.white),
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
