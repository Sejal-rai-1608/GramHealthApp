import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/mock_api.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  List<HealthRecord> _records = [];
  bool _isAdmin = false;
  bool _showAddModal = false;
  final _doctorCtrl = TextEditingController();
  final _illnessCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await RecordsService.getHealthRecords();
    if (mounted) setState(() => _records = records);
  }

  void _addRecord() {
    final newRecord = HealthRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _dateCtrl.text.isEmpty ? 'Today' : _dateCtrl.text,
      doctor: _doctorCtrl.text,
      illness: _illnessCtrl.text,
      diagnosis: _illnessCtrl.text,
      prescription: 'Prescribed by ${_doctorCtrl.text}',
    );
    setState(() {
      _records = [newRecord, ..._records];
      _showAddModal = false;
      _doctorCtrl.clear();
      _illnessCtrl.clear();
      _dateCtrl.clear();
      _timeCtrl.clear();
    });
  }

  @override
  void dispose() {
    _doctorCtrl.dispose();
    _illnessCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryBg,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('health_records'),
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        GestureDetector(
                          onTap: () => setState(() => _isAdmin = !_isAdmin),
                          child: Text(
                            _isAdmin ? context.tr('patient_view') : context.tr('admin_view'),
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.primaryAccent, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showAddModal = true),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.primaryAccent.withValues(alpha: 0.4), blurRadius: 8)],
                        ),
                        child: const Icon(Icons.add, color: AppColors.textDark, size: 24),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  children: [
                    // Progress tracker
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 4)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.tr('meeting_progress'),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              const Text('60%',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryAccent)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              value: 0.6,
                              minHeight: 8,
                              backgroundColor: Color(0xFFEEEEEE),
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(context.tr('remaining_links'),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                        ],
                      ),
                    ),

                    // Records with timeline
                    ...List.generate(_records.length, (i) => _buildRecordRow(i)),
                  ],
                ),
              ),
            ],
          ),

          // Add modal overlay
          if (_showAddModal)
            GestureDetector(
              onTap: () => setState(() => _showAddModal = false),
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    child: GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('add_new_record'),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                          const SizedBox(height: 20),
                          _formField(context.tr('doctor_name'), 'e.g. Dr. Rajesh', _doctorCtrl),
                          _formField(context.tr('illness_reason'), 'e.g. Fever', _illnessCtrl),
                          Row(
                            children: [
                              Expanded(child: _formField(context.tr('date'), 'Oct 15', _dateCtrl)),
                              const SizedBox(width: 10),
                              Expanded(child: _formField(context.tr('time'), '10:00 AM', _timeCtrl)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _showAddModal = false),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  child: Text(context.tr('cancel'), style: const TextStyle(fontSize: 15, color: Color(0xFF999999))),
                                ),
                              ),
                              GestureDetector(
                                onTap: _addRecord,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(context.tr('save_record'),
                                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 14)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordRow(int i) {
    final record = _records[i];
    final isFirst = i == 0;
    final isLast = i == _records.length - 1;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline
          SizedBox(
            width: 30,
            child: Column(
              children: [
                if (!isFirst) Expanded(child: Container(width: 2, color: const Color(0xFFDDDDDD))),
                Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryAccent, width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(color: AppColors.primaryAccent, shape: BoxShape.circle),
                    ),
                  ),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: const Color(0xFFDDDDDD))),
              ],
            ),
          ),

          // Card
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/health-overview'),
              child: Container(
                margin: const EdgeInsets.only(left: 8, bottom: 16),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(record.date,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF888888))),
                          const Icon(Icons.chevron_right, size: 18, color: Color(0xFFAAAAAA)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(record.doctor,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('diagnosis'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
                            Text(record.diagnosis, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.description_outlined, size: 14, color: AppColors.primaryAccent),
                          const SizedBox(width: 6),
                          Expanded(child: Text(record.prescription,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF555555)))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formField(String label, String hint, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
        const SizedBox(height: 6),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.secondaryBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
