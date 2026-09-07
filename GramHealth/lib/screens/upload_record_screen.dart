import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/medical_record_service.dart';

class UploadRecordScreen extends StatefulWidget {
  @override
  _UploadRecordScreenState createState() => _UploadRecordScreenState();
}

class _UploadRecordScreenState extends State<UploadRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String _documentType = 'PRESCRIPTION';
  bool _isUploading = false;
  File? _selectedImage;
  String? _base64Image;
  final MedicalRecordService _recordService = MedicalRecordService();

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 50);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      setState(() {
        _selectedImage = File(image.path);
        _base64Image = 'data:image/jpeg;base64,$base64String';
      });
    }
  }

  Future<void> _upload() async {
    if (_formKey.currentState!.validate()) {
      if (_base64Image == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select or capture a document image first.')));
        return;
      }
      setState(() => _isUploading = true);
      try {
        await _recordService.uploadManualRecord(
          _titleController.text,
          _documentType,
          _base64Image!,
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploaded successfully!')));
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload: $e')));
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Document')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Upload a physical document to your health vault", style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
              SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Document Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _documentType,
                decoration: InputDecoration(
                  labelText: 'Document Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: ['PRESCRIPTION', 'LAB_REPORT', 'X_RAY', 'OTHER']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.replaceAll('_', ' ')),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _documentType = v!),
              ),
              SizedBox(height: 16),
              if (_selectedImage != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('No Document Selected', style: TextStyle(color: Colors.grey.shade600)),
                  ),
                ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera_alt),
                    label: Text('Camera'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library),
                    label: Text('Gallery'),
                  ),
                ],
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isUploading ? null : _upload,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isUploading 
                  ? CircularProgressIndicator(color: Colors.white) 
                  : Text('Save Record to Vault', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
