import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class AuthController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final DatabaseReference database = FirebaseDatabase.instance.ref();

  //  createNewUser method
 /* Future<String> createNewUser(String fullName,
      String email,
      String password,
      String role, {
        String businessName = '',
        String phoneNumber = '',
        String address = '',
        String stripeAccountId = '',
      }) async {
    String res = 'some error occurred';
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      String createdAt = DateFormat('yyyy-MM-dd HH:mm').format(
          DateTime.now());


      // Common data for all users
      Map<String, dynamic> userData = {
        'fullName': fullName,
        'email': email,
        'userId': uid,
        'password': password,
        'role': role,
        'createdAt': createdAt,
      };

      // If user is a seller, add extra fields
      if (role.toLowerCase() == 'vendor') {
        userData.addAll({
          'businessName': businessName,
          'phoneNumber': phoneNumber,
          'address': address,
          'stripeAccountId': stripeAccountId,
          'status': 'pending',
        });
      }

      // Save user data under 'users' node
      await database.child('users').child(uid).set(userData);

      res = 'success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        res = 'user_exists';
      } else {
        res = e.message ?? 'An unexpected error occurred';
      }
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  //  role base login

  Future<String> loginUser(String email, String password) async {
    String res = 'Some error occurred';
    try {
      // 1. Sign in user
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Optional: Update password in database if needed
      await updateUserPasswordInDatabase(email, password);

      // 3. Get current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return 'User not found';
      }

      // 4. Fetch user data from Realtime Database
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid)
          .once();

      // Check if user data exists
      if (snapshot.snapshot.value == null) {
        return 'User data not found';
      }

      // 5. Extract role (default to 'customer' if missing)
      final userData = snapshot.snapshot.value as Map<dynamic, dynamic>;
      String role = userData['role']?.toString() ?? 'customer';
      String status = userData['status']?.toString().toLowerCase() ?? 'approved';

      // 6. Handle Vendor Status Logic
      if (role == 'vendor') {
        if (status == 'pending') {
          return 'pending_approval'; // Vendor can't access dashboard yet
        } else if (status == 'approved') {
          return 'success'; // Approved seller
        } else {
          return 'Account rejected'; // Vendor is rejected
        }
      }

      res = role;
    } catch (e) {
      res = e.toString();
    }
    return res;
  }*/


  // In AuthController class

  Future<String> createNewUser(String fullName, String email, String password, String role,
      {String businessName = '', String phoneNumber = '', String address = '', String stripeAccountId = ''}) async {
    String res = 'some error occurred';
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send verification email
      await userCredential.user?.sendEmailVerification();

      String uid = userCredential.user!.uid;
      String createdAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

      Map<String, dynamic> userData = {
        'fullName': fullName,
        'email': email,
        'userId': uid,
        'password': password,
        'role': role,
        'createdAt': createdAt,
        'emailVerified': false, // Track verification status
      };

      if (role.toLowerCase() == 'vendor') {
        userData.addAll({
          'businessName': businessName,
          'phoneNumber': phoneNumber,
          'address': address,
          'stripeAccountId': stripeAccountId,
          'status': 'pending',
        });
      }

      await database.child('users').child(uid).set(userData);
      res = 'success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        res = 'user_exists';
      } else {
        res = e.message ?? 'An unexpected error occurred';
      }
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  /*Future<String> loginUser(String email, String password) async {
    String res = 'Some error occurred';
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if email is verified
      if (!userCredential.user!.emailVerified) {
        await userCredential.user?.sendEmailVerification(); // Resend verification email
        return 'email_not_verified';
      }

      await updateUserPasswordInDatabase(email, password);
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'User not found';

      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid)
          .once();

      if (snapshot.snapshot.value == null) {
        return 'User data not found';
      }

      final userData = snapshot.snapshot.value as Map<dynamic, dynamic>;
      String role = userData['role']?.toString() ?? 'customer';
      String status = userData['status']?.toString().toLowerCase() ?? 'approved';

      if (role == 'vendor') {
        if (status == 'pending') {
          return 'pending_approval';
        } else if (status == 'approved') {
          return 'success';
        } else {
          return 'Account rejected';
        }
      }

      res = role;
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  // Update password in database
  Future<void> updateUserPasswordInDatabase(String email, String password) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No authenticated user found.");
        return;
      }

      String uid = user.uid;

      // Get user role
      DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users").child(uid);
      DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic>? userData = snapshot.value as Map<dynamic, dynamic>?;

        if (userData != null) {
          String role = userData["role"]?.toString().toLowerCase() ?? "";

          // Determine the correct node
          String node = role == "admin"
              ? "admins"
              : role == "customer"
              ? "customers"
              : role == "vendor"
              ? "vendors"
              : "";

          print("Updating password for user: $email with UID: $uid");
          print("Updating password in 'users' node...");

          // Update password in users node
          await FirebaseDatabase.instance.ref().child("users").child(uid).update({
            "password": password,
          });

          print("Password successfully updated for $role.");
        }
      } else {
        print("User data not found.");
      }
    } catch (e) {
      print("Error updating password in database: $e");
    }
  }*/

  Future<String> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check email verification first
      if (!userCredential.user!.emailVerified) {
        return 'email_not_verified';
      }

      // Rest of your login logic...
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userCredential.user!.uid)
          .once();

      if (snapshot.snapshot.value == null) {
        return 'user_data_not_found';
      }

      final userData = snapshot.snapshot.value as Map<dynamic, dynamic>;
      String role = userData['role']?.toString() ?? 'customer';
      String status = userData['status']?.toString().toLowerCase() ?? 'approved';

      if (role == 'vendor') {
        if (status == 'pending') return 'pending_approval';
        if (status == 'rejected') return 'Account rejected';
      }

      return role; // Return role for successful login
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        return 'invalid_credentials';
      }
      return e.code;
    } catch (e) {
      return e.toString();
    }
  }




  // Fetch Current Signed-In User Name from Firebase
  Future<String?> getCurrentCustomerName() async {
    User? user = auth.currentUser;
    if (user == null) return null;

    // Fetch user data from "users" node
    DataSnapshot userSnapshot = await database.child("users")
        .child(user.uid)
        .get();

    if (userSnapshot.exists) {
      Map<dynamic, dynamic>? userData = userSnapshot.value as Map<
          dynamic,
          dynamic>?;

      if (userData != null && userData["role"] != null &&
          userData["role"].toString().toLowerCase() == "customer") {
        return userData["fullName"]?.toString();
      }
    }

    return null; // If user is not a customer or data doesn't exist
  }

  Future<String?> getCurrentVendorName() async {
    User? user = auth.currentUser;
    if (user == null) return null;

    // Fetch user data from "users" node
    DataSnapshot userSnapshot = await database.child("users")
        .child(user.uid)
        .get();

    if (userSnapshot.exists) {
      Map<dynamic, dynamic>? userData = userSnapshot.value as Map<
          dynamic,
          dynamic>?;

      if (userData != null && userData["role"] != null &&
          userData["role"].toString().toLowerCase() == "vendor") {
        return userData["fullName"]?.toString();
      }
    }

    return null; // If user is not a customer or data doesn't exist
  }

}






