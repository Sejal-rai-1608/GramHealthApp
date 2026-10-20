import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/medical_record_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_icon_button.dart';
import '../../widgets/care_card.dart';
import '../../widgets/primary_button.dart';

class UploadRecordScreen extends StatefulWidget {
  const UploadRecordScreen({super.key});

  @override
  State<UploadRecordScreen> createState() => _UploadRecordScreenState();
}

class _UploadRecordScreenState extends State<UploadRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  String _documentType = 'PRESCRIPTION';
  bool _isUploading = false;
  File? _selectedImage;
  String? _base64Image;
  final _recordService = MedicalRecordService();

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: source, imageQuality: 55);
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() {
        _selectedImage = File(img.path);
        _base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      });
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please capture or select a document image.', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.emergency,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    setState(() => _isUploading = true);
    try {
      await _recordService.uploadManualRecord(_titleCtrl.text.trim(), _documentType, _base64Image!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Record saved to your vault', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColors.surface)),
          backgroundColor: AppColors.tealDeep,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.emergency));
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
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
            onTap: () => Navigator.pop(context),
            tooltip: 'Back',
            iconSize: 18,
            size: 44,
          ),
        ),
        leadingWidth: 56,
        title: Text('Upload document', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CareCard(
                color: AppColors.mintLight,
                borderColor: AppColors.tealPale,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.shield_outlined, size: 18, color: AppColors.surface)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Private health vault', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Text('Encrypted, visible only to you and your assigned clinician.', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.inkSoft, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Document details', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 10),
              CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Document title *', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleCtrl,
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: 'e.g. Blood test — Jan 2026',
                        hintStyle: GoogleFonts.manrope(fontSize: 13, color: AppColors.inkFaint),
                        prefixIcon: const Icon(Icons.title_rounded, size: 18, color: AppColors.inkFaint),
                        filled: true,
                        fillColor: AppColors.groundAlt,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.borderLight)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.borderLight)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.tealDeep, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 14),
                    Text('Document type', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _documentType,
                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.category_outlined, size: 18, color: AppColors.inkFaint),
                        filled: true,
                        fillColor: AppColors.groundAlt,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.borderLight)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.borderLight)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: const ['PRESCRIPTION', 'LAB_REPORT', 'X_RAY', 'OTHER']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' '))))
                          .toList(),
                      onChanged: (v) => setState(() => _documentType = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Preview
              if (_selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(border: Border.all(color: AppColors.borderLight), borderRadius: BorderRadius.circular(AppRadii.lg)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.lg - 1),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                    ),
                  ),
                )
              else
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.groundAlt, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.image_outlined, color: AppColors.inkMuted)),
                      const SizedBox(height: 10),
                      Text('No document selected', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkMuted)),
                      const SizedBox(height: 4),
                      Text('Take a photo or choose from gallery', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.inkFaint)),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        label: Text('Camera', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(color: AppColors.borderLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                          backgroundColor: AppColors.surface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: Text('Gallery', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(color: AppColors.borderLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                          backgroundColor: AppColors.surface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isUploading)
                const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CircularProgressIndicator(color: AppColors.teal)))
              else
                PrimaryButton(title: 'Save to vault', icon: Icons.lock_rounded, onPress: _upload, width: double.infinity),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 12, color: AppColors.inkFaint),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Offline? We save it securely on your device and sync when you are back online.',
                        style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.inkFaint, height: 1.4)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
