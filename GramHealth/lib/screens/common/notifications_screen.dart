import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/care_icon_button.dart';
import '../../widgets/empty_state.dart';

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final String time;
  final String date;
  final String doctor;
  bool read;
  NotificationItem({required this.id, required this.type, required this.title, required this.message, required this.time, required this.date, required this.doctor, required this.read});
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(id: '1', type: 'reminder', title: 'Upcoming appointment', message: "Your consultation with Dr. Anita Joshi is scheduled soon.", time: '10:30 AM', date: 'Today', doctor: 'Dr. Anita Joshi', read: false),
    NotificationItem(id: '2', type: 'alert', title: 'Request accepted', message: 'Dr. Vikram Singh has accepted your urgent booking request.', time: '09:15 AM', date: 'Today', doctor: 'Dr. Vikram Singh', read: true),
    NotificationItem(id: '3', type: 'reminder', title: 'Follow-up scheduled', message: 'You have a follow-up meeting scheduled for next Monday.', time: '02:00 PM', date: 'Oct 15', doctor: 'Dr. Rajesh Kumar', read: true),
  ];

  void _markAllRead() => setState(() => _notifications.forEach((n) => n.read = true));

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
        title: Text('Notifications', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal)),
            ),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? const EmptyState(icon: Icons.notifications_off_outlined, title: 'No new notifications', subtitle: 'We will notify you about appointments, prescriptions, and updates here.')
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: _notifications.length,
              itemBuilder: (_, i) {
                final item = _notifications[i];
                final isAlert = item.type == 'alert';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CareCard(
                    borderColor: !item.read ? AppColors.tealPale : AppColors.borderLight,
                    color: !item.read ? AppColors.mintLight : AppColors.surface,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(color: isAlert ? AppColors.emergencyWash : AppColors.mint, borderRadius: BorderRadius.circular(10)),
                              child: Icon(isAlert ? Icons.bolt_rounded : Icons.calendar_today_rounded, size: 16, color: isAlert ? AppColors.emergency : AppColors.teal),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                                  Text('${item.date} • ${item.time}', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.inkMuted)),
                                ],
                              ),
                            ),
                            if (!item.read)
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(item.message, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.inkSoft, height: 1.5)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(color: AppColors.groundAlt, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.inkMuted),
                              const SizedBox(width: 4),
                              Text(item.doctor, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
