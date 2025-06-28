import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

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

  String _formatDateTime(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('MMM d, y  h:mm a').format(dateTime);
    } catch (e) {
      return 'Unknown date';
    }
  }

  Future<void> _fetchVendorData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        print("Current UID: ${user.uid}");

        _userRef = _dbRef.child('users').child(user.uid);
        final DatabaseEvent event = await _userRef.once();
        final DataSnapshot snapshot = event.snapshot;

        if (snapshot.value != null) {
          final rawMap = Map<Object?, Object?>.from(snapshot.value as Map);
          final formattedMap = rawMap.map((key, value) => MapEntry(key.toString(), value));

          print('✅ Fetched vendor data: $formattedMap');

          setState(() {
            _vendorData = formattedMap;
            _addressController.text = _vendorData['address'] ?? '';
            _phoneController.text = _vendorData['phoneNumber'] ?? '';
            _isLoading = false;
          });
        } else {
          print('⚠️ No data found for user');
        }
      } else {
        print('⚠️ No current user logged in');
      }
    } catch (e) {
      print('❌ Error fetching vendor data: $e');
      setState(() => _isLoading = false);
    }
  }


  Future<void> _updateVendorData(String field, String value) async {
    try {
      await _userRef.update({field: value});
      setState(() {
        _vendorData[field] = value;
      });
    } catch (e) {
      print('Error updating $field: $e');
    }
  }

  Widget _buildEditableInfoTile(
      String title,
      String value,
      IconData icon,
      TextEditingController controller,
      bool isEditing,
      VoidCallback onEditToggle,
      ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF4A49).withOpacity(isDarkMode ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              color: isDarkMode ? Colors.white70 : const Color(0xFFFF4A49),
              size: 24),
        ),
        title: Text(title,
            style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                fontWeight: FontWeight.w500)),
        subtitle: isEditing
            ? TextField(
          controller: controller,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: Theme.of(context).hintColor,
            ),
          ),
        )
            : Text(value.isEmpty ? 'Not provided' : value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            )),
        trailing: GestureDetector(
          onTap: onEditToggle,
          child: Text(
            isEditing ? 'SAVE' : 'EDIT',
            style: TextStyle(
              color: isEditing
                  ? const Color(0xFF4CAF50) // Green for SAVE
                  : Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFFF4A49) // Pink for EDIT in dark mode
                  : const Color(0xFFFF4A49), // Pink for EDIT in light mode too
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF4A49).withOpacity(isDarkMode ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              color: isDarkMode ? Colors.white70 : const Color(0xFFFF4A49),
              size: 24),
        ),
        title: Text(title,
            style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                fontWeight: FontWeight.w500)),
        subtitle: Text(value.isEmpty ? 'Not provided' : value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Store Info',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
            fontFamily: 'Poppins',
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFF4A49),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildInfoTile('Store Name',
                _vendorData['businessName'] ?? '', Icons.store),
            _buildInfoTile('Store Status',
                _vendorData['status']?.toString().toUpperCase() ?? 'PENDING',
                Icons.verified_user_rounded),
            _buildEditableInfoTile(
              'Store Address',
              _vendorData['address'] ?? '',
              Icons.location_on_rounded,
              _addressController,
              _isEditingAddress,
                  () async {
                if (_isEditingAddress) {
                  await _updateVendorData('address', _addressController.text);
                }
                setState(() => _isEditingAddress = !_isEditingAddress);
              },
            ),
            _buildEditableInfoTile(
              'Contact Number',
              _vendorData['phoneNumber'] ?? '',
              Icons.phone_rounded,
              _phoneController,
              _isEditingPhone,
                  () async {
                if (_isEditingPhone) {
                  await _updateVendorData('phoneNumber', _phoneController.text);
                }
                setState(() => _isEditingPhone = !_isEditingPhone);
              },
            ),
            _buildInfoTile('Stripe ID',
                _vendorData['stripeAccountId'] ?? '', Icons.credit_card_rounded),
            _buildInfoTile('Registered Email',
                _vendorData['email'] ?? '', Icons.email_rounded),
            _buildInfoTile('Member Since',
                _formatDateTime(_vendorData['createdAt'] ?? ''),
                Icons.calendar_today_rounded),
            const SizedBox(height: 20),
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