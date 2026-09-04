class MedicalRecord {
  final String id;
  final String patientId;
  final String? consultationId;
  final String? title;
  final String? documentType;
  final String? fileUrl;
  final String? source;
  final DateTime? issuedDate;
  final String? diagnosis;
  final String? clinicalNotes;
  final DateTime createdAt;
  
  MedicalRecord({
    required this.id,
    required this.patientId,
    this.consultationId,
    this.title,
    this.documentType,
    this.fileUrl,
    this.source,
    this.issuedDate,
    this.diagnosis,
    this.clinicalNotes,
    required this.createdAt,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'],
      patientId: json['patientId'] ?? '',
      consultationId: json['consultationId'],
      title: json['title'],
      documentType: json['documentType'] ?? json['document_type'],
      fileUrl: json['fileUrl'] ?? json['file_url'],
      source: json['source'],
      issuedDate: json['issuedDate'] != null ? DateTime.parse(json['issuedDate']) : null,
      diagnosis: json['diagnosis'],
      clinicalNotes: json['clinicalNotes'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
