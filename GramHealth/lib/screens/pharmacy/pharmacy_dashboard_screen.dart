import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/pharmacy_service.dart';
import '../../services/auth_service.dart';
import '../../utils/auth_guard.dart';
import '../../theme/app_colors.dart';

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
  final List<String> _medicinesList = [];
  final _newMedCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _medicinesList.addAll(kEssentialMedicines);
    // Default all to false initially
    for (var m in _medicinesList) {
      _inventory[m] = false;
    }
    _loadInitialState();
  }

  @override
  void dispose() {
    _newMedCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.getUser();
      final currentUserId = user?['id'] as String?;
      
      if (currentUserId != null) {
        final pharmacies = await PharmacyService.syncPharmacies();
        final myPharmacy = pharmacies.firstWhere(
          (p) => p.userId == currentUserId, 
          orElse: () => throw Exception('Pharmacy not found for user'),
        );

        for (var inv in myPharmacy.inventories) {
          final medName = inv['medicineName'] as String;
          final inStock = inv['inStock'] as bool;
          _inventory[medName] = inStock;
          if (!_medicinesList.contains(medName)) {
            _medicinesList.add(medName);
          }
        }
      }
    } catch (e) {
      print('Failed to load initial pharmacy state: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    AuthGuard.onLogout();
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

  void _addCustomMedicine() {
    final val = _newMedCtrl.text.trim();
    if (val.isEmpty) return;
    if (!_medicinesList.contains(val)) {
      setState(() {
        _medicinesList.insert(0, val);
        _inventory[val] = true;
      });
      _toggleMedicine(val, true);
    }
    _newMedCtrl.clear();
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
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newMedCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Add new medicine name...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _addCustomMedicine(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primaryAccent),
                    onPressed: _addCustomMedicine,
                  )
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
            child: ListView.builder(
              itemCount: _medicinesList.length,
              itemBuilder: (context, index) {
                final med = _medicinesList[index];
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
