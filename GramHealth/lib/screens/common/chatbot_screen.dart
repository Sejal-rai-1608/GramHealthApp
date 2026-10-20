import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_language.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_icon_button.dart';
import '../../widgets/offline_status_indicator.dart';
import '../../widgets/offline_setup_card.dart';
import '../../models/local_model_status.dart';
import '../../services/connectivity_service.dart';
import '../../services/ai_service.dart';
import '../../services/offline_ai_service.dart';

class Message {
  final String id;
  final String text;
  final String sender;
  final DateTime timestamp;
  final bool isOffline;
  Message({required this.id, required this.text, required this.sender, required this.timestamp, this.isOffline = false});
}

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final List<Message> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  StreamSubscription<LocalModelStatus>? _modelSub;
  StreamSubscription<NetworkStatus>? _connSub;
  bool _showSetupCard = true;
  bool _sending = false;

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
    if (_messages.isEmpty) {
      _messages.add(Message(
        id: '1',
        text: "${context.tr('greeting')} ${context.tr('dihati_assistant')}. ${context.tr('ask_health')}",
        sender: 'ai',
        timestamp: DateTime.now(),
      ));
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

  Future<void> _handleSend() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _messages.add(Message(id: DateTime.now().millisecondsSinceEpoch.toString(), text: text, sender: 'user', timestamp: DateTime.now()));
      _inputCtrl.clear();
    });
    _scrollToBottom();
    try {
      final r = await AiService.query(text);
      if (!mounted) return;
      String out = r.answer ?? "I'm sorry, I couldn't understand that.";
      if (r.urgency == 'emergency') {
        out = "🚨 EMERGENCY 🚨\n$out";
      } else if (r.requiresProfessionalReview == true) {
        out = "⚠️ Please consult a professional.\n$out";
      }
      final isOffline = (r.agent == 'offline_ai_router') || (r.routingMethod?.contains('offline') ?? false);
      setState(() {
        _messages.add(Message(id: DateTime.now().millisecondsSinceEpoch.toString(), text: out, sender: 'ai', timestamp: DateTime.now(), isOffline: isOffline));
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(Message(id: DateTime.now().millisecondsSinceEpoch.toString(), text: "Sorry, I encountered an error: $e", sender: 'ai', timestamp: DateTime.now()));
        _sending = false;
      });
      _scrollToBottom();
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
                final isUser = m.sender == 'user';
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
                                Text(m.text, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: isUser ? Colors.white : AppColors.ink, height: 1.45)),
                                const SizedBox(height: 6),
                                Text("${m.timestamp.hour.toString().padLeft(2, '0')}:${m.timestamp.minute.toString().padLeft(2, '0')}",
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
