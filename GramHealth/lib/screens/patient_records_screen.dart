import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/medical_record.dart';
import '../services/medical_record_service.dart';
import 'upload_record_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientRecordsScreen extends StatefulWidget {
  @override
  _PatientRecordsScreenState createState() => _PatientRecordsScreenState();
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
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Make sure you connect to the server. Could not fetch records.";
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open document')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Medical Vault'),
        actions: [
          IconButton(
            icon: Icon(Icons.cloud_upload),
            tooltip: 'Upload Document',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UploadRecordScreen()),
              );
              if (result == true) {
                _fetchRecords();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchRecords,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UploadRecordScreen()),
          );
          if (result == true) {
            _fetchRecords();
          }
        },
        icon: Icon(Icons.cloud_upload),
        label: Text('Upload Record'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey.shade700)),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchRecords, child: Text('Retry')),
          ],
        ),
      );
    }

    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No medical records found.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            SizedBox(height: 8),
            Text('Upload your physical health documents safely.', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UploadRecordScreen()),
                );
                if (result == true) {
                  _fetchRecords();
                }
              },
              icon: Icon(Icons.add),
              label: Text("Upload Record", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)
              )
            )
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        final isAbha = record.source == 'ABHA';

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: isAbha ? 3 : 1,
          shape: RoundedRectangleBorder(
            side: isAbha ? BorderSide(color: Colors.blue.shade200, width: 2) : BorderSide.none,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAbha ? Colors.blue.shade50 : Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                record.documentType == 'X_RAY' ? Icons.image : Icons.description,
                color: isAbha ? Colors.blue.shade700 : Theme.of(context).primaryColor,
              ),
            ),
            title: Text(record.title ?? 'Untitled Record', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 6),
                Text('Type: ${record.documentType}'),
                Text('Date: ${record.issuedDate?.toString().substring(0, 10) ?? '-'}'),
                if (isAbha) 
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 14, color: Colors.blue.shade800),
                        SizedBox(width: 4),
                        Text('Fetched via ABHA', style: TextStyle(color: Colors.blue.shade900, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.remove_red_eye, color: Theme.of(context).primaryColor),
              onPressed: () {
                if (record.fileUrl != null && record.fileUrl!.isNotEmpty) {
                  if (record.fileUrl!.startsWith('data:image')) {
                    final base64String = record.fileUrl!.split(',').last;
                    final bytes = base64Decode(base64String);
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppBar(
                              title: Text('Document View'), 
                              automaticallyImplyLeading: false,
                              actions: [CloseButton()],
                            ),
                            Flexible(child: InteractiveViewer(child: Image.memory(bytes))),
                          ]
                        )
                      )
                    );
                  } else {
                    _launchUrl(record.fileUrl!);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No document attachment found.")));
                }
              },
            ),
          ),
        );
      },
    );
  }
}
