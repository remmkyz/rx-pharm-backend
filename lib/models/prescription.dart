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
  final String imagePath;
  String status; // 'Pending' or 'Completed'
  final List<Medication> medications;

  Prescription({
    required this.id,
    required this.patientName,
    required this.patientAge,
    required this.date,
    required this.doctorName,
    required this.doctorLicense,
    required this.imagePath,
    required this.status,
    required this.medications,
  });
}

// History starts completely empty as requested
List<Prescription> prescriptionHistory = [];