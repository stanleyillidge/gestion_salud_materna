import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/appointment_provider.dart';
import 'appointment_item.dart';

class AppointmentList extends StatelessWidget {
  const AppointmentList({super.key});

  @override
  Widget build(BuildContext context) {
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final appointments = appointmentProvider.citas;

    return ListView.builder(
      itemCount: appointments.length,
      itemBuilder: (ctx, i) => AppointmentItem(appointments[i]),
    );
  }
}
