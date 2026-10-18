import 'dart:io';
import 'package:flutter/material.dart';
import '../models/prescription.dart';

/// Shows a saved prescription again: the original photo (tap to zoom)
/// and the translated details, so the user can double-check them.
class PrescriptionDetailScreen extends StatelessWidget {
  final Prescription prescription;

  const PrescriptionDetailScreen({super.key, required this.prescription});

  static const _orange = Color(0xFFF4711E);

  bool get _hasPhoto =>
      prescription.imagePath.isNotEmpty &&
      File(prescription.imagePath).existsSync();

  String _doctorLabel(String name) {
    final l = name.toLowerCase().trim();
    final hasTitle = l.startsWith('dr') || l.contains('m.d');
    return hasTitle ? name : 'Dr. $name';
  }

  void _openFullPhoto(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image.file(File(prescription.imagePath)),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Original photo',
              style: TextStyle(color: _orange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_hasPhoto) ...[
            GestureDetector(
              onTap: () => _openFullPhoto(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(prescription.imagePath),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap the photo to zoom in and compare it with the translation below.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ] else
            Container(
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('The photo is no longer available on this device.',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = prescription;
    final isCompleted = p.status == 'Completed';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          Container(
            height: 110,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
            decoration: const BoxDecoration(
              color: _orange,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Prescription #${p.id}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const Text('Saved prescription details',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _photoCard(context),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Patient',
                                style: TextStyle(
                                    color: _orange,
                                    fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isCompleted ? 'Completed' : 'On going',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? Colors.green.shade800
                                      : Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.patientName.trim().isEmpty
                              ? 'Unknown patient'
                              : p.patientName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        if (p.patientAge > 0)
                          Text('Age: ${p.patientAge}',
                              style: const TextStyle(color: Colors.black54)),
                        Text('Date: ${p.date}',
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 12)),
                        const Divider(height: 24),
                        const Text('Medicines',
                            style: TextStyle(
                                color: _orange, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (p.medications.isEmpty)
                          const Text('No medicines were recorded.',
                              style: TextStyle(color: Colors.black54)),
                        ...p.medications.map(
                          (m) => Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0xFFFFEBE0),
                                  child:
                                      Icon(Icons.medication, color: _orange),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.genericName.isNotEmpty
                                            ? m.genericName
                                            : m.brandName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text('How to take it',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey)),
                                      Text(m.instruction,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                      if (m.quantity.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text('Amount given: ${m.quantity}',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(),
                        Text('Doctor: ${_doctorLabel(p.doctorName)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('License No: ${p.doctorLicense}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 8),
                        const Text(
                          'Scanned text may contain errors. Always confirm with your doctor or pharmacist before taking any medicine.',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
