import 'package:flutter/material.dart';

class DoctorAppointmentsScreen extends StatelessWidget {
  const DoctorAppointmentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Appointments')),
      body: const Center(child: Text('Doctor Appointments Screen Placeholder')),
    );
  }
}
