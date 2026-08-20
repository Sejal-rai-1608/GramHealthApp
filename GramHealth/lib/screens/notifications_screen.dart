import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final String time;
  final String date;
  final String doctor;
  bool read;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.date,
    required this.doctor,
    required this.read,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      type: 'reminder',
      title: 'Upcoming Appointment',
      message: "Don't forget your consultation with Dr. Anita Joshi.",
      time: '10:30 AM',
      date: 'Today',
      doctor: 'Dr. Anita Joshi',
      read: false,
    ),
    NotificationItem(
      id: '2',
      type: 'alert',
      title: 'Urgent Request Accepted',
      message: 'Dr. Vikram Singh has accepted your urgent booking request.',
      time: '09:15 AM',
      date: 'Today',
      doctor: 'Dr. Vikram Singh',
      read: true,
    ),
    NotificationItem(
      id: '3',
      type: 'reminder',
      title: 'Follow-up Scheduled',
      message: 'You have a follow-up meeting scheduled for next Monday.',
      time: '02:00 PM',
      date: 'Oct 15',
      doctor: 'Dr. Rajesh Kumar',
      read: true,
    ),
  ];

  void _markAllRead() {
    setState(() {
      for (var n in _notifications) {
        n.read = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryBg,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondaryBg,
                    ),
                    child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textDark),
                  ),
                ),
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                GestureDetector(
                  onTap: _markAllRead,
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryAccent),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _notifications.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 60, color: Color(0xFFCCCCCC)),
                        SizedBox(height: 16),
                        Text('No new notifications', style: TextStyle(color: Color(0xFF999999), fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 300 + index * 100),
                        curve: Curves.easeOut,
                        builder: (context, val, child) {
                          return Opacity(
                            opacity: val,
                            child: Transform.translate(
                              offset: Offset(30 * (1 - val), 0),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            borderColor: !item.read ? AppColors.primaryAccent.withValues(alpha: 0.5) : null,
                            backgroundColor: !item.read ? AppColors.primaryAccent.withValues(alpha: 0.08) : null,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: item.type == 'reminder'
                                            ? AppColors.primaryAccent.withValues(alpha: 0.2)
                                            : const Color(0xFFFF4D4D).withValues(alpha: 0.1),
                                      ),
                                      child: Icon(
                                        item.type == 'reminder' ? Icons.calendar_today_outlined : Icons.bolt,
                                        size: 18,
                                        color: item.type == 'reminder' ? AppColors.textDark : const Color(0xFFFF4D4D),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(
                                                fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                                          ),
                                          Text(
                                            '${item.date} • ${item.time}',
                                            style: TextStyle(
                                                fontSize: 11, color: AppColors.textDark.withValues(alpha: 0.5)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!item.read)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primaryAccent,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.message,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.4),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.person_outline, size: 12, color: Color(0xFF666666)),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.doctor,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
