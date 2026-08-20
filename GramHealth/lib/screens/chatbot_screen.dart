import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class Message {
  final String id;
  final String text;
  final String sender; // 'user' or 'ai'
  final DateTime timestamp;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_messages.isEmpty) {
      _messages.add(
        Message(
          id: '1',
          text: "${context.tr('greeting')} ${context.tr('dihati_assistant')}. ${context.tr('ask_health')}",
          sender: 'ai',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    final userMsg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: 'user',
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _inputCtrl.clear();
    });

    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      final aiMsg = Message(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: _getAIResponse(text),
        sender: 'ai',
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(aiMsg);
      });
      _scrollToBottom();
    });
  }

  String _getAIResponse(String input) {
    final low = input.toLowerCase();
    if (low.contains('fever') || low.contains('bukhar') || low.contains('taap') || low.contains('taav')) {
      return "I see you're mentioning fever. Would you like to use our Symptom Checker or connect with Dr. Anita Joshi (General Physician)?";
    }
    if (low.contains('appointment') || low.contains('booking') || low.contains('doctor')) {
      return "You can book an appointment by going to the 'Consult Doctor' section on the Home screen or selecting a doctor from the carousel.";
    }
    if (low.contains('hello') || low.contains('hi') || low.contains('namaste') || low.contains('namaskar')) {
      return "Hello! I can help you find doctors, check symptoms, or manage your health records. What's on your mind?";
    }
    return "I'm still learning, but I can help you navigate RuralCare. You can ask about doctors, symptoms, or how to see your records!";
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
                        context.tr('online_assistant'),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

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
                        final hasText = value.text.trim().isNotEmpty;
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
