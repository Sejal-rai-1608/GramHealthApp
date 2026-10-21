import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/medical_record.dart';
import '../../services/medical_record_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_state.dart';
import 'package:go_router/go_router.dart';

class PatientRecordsScreen extends StatefulWidget {
  const PatientRecordsScreen({super.key});

  @override
  State<PatientRecordsScreen> createState() => _PatientRecordsScreenState();
}

class _PatientRecordsScreenState extends State<PatientRecordsScreen> {
  final MedicalRecordService _recordService = MedicalRecordService();
  List<MedicalRecord> _records = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final records = await _recordService.getMyRecords();
      if (mounted)
        setState(() {
          _records = records;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error =
              'Could not fetch records. Check your connection or try again.';
          _isLoading = false;
        });
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open document')));
    }
  }

  Future<void> _pushUpload() async {
    final result = await context.push<bool>('/upload-record');
    if (!mounted) return;
    if (result == true) _fetchRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Health records',
                style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            Text('Private • stored securely on your device and the server',
                style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.ink),
            onPressed: _fetchRecords,
            tooltip: 'Refresh',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              height: 36,
              child: FilledButton.icon(
                onPressed: _pushUpload,
                icon: const Icon(Icons.upload_rounded, size: 16),
                label: Text('Upload',
                    style: GoogleFonts.manrope(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                    foregroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingState(message: 'Loading your records…');
    if (_error != null) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Unable to load records',
        subtitle: _error!,
        actionLabel: 'Retry',
        onAction: _fetchRecords,
      );
    }
    if (_records.isEmpty) {
      return EmptyState(
        icon: Icons.folder_open_rounded,
        title: 'No records yet',
        subtitle:
            'Upload a prescription, lab report, or scan. You can use your camera or gallery.',
        actionLabel: 'Upload record',
        onAction: _pushUpload,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: _records.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _RecordCard(record: _records[i], onOpen: _openUrl),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final MedicalRecord record;
  final Future<void> Function(String) onOpen;
  const _RecordCard({required this.record, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final isAbha = record.source == 'ABHA';
    final isImage = record.documentType == 'X_RAY' ||
        (record.fileUrl?.startsWith('data:image') ?? false);
    return CareCard(
      borderColor: isAbha ? AppColors.tealPale : AppColors.borderLight,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isAbha ? AppColors.mint : AppColors.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
                isImage ? Icons.image_outlined : Icons.description_outlined,
                size: 20,
                color: AppColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.title ?? 'Untitled record',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 3),
                Text(
                    '${record.documentType}  •  ${record.issuedDate?.toString().substring(0, 10) ?? '-'}',
                    style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkMuted)),
                if (isAbha) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 12, color: AppColors.teal),
                        const SizedBox(width: 4),
                        Text('ABHA verified',
                            style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teal)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              final url = record.fileUrl;
              if (url == null || url.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No attachment found.')));
                return;
              }
              if (url.startsWith('data:image')) {
                final bytes = base64Decode(url.split(',').last);
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.lg)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                          child: Row(
                            children: [
                              Text('Document',
                                  style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink)),
                              const Spacer(),
                              IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => Navigator.pop(context)),
                            ],
                          ),
                        ),
                        Flexible(
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: InteractiveViewer(
                                    child: Image.memory(bytes)))),
                      ],
                    ),
                  ),
                );
              } else {
                onOpen(url);
              }
            },
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.visibility_outlined,
                    size: 16, color: AppColors.surface),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
