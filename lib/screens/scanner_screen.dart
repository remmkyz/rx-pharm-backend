import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/prescription.dart';
import '../services/prescription_parser.dart';
import '../services/user_data_service.dart';
import '../widgets/header_notification_bell.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  XFile? _capturedImage;
  bool _isProcessing = false;
  String? _errorMessage;

  // Strictly null until a valid prescription (Rx + supporting fields) is verified
  ParsedPrescription? _result;

  // Patient name is usually handwritten (OCR can't read it), so the user
  // types it in after the scan.
  final TextEditingController _patientNameController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void dispose() {
    _recognizer.close();
    _patientNameController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() {
      _capturedImage = photo;
      _isProcessing = true;
      _errorMessage = null;
      _result = null;
      _patientNameController.clear();
    });

    try {
      // 1. Real OCR: read all text in the photo
      final recognized =
          await _recognizer.processImage(InputImage.fromFilePath(photo.path));

      final text = recognized.blocks
          .expand((b) => b.lines)
          .map((l) => l.text)
          .join('\n');

      debugPrint('=== OCR TEXT ===\n$text\n================');

      // 2. Not a prescription -> show the "No Prescription Found!" view
      final parsed = PrescriptionParser.parse(text);
      if (parsed == null) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'No Prescription Found!';
          _result = null;
        });
        return;
      }

      // 3. Valid prescription -> show the translated result.
      //    Pre-fill the patient name if OCR managed to read one.
      setState(() {
        _isProcessing = false;
        _result = parsed;
        _patientNameController.text = parsed.patientName ?? '';
      });
    } catch (e, st) {
      debugPrint('OCR ERROR: $e\n$st');
      setState(() {
        _isProcessing = false;
        _errorMessage = 'No Prescription Found!';
        _result = null;
      });
    }
  }

  void _resetScan() {
    setState(() {
      _capturedImage = null;
      _errorMessage = null;
      _result = null;
      _patientNameController.clear();
    });
  }

  bool _isSaving = false;

  /// The camera photo lives in a temporary folder that Android can clear at
  /// any time. Copy it into the app's own storage so it can be viewed again
  /// from History.
  Future<String> _persistImage(String? sourcePath) async {
    if (sourcePath == null || sourcePath.isEmpty) return '';
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/prescriptions');
      if (!await folder.exists()) await folder.create(recursive: true);
      final dest =
          '${folder.path}/rx_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(sourcePath).copy(dest);
      return dest;
    } catch (e) {
      debugPrint('Could not copy prescription photo: $e');
      return sourcePath;
    }
  }

  Future<void> _savePrescription() async {
    final r = _result;
    if (r == null || _isSaving) return;

    final patientName = _patientNameController.text.trim();
    if (patientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the patient name before saving.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _isSaving = true;
    try {
      final timestamp = DateTime.now();
      final savedImagePath = await _persistImage(_capturedImage?.path);
      final newId = await UserDataService.nextPrescriptionId();

      // Parse age safely to an integer
      int parsedAge = 0;
      if (r.age != null) {
        parsedAge = int.tryParse(r.age!) ?? 0;
      }

      // Saved under the logged-in account, so it is still there after
      // Log Out, the Back button, or restarting the app.
      await UserDataService.addPrescription(
        Prescription(
          id: newId,
          patientName: patientName,
          patientAge: parsedAge,
          date: r.date ??
              '${timestamp.day}/${timestamp.month}/${timestamp.year}',
          doctorName: r.doctorName ?? 'Attending Physician, M.D.',
          doctorLicense: r.doctorLicense ?? 'N/A',
          imagePath: savedImagePath,
          status: 'Pending',
          medications: r.medications
              .map((m) => Medication(
                    genericName: '${m.name} ${m.strength ?? ''}'.trim(),
                    brandName: m.name,
                    quantity: m.quantity ?? 'As Prescribed',
                    instruction: m.howToTake,
                  ))
              .toList(),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription saved to History successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } finally {
      _isSaving = false;
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
                const HeaderNotificationBell(),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _capturedImage == null
                  ? _buildCameraPrompt()
                  : _isProcessing
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(
                                color: Color(0xFFF4711E)),
                          ),
                        )
                      : _errorMessage != null
                          ? _buildErrorView(_errorMessage!)
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
        const Text('Scan Your Prescription',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const Text('Place the prescription within the frame to scan',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
            ),
            onPressed: _captureImage,
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            label: const Text('Scan Prescription',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(String message) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
            ],
          ),
          child: Column(
            children: [
              if (_capturedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(_capturedImage!.path),
                      height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
              const SizedBox(height: 16),
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent, size: 52),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.redAccent)),
              const SizedBox(height: 6),
              const Text(
                'Please make sure a prescription with the Rx symbol is clearly visible in the frame.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4711E)),
                onPressed: _captureImage,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retry Scan',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700),
                onPressed: _resetScan,
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildPrescriptionDetailsView() {
    final r = _result;
    if (r == null) return const SizedBox(); // nothing displayed

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Column(
            children: [
              Text('Your Prescription',
                  style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Here is what your doctor wrote, in plain language',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
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
              const Text('Patient',
                  style: TextStyle(
                      color: Color(0xFFF4711E), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Patient name: typed by the user after the scan
              TextField(
                controller: _patientNameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Patient name',
                  hintText: 'Type the patient\'s full name',
                  prefixIcon: const Icon(Icons.person_outline,
                      color: Color(0xFFF4711E)),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFFF4711E), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (r.dateOfBirth != null)
                Text('Date of birth: ${r.dateOfBirth}',
                    style: const TextStyle(color: Colors.black54)),
              if (r.age != null)
                Text('Age: ${r.age}',
                    style: const TextStyle(color: Colors.black54)),
              if (r.date != null)
                Text('Prescribed on: ${r.date}',
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 12)),
              const Divider(height: 24),
              if (r.medications.isEmpty)
                const Text(
                  'We could not read the medicine clearly. Please retake the photo or ask your pharmacist.',
                  style: TextStyle(color: Colors.black54),
                ),
              ...r.medications.asMap().entries.map((e) {
                final med = e.value;
                return Container(
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
                        child: Icon(Icons.medication,
                            color: Color(0xFFF4711E)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${med.name}${med.strength != null ? ' · ${med.strength}' : ''}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            const Text('How to take it',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            Text(med.howToTake,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            if (med.quantity != null) ...[
                              const SizedBox(height: 6),
                              Text('Amount given: ${med.quantity}',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                            if (med.refills != null)
                              Text(med.refills!,
                                  style: const TextStyle(fontSize: 12)),
                            if (med.rawInstruction.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Written as: "${med.rawInstruction}"',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (r.doctorName != null || r.doctorLicense != null) ...[
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (r.doctorName != null)
                      Expanded(
                        child: Text('Doctor: ${r.doctorName}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                    if (r.doctorLicense != null)
                      Text('License No: ${r.doctorLicense}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'Scanned text may contain errors. Always confirm with your doctor or pharmacist before taking any medicine.',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
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
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4711E)),
                onPressed: _captureImage,
                icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                label: const Text('Retry',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
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
            decoration: const BoxDecoration(
                color: Color(0xFFFFEBE0), shape: BoxShape.circle),
            child:
                const Icon(Icons.shield_outlined, color: Color(0xFFF4711E)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data Privacy & Security',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(
                    'Your scanned prescriptions are securely processed and kept confidential.',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
