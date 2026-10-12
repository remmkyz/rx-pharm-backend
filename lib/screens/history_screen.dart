import 'package:flutter/material.dart';
import '../models/prescription.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedTab = 'All';

  List<Prescription> get _filteredList {
    if (_selectedTab == 'Pending') {
      return prescriptionHistory.where((p) => p.status == 'Pending').toList();
    } else if (_selectedTab == 'Completed') {
      return prescriptionHistory.where((p) => p.status == 'Completed').toList();
    }
    return prescriptionHistory;
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
                    Text('History', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('View your past prescriptions', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                        color: isSelected ? const Color(0xFFF4711E) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tab,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFFF4711E),
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filteredList.length,
              itemBuilder: (context, index) {
                final item = _filteredList[index];
                final isCompleted = item.status == 'Completed';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
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
                            Text('Prescription #${item.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Date: ${item.date}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('Dr. ${item.doctorName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCompleted ? Colors.green.shade800 : Colors.orange.shade800,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
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