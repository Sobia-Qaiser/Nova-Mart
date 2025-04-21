import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class StoreDetails extends StatefulWidget {
  const StoreDetails({super.key});

  @override
  _StoreDetailsState createState() => _StoreDetailsState();
}

class _StoreDetailsState extends State<StoreDetails> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  late DatabaseReference _userRef;

  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  bool _isLoading = true;
  bool _isEditingAddress = false;
  bool _isEditingPhone = false;
  Map<String, dynamic> _vendorData = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchVendorData();
  }

  void _initializeControllers() {
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
  }

  Future<void> _fetchVendorData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        _userRef = _dbRef.child('users').child(user.uid);
        final DatabaseEvent event = await _userRef.once();
        final DataSnapshot snapshot = event.snapshot;

        if (snapshot.value != null) {
          setState(() {
            _vendorData = Map<String, dynamic>.from(snapshot.value as Map);
            _addressController.text = _vendorData['address'] ?? '';
            _phoneController.text = _vendorData['phoneNumber'] ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching vendor data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateVendorData(String field, String value) async {
    try {
      await _userRef.update({field: value});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$field updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating $field: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF4A49).withOpacity(0.1),
            Colors.white.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF4A49).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.storefront,
              size: 40,
              color: const Color(0xFFFF4A49),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _vendorData['businessName'] ?? 'Business Name',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _vendorData['status'] == 'approved'
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  size: 16,
                  color: _vendorData['status'] == 'approved'
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  _vendorData['status']?.toString().toUpperCase() ?? 'PENDING',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _vendorData['status'] == 'approved'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    required Function(bool) onEditToggle,
    required String fieldName,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF4A49).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFFF4A49), size: 22),
        ),
        title: isEditing
            ? TextField(
          controller: controller,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins'),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: label,
            hintStyle: TextStyle(
              color: Colors.grey[400],
            ),
          ),
        )
            : Text(
          value.isNotEmpty ? value : 'Not provided',
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins'),
        ),
        trailing: IconButton(
          icon: Icon(
            isEditing ? Icons.check_circle_rounded : Icons.edit_rounded,
            color: isEditing ? Colors.green : const Color(0xFFFF4A49),
            size: 24,
          ),
          onPressed: () async {
            if (isEditing) await _updateVendorData(fieldName, controller.text);
            onEditToggle(!isEditing);
          },
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF4A49).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFFF4A49), size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'Poppins'),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Profile',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFF4A49),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 16),
            _buildEditableField(
                label: 'Store Address',
                value: _vendorData['address'] ?? '',
                controller: _addressController,
                isEditing: _isEditingAddress,
                onEditToggle: (value) =>
                    setState(() => _isEditingAddress = value),
                fieldName: 'address',
                icon: Icons.location_on_outlined),
            _buildEditableField(
                label: 'Contact Number',
                value: _vendorData['phoneNumber'] ?? '',
                controller: _phoneController,
                isEditing: _isEditingPhone,
                onEditToggle: (value) =>
                    setState(() => _isEditingPhone = value),
                fieldName: 'phoneNumber',
                icon: Icons.phone_outlined),
            _buildInfoItem(
                'Registered Email',
                _vendorData['email'] ?? 'Not provided',
                Icons.email_outlined),
            _buildInfoItem(
                'Member Since',
                _vendorData['createdAt'] ?? 'Unknown',
                Icons.calendar_today_outlined),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}