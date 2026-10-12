import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/prescription.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  XFile? _capturedImage;
  bool _isProcessing = false;
  bool _isBlurry = false;
  Prescription? _extractedDetails;

  final ImagePicker _picker = ImagePicker();

  Future<void> _captureImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() {
      _capturedImage = photo;
      _isProcessing = true;
      _isBlurry = false;
      _extractedDetails = null;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (photo.path.contains('blur')) {
      setState(() {
        _isProcessing = false;
        _isBlurry = true;
      });
      return;
    }

    setState(() {
      _isProcessing = false;
      _extractedDetails = Prescription(
        id: '00${prescriptionHistory.length + 1}',
        patientName: 'Warren Zafra',
        patientAge: 21,
        date: '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        doctorName: 'Jerry Sy, M.D.',
        doctorLicense: '70423',
        imagePath: photo.path,
        status: 'Pending',
        medications: [
          Medication(
            genericName: 'Levocetirizine',
            brandName: 'XYZAL or generic equivalents',
            quantity: '14 days',
            instruction: 'Take 1 tab before bedtime',
          ),
          Medication(
            genericName: 'Pantoprazole + Domperidone',
            brandName: 'Pantoprime or generic equivalents',
            quantity: '1 month',
            instruction: 'Take 1 capsule once a day, 30 min before food (e.g., breakfast).',
          ),
        ],
      );
    });
  }

  void _resetScan() {
    setState(() {
      _capturedImage = null;
      _isBlurry = false;
      _extractedDetails = null;
    });
  }

  void _savePrescription() {
    if (_extractedDetails != null) {
      prescriptionHistory.insert(0, _extractedDetails!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription saved to History!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          Container(
            height: 110,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
            decoration: const BoxDecoration(
              color: Color(0xFFF4711E),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Icon(Icons.notifications, color: Colors.white),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _capturedImage == null
                  ? _buildCameraPrompt()
                  : _isBlurry
                      ? _buildBlurryErrorView()
                      : _isProcessing
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(color: Color(0xFFF4711E)),
                              ),
                            )
                          : _buildPrescriptionDetailsView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPrompt() {
    return Column(
      children: [
        const Text(
          'Scan Your Prescription',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Place the prescription within the frame to scan',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF4711E), width: 3),
          ),
          child: const Center(
            child: Icon(Icons.receipt_long, size: 80, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 20),
        _buildSecurityBanner(),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF4711E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            onPressed: _captureImage,
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            label: const Text('Scan Prescription', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildBlurryErrorView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Image.file(File(_capturedImage!.path), height: 200, fit: BoxFit.cover),
              const SizedBox(height: 12),
              const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 48),
              const Text(
                'Image is blurry or not readable',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Text(
                'We couldn’t detect the text from this image. Please try scanning again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF4711E)),
                onPressed: _captureImage,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retry Scan', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFF4711E)),
                onPressed: _resetScan,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Discard'),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildPrescriptionDetailsView() {
    if (_extractedDetails == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Column(
            children: [
              Text('Prescription Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Check your medication information', style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Patient Information', style: TextStyle(color: Color(0xFFF4711E), fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Patient Name: ${_extractedDetails!.patientName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('Date: ${_extractedDetails!.date}', style: const TextStyle(color: Colors.black54)),
                ],
              ),
              Text('Age: ${_extractedDetails!.patientAge}', style: const TextStyle(color: Colors.black54)),
              const Divider(height: 24),
              ..._extractedDetails!.medications.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final med = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFFFEBE0),
                        child: Icon(Icons.medication, color: Color(0xFFF4711E)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Medication $idx', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Generic Name: ${med.genericName}', style: const TextStyle(fontSize: 12)),
                            Text('Brand: ${med.brandName}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('Quantity: ${med.quantity}', style: const TextStyle(fontSize: 11)),
                            Text('Instruction: ${med.instruction}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Doctor: ${_extractedDetails!.doctorName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('License No: ${_extractedDetails!.doctorLicense}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSecurityBanner(),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF4711E)),
                onPressed: _captureImage,
                icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                label: const Text('Retry', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFF4711E)),
                  foregroundColor: const Color(0xFFF4711E),
                ),
                onPressed: _savePrescription,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Save', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                ),
                onPressed: _resetScan,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Discard', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFFFEBE0), shape: BoxShape.circle),
            child: const Icon(Icons.shield_outlined, color: Color(0xFFF4711E)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Privacy & Security',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'Your scanned prescriptions are securely processed and kept confidential.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}