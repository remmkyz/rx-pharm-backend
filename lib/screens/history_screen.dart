import 'package:flutter/material.dart';
import '../models/prescription.dart';
import '../services/user_data_service.dart';
import 'prescription_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedTab = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// Loads the saved prescriptions of the account that is currently logged in.
  Future<void> _loadHistory() async {
    await UserDataService.syncPrescriptionHistory();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  List<Prescription> get _filteredList {
    if (_selectedTab == 'Pending') {
      return prescriptionHistory.where((p) => p.status == 'Pending').toList();
    } else if (_selectedTab == 'Completed') {
      return prescriptionHistory.where((p) => p.status == 'Completed').toList();
    }
    return prescriptionHistory;
  }

  String _doctorLabel(String name) {
    final l = name.toLowerCase().trim();
    final hasTitle = l.startsWith('dr') || l.contains('m.d');
    return hasTitle ? name : 'Dr. $name';
  }

  void _openDetails(Prescription prescription) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrescriptionDetailScreen(prescription: prescription),
      ),
    );
  }

  Future<void> _confirmDelete(Prescription prescription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Prescription #${prescription.id}?'),
        content: const Text(
          'This will permanently remove this saved prescription and its photo from your history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await UserDataService.deletePrescription(prescription.id);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prescription deleted.')),
    );
  }

  void _showEditStatusDialog(Prescription prescription) {
    String currentStatus = prescription.status;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (innerContext, setDialogState) {
            return AlertDialog(
              title: Text('Edit Prescription #${prescription.id}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select prescription status:'),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    title: const Text('On going (Pending)'),
                    value: 'Pending',
                    groupValue: currentStatus,
                    activeColor: const Color(0xFFF4711E),
                    onChanged: (val) {
                      setDialogState(() => currentStatus = val!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Completed'),
                    value: 'Completed',
                    groupValue: currentStatus,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      setDialogState(() => currentStatus = val!);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF4711E)),
                  onPressed: () async {
                    prescription.status = currentStatus;
                    // Save the change so it is kept after logout / restart
                    await UserDataService.savePrescriptionHistory(
                        prescriptionHistory);
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    if (!mounted) return;
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Prescription status updated successfully!')),
                    );
                  },
                  child:
                      const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _cardAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('History',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    Text('View and edit your past prescriptions',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tab switcher
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBE0),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: ['All', 'Pending', 'Completed'].map((tab) {
                final isSelected = _selectedTab == tab;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = tab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF4711E)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tab,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFF4711E),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF4711E)),
                  )
                : _filteredList.isEmpty
                    ? const Center(
                        child: Text(
                          'No saved prescriptions found.\nScan a prescription to add it here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          final item = _filteredList[index];
                          final isCompleted = item.status == 'Completed';
                          final medNames = item.medications
                              .map((m) => m.brandName)
                              .where((n) => n.trim().isNotEmpty)
                              .join(', ');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8)
                              ],
                            ),
                            child: Column(
                              children: [
                                // Tap the top part to view the prescription
                                InkWell(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                  onTap: () => _openDetails(item),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        const CircleAvatar(
                                          backgroundColor: Color(0xFFFFEBE0),
                                          child: Icon(Icons.medication,
                                              color: Color(0xFFF4711E)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Prescription #${item.id}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              if (item.patientName
                                                  .trim()
                                                  .isNotEmpty)
                                                Text(
                                                    'Patient: ${item.patientName}',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                              if (medNames.isNotEmpty)
                                                Text(medNames,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                              Text('Date: ${item.date}',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey)),
                                              Text(
                                                  _doctorLabel(item.doctorName),
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey),
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isCompleted
                                                ? Colors.green.shade100
                                                : Colors.orange.shade100,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            isCompleted
                                                ? 'Completed'
                                                : 'On going',
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
                                  ),
                                ),
                                const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  child: Row(
                                    children: [
                                      _cardAction(
                                        icon: Icons.visibility_outlined,
                                        label: 'View',
                                        color: const Color(0xFFF4711E),
                                        onTap: () => _openDetails(item),
                                      ),
                                      _cardAction(
                                        icon: Icons.edit_outlined,
                                        label: 'Status',
                                        color: Colors.grey.shade700,
                                        onTap: () =>
                                            _showEditStatusDialog(item),
                                      ),
                                      _cardAction(
                                        icon: Icons.delete_outline,
                                        label: 'Delete',
                                        color: Colors.red,
                                        onTap: () => _confirmDelete(item),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
