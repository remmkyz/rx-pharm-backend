class Medication {
  final String genericName;
  final String brandName;
  final String quantity;
  final String instruction;

  Medication({
    required this.genericName,
    required this.brandName,
    required this.quantity,
    required this.instruction,
  });
}

class Prescription {
  final String id;
  final String patientName;
  final int patientAge;
  final String date;
  final String doctorName;
  final String doctorLicense;
  final List<Medication> medications;
  final String imagePath;
  String status; // 'Pending' or 'Completed'

  Prescription({
    required this.id,
    required this.patientName,
    required this.patientAge,
    required this.date,
    required this.doctorName,
    required this.doctorLicense,
    required this.medications,
    required this.imagePath,
    this.status = 'Pending',
  });
}

// Global state list for demo persistence
List<Prescription> prescriptionHistory = [
  Prescription(
    id: '001',
    patientName: 'Warren Zafra',
    patientAge: 21,
    date: '31/1/2024',
    doctorName: 'Dr. Jerry Sy, M.D.',
    doctorLicense: '70423',
    medications: [],
    imagePath: '',
    status: 'Completed',
  ),
  Prescription(
    id: '002',
    patientName: 'Warren Zafra',
    patientAge: 21,
    date: '01/2/2024',
    doctorName: 'Dr. Jerry Sy, M.D.',
    doctorLicense: '70423',
    medications: [],
    imagePath: '',
    status: 'Completed',
  ),
  Prescription(
    id: '003',
    patientName: 'Warren Zafra',
    patientAge: 21,
    date: '10/2/2024',
    doctorName: 'Dr. Jerry Sy, M.D.',
    doctorLicense: '70423',
    medications: [],
    imagePath: '',
    status: 'Pending',
  ),
];