import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../l10n/app_language.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_icon_button.dart';
import '../../widgets/chat_history_sheet.dart';
import '../../widgets/offline_status_indicator.dart';
import '../../widgets/offline_setup_card.dart';
import '../../models/chat_message.dart';
import '../../models/local_model_status.dart';
import '../../services/chat_history_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/ai_service.dart';
import '../../services/offline_ai_service.dart';

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
  bool _sending = false;
  bool _historyStarted = false;
  String _conversationId = '';
  String _greetingText = '';

  @override
  void initState() {
    super.initState();
    unawaited(OfflineAiService.instance.ensureModelLoaded());
    _modelSub = OfflineAiService.instance.statusStream.listen((_) { if (mounted) setState(() {}); });
    _connSub = ConnectivityService.instance.statusStream.listen((_) { if (mounted) setState(() {}); });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_greetingText.isEmpty) {
      _greetingText = "${context.tr('greeting')} ${context.tr('dihati_assistant')}. ${context.tr('ask_health')}";
    }
    if (!_historyStarted) {
      _historyStarted = true;
      unawaited(_loadHistory());
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

  /// Restores the persisted transcript so the conversation survives navigating
  /// away from this screen and restarting the app.
  Future<void> _loadHistory() async {
    try {
      final service = ChatHistoryService.instance;
      _conversationId = await service.activeConversationId();
      final stored = await service.loadMessages(_conversationId);

      if (!mounted) return;

      if (stored.isNotEmpty) {
        setState(() {
          _messages
            ..clear()
            ..addAll(stored);
        });
        _scrollToBottom();
        return;
      }

      final greeting = ChatMessage(
        id: const Uuid().v4(),
        conversationId: _conversationId,
        role: ChatRole.assistant,
        content: _greetingText,
        createdAt: DateTime.now(),
      );
      setState(() => _messages.add(greeting));
      await _persist(greeting);
    } catch (e) {
      print('[ChatHistory] Failed to load history: $e');
    }
  }

  Future<void> _persist(ChatMessage message) async {
    try {
      await ChatHistoryService.instance.saveMessage(message);
    } catch (e) {
      print('[ChatHistory] Failed to persist message: $e');
    }
  }

  String get _statusSubtitle {
    final isOnline = ConnectivityService.instance.currentStatus != NetworkStatus.offline;
    if (isOnline) return 'AI • Online';
    final svc = OfflineAiService.instance;
    final s = svc.modelStatus;
    switch (s) {
      case LocalModelStatus.downloading: return 'Offline • Downloading ${(svc.downloadProgress * 100).toInt()}%';
      case LocalModelStatus.verifying: return 'Offline • Verifying';
      case LocalModelStatus.lexiconOnly: return 'Offline • Knowledge mode';
      case LocalModelStatus.ready: return 'Offline • Ready';
      case LocalModelStatus.loading: return 'Offline • Starting';
      case LocalModelStatus.generating: return 'Offline • Thinking';
      case LocalModelStatus.checking: return 'Offline • Checking';
      case LocalModelStatus.pending: return 'Offline • Waiting for Wi‑Fi';
      case LocalModelStatus.error: return 'Offline • Retry pending';
      default: return 'AI • Offline';
    }
  }

  Color get _statusColor => ConnectivityService.instance.currentStatus != NetworkStatus.offline ? AppColors.onlineGreen : AppColors.offlineOrange;

  /// Display decorations are applied at render time only. The stored content
  /// stays raw, so a transcript reloaded from the database renders exactly
  /// like the original instead of repeating the banners.
  String _displayText(ChatMessage m) {
    if (m.isUser) return m.content;
    if (m.urgency == 'emergency') {
      return "🚨 EMERGENCY 🚨\n${m.content}";
    }
    if (m.requiresProfessionalReview) {
      return "⚠️ Please consult a professional.\n${m.content}";
    }
    return m.content;
  }

  Future<void> _handleSend() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    final service = ChatHistoryService.instance;
    if (_conversationId.isEmpty) {
      _conversationId = await service.activeConversationId();
    }

    // Snapshot the previous turns before the new question is stored so the
    // backend receives the earlier conversation plus this question exactly
    // once.
    List<Map<String, dynamic>> history = const <Map<String, dynamic>>[];
    try {
      final previous = await service.contextMessages(_conversationId);
      history = previous.map((m) => m.toContextJson()).toList();
    } catch (e) {
      print('[ChatHistory] Failed to build context window: $e');
    }

    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      conversationId: _conversationId,
      role: ChatRole.user,
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _sending = true;
      _messages.add(userMessage);
      _inputCtrl.clear();
    });
    _scrollToBottom();
    unawaited(_persist(userMessage));

    try {
      final r = await AiService.query(text, history: history);
      if (!mounted) return;
      final isOffline = (r.agent == 'offline_ai_router') || (r.routingMethod?.contains('offline') ?? false);
      final aiMessage = ChatMessage(
        id: const Uuid().v4(),
        conversationId: _conversationId,
        role: ChatRole.assistant,
        content: r.answer ?? "I'm sorry, I couldn't understand that.",
        createdAt: DateTime.now(),
        isOffline: isOffline,
        urgency: r.urgency,
        intent: r.intent,
        routingMethod: r.routingMethod,
        requiresProfessionalReview: r.requiresProfessionalReview == true,
      );
      setState(() {
        _messages.add(aiMessage);
        _sending = false;
      });
      _scrollToBottom();
      unawaited(_persist(aiMessage));
    } catch (e) {
      if (!mounted) return;
      final errorMessage = ChatMessage(
        id: const Uuid().v4(),
        conversationId: _conversationId,
        role: ChatRole.assistant,
        content: "Sorry, I encountered an error: $e",
        createdAt: DateTime.now(),
        requiresProfessionalReview: true,
      );
      setState(() {
        _messages.add(errorMessage);
        _sending = false;
      });
      _scrollToBottom();
      unawaited(_persist(errorMessage));
    }
  }

  /// Starts an empty conversation. The previous transcript is kept on the
  /// device and stays reachable from the chat history sheet.
  Future<void> _startNewChat() async {
    try {
      final newId = await ChatHistoryService.instance.startNewConversation();
      if (!mounted) return;

      final greeting = ChatMessage(
        id: const Uuid().v4(),
        conversationId: newId,
        role: ChatRole.assistant,
        content: _greetingText,
        createdAt: DateTime.now(),
      );

      setState(() {
        _conversationId = newId;
        _messages
          ..clear()
          ..add(greeting);
      });
      _scrollToBottom();
      await _persist(greeting);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('new_chat_started')),
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('[ChatHistory] Failed to start new chat: $e');
    }
  }

  /// Opens the stored conversation list.
  void _openHistorySheet() {
    showChatHistorySheet(
      context,
      activeConversationId: _conversationId,
      onSelected: (id) => id.isEmpty ? _startNewChat() : _openConversation(id),
    );
  }

  /// Re-opens a previously stored conversation.
  Future<void> _openConversation(String conversationId) async {
    try {
      final messages =
          await ChatHistoryService.instance.openConversation(conversationId);
      if (!mounted) return;
      setState(() {
        _conversationId = conversationId;
        _messages
          ..clear()
          ..addAll(messages);
      });
      _scrollToBottom();
    } catch (e) {
      print('[ChatHistory] Failed to open conversation: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: AppMotion.route, curve: AppMotion.standard);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: CareIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => context.pop(),
            tooltip: 'Back',
            iconSize: 18,
            size: 44,
          ),
        ),
        leadingWidth: 56,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.smart_toy_outlined, size: 16, color: AppColors.teal),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('dihati_assistant'), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(_statusSubtitle, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CareIconButton(
            icon: Icons.history_rounded,
            onTap: _openHistorySheet,
            tooltip: context.tr('chat_history'),
            iconSize: 18,
            size: 44,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OfflineStatusIndicator(isOnline: ConnectivityService.instance.currentStatus != NetworkStatus.offline),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSetupCard &&
              ConnectivityService.instance.currentStatus == NetworkStatus.offline &&
              ![LocalModelStatus.ready, LocalModelStatus.loaded, LocalModelStatus.generating, LocalModelStatus.lexiconOnly]
                  .contains(OfflineAiService.instance.modelStatus))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: OfflineSetupCard(onDismiss: () => setState(() => _showSetupCard = false)),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isUser = m.isUser;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                          Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(right: 8, top: 2),
                            decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                            child: const Icon(Icons.smart_toy_rounded, size: 14, color: Colors.white),
                          ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 11, 14, 8),
                            decoration: BoxDecoration(
                              color: isUser ? AppColors.ink : AppColors.surface,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isUser ? 16 : 4),
                                bottomRight: Radius.circular(isUser ? 4 : 16),
                              ),
                              border: Border.all(color: isUser ? AppColors.ink : AppColors.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (!isUser)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: m.isOffline ? AppColors.offlineWash : AppColors.onlineWash,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(m.isOffline ? 'Offline' : 'Online',
                                        style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w700, color: m.isOffline ? AppColors.offlineOrange : AppColors.onlineGreen)),
                                  ),
                                Text(_displayText(m), style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: isUser ? Colors.white : AppColors.ink, height: 1.45)),
                                const SizedBox(height: 6),
                                Text("${m.createdAt.hour.toString().padLeft(2, '0')}:${m.createdAt.minute.toString().padLeft(2, '0')}",
                                    style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w500, color: isUser ? Colors.white70 : AppColors.inkFaint)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Input — opaque, focused border
          Container(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 12 + MediaQuery.of(context).padding.bottom * 0.3),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    maxLines: 4,
                    minLines: 1,
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: context.tr('ask_health'),
                      hintStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.inkFaint),
                      filled: true,
                      fillColor: AppColors.groundAlt,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.lg), borderSide: const BorderSide(color: AppColors.borderLight)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.lg), borderSide: const BorderSide(color: AppColors.borderLight)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.lg), borderSide: const BorderSide(color: AppColors.tealDeep, width: 1.5)),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 10),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _inputCtrl,
                  builder: (_, v, __) {
                    final hasText = v.text.trim().isNotEmpty;
                    return GestureDetector(
                      onTap: hasText && !_sending ? _handleSend : null,
                      child: AnimatedContainer(
                        duration: AppMotion.state,
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: hasText ? AppColors.teal : AppColors.borderLight,
                          shape: BoxShape.circle,
                        ),
                        child: _sending
                            ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
