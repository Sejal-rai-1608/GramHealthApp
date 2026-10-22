import 'package:flutter/material.dart';
import '../../widgets/dashboard_layout.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/stat_card.dart';
import '../../services/admin_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  late Future<Map<String, dynamic>> _overviewFuture;
  late Future<List<Map<String, dynamic>>> _consultationTrendsFuture;
  late Future<List<Map<String, dynamic>>> _doctorWorkloadFuture;
  late Future<List<Map<String, dynamic>>> _pharmacyCoverageFuture;
  late Future<List<Map<String, dynamic>>> _userGrowthFuture;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    setState(() {
      _overviewFuture = AdminService.getReportOverview();
      _consultationTrendsFuture = AdminService.getConsultationTrends(days: 30);
      _doctorWorkloadFuture = AdminService.getDoctorWorkload();
      _pharmacyCoverageFuture = AdminService.getPharmacyCoverage();
      _userGrowthFuture = AdminService.getUserGrowth(days: 30);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'System Reports',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reports & Analytics',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Real-time system performance metrics and healthcare analytics',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            
            // Overview Stats
            FutureBuilder<Map<String, dynamic>>(
              future: _overviewFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: List.generate(9, (i) => _buildSkeletonStatCard()),
                  );
                }

                if (snapshot.hasError || snapshot.data == null) {
                  return _buildErrorState('Failed to load overview stats');
                }

                final stats = snapshot.data!;
                final statData = [
                  {'label': 'Total Users', 'value': _formatNumber(stats['totalUsers'] ?? 0), 'icon': Icons.group},
                  {'label': 'Doctors', 'value': _formatNumber(stats['totalDoctors'] ?? 0), 'icon': Icons.medical_services},
                  {'label': 'Patients', 'value': _formatNumber(stats['totalPatients'] ?? 0), 'icon': Icons.people_alt},
                  {'label': 'Pharmacies', 'value': _formatNumber(stats['totalPharmacies'] ?? 0), 'icon': Icons.local_pharmacy},
                  {'label': 'Facilities', 'value': _formatNumber(stats['totalFacilities'] ?? 0), 'icon': Icons.local_hospital},
                  {'label': 'Consultations', 'value': _formatNumber(stats['totalConsultations'] ?? 0), 'icon': Icons.calendar_month},
                  {'label': 'Pending', 'value': _formatNumber(stats['pendingConsultations'] ?? 0), 'icon': Icons.hourglass_empty},
                  {'label': 'Completed', 'value': _formatNumber(stats['completedConsultations'] ?? 0), 'icon': Icons.check_circle},
                  {'label': 'Prescriptions', 'value': _formatNumber(stats['totalPrescriptions'] ?? 0), 'icon': Icons.description},
                ];

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: statData.map((d) => StatCard(
                    icon: d['icon'] as IconData,
                    label: d['label'] as String,
                    value: d['value'] as String,
                  )).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // Consultation Trends
            const Text(
              'Consultation Trends (30 Days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _consultationTrendsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildSkeletonTrendChart();
                  }
                  if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                    return _buildEmptyTrend('No consultation data available');
                  }

                  final trends = snapshot.data!;
                  return _buildTrendChart(trends);
                },
              ),
            ),

            const SizedBox(height: 24),

            // Doctor Workload
            const Text(
              'Doctor Workload',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _doctorWorkloadFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.leafGreenPrimary));
                  }
                  if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                    return _buildEmptyState('No doctor workload data available');
                  }

                  final doctors = snapshot.data!;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: doctors.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final d = doctors[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.leafGreenPale,
                          child: Text(
                            (d['name'] ?? 'D')[0].toUpperCase(),
                            style: const TextStyle(color: AppColors.leafGreenDeep, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(d['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        subtitle: Text('${d['specialization'] ?? "N/A"} | ${d['hospitalName'] ?? "N/A"}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${d['totalConsultations']} consultations', style: const TextStyle(fontSize: 11, color: AppColors.leafGreenDeep, fontWeight: FontWeight.bold)),
                            Text('${d['totalPrescriptions']} prescriptions', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Pharmacy Coverage
            const Text(
              'Pharmacy Medicine Coverage',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _pharmacyCoverageFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.leafGreenPrimary));
                  }
                  if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                    return _buildEmptyState('No pharmacy coverage data available');
                  }

                  final pharmacies = snapshot.data!;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pharmacies.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final p = pharmacies[index];
                      final stockPct = p['stockPercentage'] ?? 0;
                      final color = stockPct >= 80 ? Colors.green : (stockPct >= 50 ? Colors.orange : Colors.red);
                      
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.leafGreenPale,
                          child: const Icon(Icons.local_pharmacy, color: AppColors.leafGreenDeep),
                        ),
                        title: Text(p['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        subtitle: Text('${p['address'] ?? "N/A"} | ${p['inStockCount']}/${p['totalMedicines']} in stock', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$stockPct%',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // User Growth
            const Text(
              'User Growth (30 Days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _userGrowthFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildSkeletonTrendChart();
                  }
                  if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                    return _buildEmptyTrend('No user growth data available');
                  }

                  final growth = snapshot.data!;
                  return _buildGrowthChart(growth);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonStatCard() {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 24, width: 80, decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          Container(height: 32, width: 60, decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }

  Widget _buildSkeletonTrendChart() {
    return Container(
      height: 200,
      child: Center(child: CircularProgressIndicator(color: AppColors.leafGreenPrimary)),
    );
  }

  Widget _buildEmptyTrend(String message) {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(List<Map<String, dynamic>> trends) {
    return Container(
      height: 200,
      child: CustomPaint(
        size: const Size(double.infinity, 200),
        painter: _TrendPainter(trends),
      ),
    );
  }

  Widget _buildGrowthChart(List<Map<String, dynamic>> growth) {
    return Container(
      height: 200,
      child: CustomPaint(
        size: const Size(double.infinity, 200),
        painter: _GrowthPainter(growth),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _TrendPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _TrendPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..color = AppColors.leafGreenPrimary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final points = <Offset>[];
    final maxVal = data.map((d) => d['total'] as int).reduce((a, b) => a > b ? a : b);
    final minVal = data.map((d) => d['total'] as int).reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i]['total'] - minVal) / range) * (size.height - 40) - 20;
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GrowthPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _GrowthPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final colors = {
      'PATIENT': Colors.blue,
      'DOCTOR': Colors.green,
      'PHARMACY': Colors.orange,
      'ASHA': Colors.purple,
      'ADMIN': Colors.red,
    };

    final roles = colors.keys.toList();
    final maxVal = data
        .expand((d) => (d['byRole'] as Map).values)
        .reduce((a, b) => a > b ? a : b);

    for (final role in roles) {
      final paint = Paint()
        ..color = colors[role]!
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final points = <Offset>[];
      for (int i = 0; i < data.length; i++) {
        final val = (data[i]['byRole'] as Map)[role] ?? 0;
        final x = (i / (data.length - 1)) * size.width;
        final y = size.height - (val / maxVal) * (size.height - 40) - 20;
        points.add(Offset(x, y));
      }

      if (points.length > 1) {
        final path = Path();
        path.moveTo(points[0].dx, points[0].dy);
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}