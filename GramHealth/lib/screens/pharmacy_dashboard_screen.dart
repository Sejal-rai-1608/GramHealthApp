import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/pharmacy_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

const List<String> kEssentialMedicines = [
  'Paracetamol',
  'Ibuprofen',
  'Amoxicillin',
  'Cetirizine',
  'Azithromycin',
  'Vitamin C',
  'Zinc',
  'ORS'
];

class PharmacyDashboardScreen extends StatefulWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  State<PharmacyDashboardScreen> createState() => _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends State<PharmacyDashboardScreen> {
  final Map<String, bool> _inventory = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default all to false. In a real app we would load their existing state here.
    for (var m in kEssentialMedicines) {
      _inventory[m] = false;
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) context.go('/login');
  }

  Future<void> _toggleMedicine(String med, bool status) async {
    setState(() => _inventory[med] = status);
    
    try {
      await PharmacyService.updateInventory(med, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated $med to ${status ? "In Stock" : "Out of Stock"}')),
        );
      }
    } catch (e) {
      // Revert if API fails
      setState(() => _inventory[med] = !status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update inventory')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacist Portal'),
        backgroundColor: AppColors.primaryAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            color: Colors.white,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Manage Inventory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                SizedBox(height: 8),
                Text('Toggle the slider to indicate if you currently have these essential medicines in stock.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: kEssentialMedicines.length,
              itemBuilder: (context, index) {
                final med = kEssentialMedicines[index];
                final inStock = _inventory[med] ?? false;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.medication, color: AppColors.primaryAccent),
                    title: Text(med, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(inStock ? 'In Stock' : 'Out of Stock', style: TextStyle(color: inStock ? Colors.green : Colors.red)),
                    trailing: Switch(
                      value: inStock,
                      activeColor: Colors.green,
                      onChanged: (val) => _toggleMedicine(med, val),
                    ),
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
