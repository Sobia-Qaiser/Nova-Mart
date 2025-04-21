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
      _showCustomSnackbar('$field updated successfully!', true);
    } catch (e) {
      _showCustomSnackbar('Error updating $field: $e', false);
    }
  }

  void _showCustomSnackbar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          right: 20,
          left: 20,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: isDarkMode
                ? Colors.blueGrey[800]
                : const Color(0xFFFF4A49).withOpacity(0.1),
            child: Icon(
              Icons.storefront_rounded,
              size: 40,
              color: isDarkMode
                  ? Colors.blueGrey[200]
                  : const Color(0xFFFF4A49),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _vendorData['businessName'] ?? 'Business Name',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Chip(
            backgroundColor: _vendorData['status'] == 'approved'
                ? Colors.green.withOpacity(0.15)
                : Colors.orange.withOpacity(0.15),
            label: Text(
              _vendorData['status']?.toString().toUpperCase() ?? 'PENDING',
              style: TextStyle(
                color: _vendorData['status'] == 'approved'
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            avatar: Icon(
              Icons.verified_rounded,
              size: 18,
              color: _vendorData['status'] == 'approved'
                  ? Colors.green
                  : Colors.orange,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(icon, color: Color(0xFFFF4A49), size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: isEditing
                        ? TextField(
                      controller: controller,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: label,
                      ),
                    )
                        : Text(
                      value.isNotEmpty ? value : 'Not provided',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isEditing ? Icons.check_circle_rounded : Icons.edit_rounded,
                      color: isEditing ? Colors.green : Color(0xFFFF4A49),
                      size: 24,
                    ),
                    onPressed: () async {
                      if (isEditing) await _updateVendorData(fieldName, controller.text);
                      onEditToggle(!isEditing);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: Color(0xFFFF4A49), size: 24),
                  const SizedBox(width: 16),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: Colors.white,
            )),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFFFF4A49),
        iconTheme: IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFFF4A49)))
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 24),
            _buildEditableField(
              label: 'Store Address',
              value: _vendorData['address'] ?? '',
              controller: _addressController,
              isEditing: _isEditingAddress,
              onEditToggle: (value) =>
                  setState(() => _isEditingAddress = value),
              fieldName: 'address',
              icon: Icons.location_on_outlined,
            ),
            _buildEditableField(
              label: 'Contact Number',
              value: _vendorData['phoneNumber'] ?? '',
              controller: _phoneController,
              isEditing: _isEditingPhone,
              onEditToggle: (value) =>
                  setState(() => _isEditingPhone = value),
              fieldName: 'phoneNumber',
              icon: Icons.phone_outlined,
            ),
            _buildInfoItem(
              'Registered Email',
              _vendorData['email'] ?? 'Not provided',
              Icons.email_outlined,
            ),
            _buildInfoItem(
              'Member Since',
              _vendorData['createdAt'] ?? 'Unknown',
              Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 32),
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