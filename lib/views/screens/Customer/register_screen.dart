import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:multi_vendor_ecommerce_app/controllers/auth_controller.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthController authController = AuthController();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _stripeAccountIdController = TextEditingController();

  bool isLoading = false;

  late String fullname;
  late String email;
  late String Password;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _showErrors = false; // Controls when to show errors

  String? selectedRole; // To store the selected role
  final List<String> roles = ['Customer', 'Vendor']; // Available roles

  String? _validateFullName(String value) {
    if (value.isEmpty) {
      return 'Please enter your full name';
    } else if (value.length < 3) {
      return 'Full Name must be at least 3 characters';
    } else if (value.length > 20) {
      return "Name cannot exceed 20 characters";
    } else if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value)) {
      return 'Only alphabets and spaces are allowed';
    }
    return null;
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) {
      return 'Please enter your email';
    } else if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
      return 'At least one uppercase letter';
    }
    if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
      return 'At least one lowercase letter';
    }
    if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
      return 'At least one number';
    }
    if (!RegExp(r'(?=.[@$*#!%?&])').hasMatch(value)) {
      return 'A least one special character (@\$!%*?&)';
    }
    return null;
  }

  String? _validateConfirmPassword(String value) {
    if (value.isEmpty) {
      return 'Please confirm your password';
    } else if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateRole(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a role';
    }
    return null;
  }
  String? _validateBusinessName(String value) {
    if (selectedRole == 'Vendor' && value.isEmpty) return 'Please enter business name';
    if (selectedRole == 'Vendor' && value.length < 3) return 'Business name must be at least 3 characters';
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (selectedRole?.toLowerCase() == 'vendor') {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter phone number';
      }

      final trimmedValue = value.trim();

      // Accepts: +14155552671 (international) OR 03161234567 (Pakistan local)
      final phoneRegExp = RegExp(r'^(\+?[1-9]\d{6,14}|03[0-9]{9})$');

      if (!phoneRegExp.hasMatch(trimmedValue)) {
        return 'Enter a valid phone number';
      }
    }
    return null;
  }



  String? _validateAddress(String value) {
    if (selectedRole == 'Vendor' && value.isEmpty) return 'Please enter address';
    return null;
  }

  // Add this validation method
  String? _validateStripeAccountId(String value) {
    if (selectedRole == 'Vendor') {
      if (value.isEmpty) {
        return 'Please enter Stripe Account ID';
      }


      if (!value.startsWith('acct_')) {
        return 'Invalid Stripe Account ID';
      }

      return null;
    }
  }


  void _submitForm() async {
    setState(() {
      _showErrors = true; // Enable error messages
    });

    // Check if form is valid
    if (!_formKey.currentState!.validate()) {
      return; // Stop execution if form validation fails
    }

    setState(() {
      isLoading = true;
    });

    try {
      String res = await authController.createNewUser(
        _fullNameController.text,
        _emailController.text,
        _passwordController.text,
        selectedRole!, // Pass the selected role
        businessName: selectedRole == 'Vendor' ? _businessNameController.text : '',
        phoneNumber: selectedRole == 'Vendor' ? _phoneNumberController.text : '',
        address: selectedRole == 'Vendor' ? _addressController.text : '',
        stripeAccountId: selectedRole == 'Vendor' ? _stripeAccountIdController.text : '',
      );


      /*if (res == 'success') {
        setState(() {
          isLoading = false;
        });

        Get.snackbar(
          "Success",
          "Account has been created Successfully!",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
          shouldIconPulse: false,
          snackStyle: SnackStyle.FLOATING,
          isDismissible: true,
          margin: const EdgeInsets.all(10),
          duration: Duration(seconds: 2),
        );

        await Future.delayed(Duration(seconds: 2));

        Get.off(() => LoginScreen());
      }*/
      // In _SignUpScreenState's _submitForm method
      if (res == 'success') {
        setState(() => isLoading = false);

        Get.snackbar(
          "Verification Email Sent",
          "We've sent a verification email. Please check your inbox and verify your email before logging in.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: const Icon(Icons.email, color: Colors.orange, size: 30),
          shouldIconPulse: false,
          snackStyle: SnackStyle.FLOATING,
          isDismissible: true,
        );

        await Future.delayed(Duration(seconds: 5));
        Get.off(() => LoginScreen());
      }


    else if (res == 'user_exists') {
        setState(() {
          isLoading = false;
        });

        Get.snackbar(
          "User Already Registered",
          "This email is already registered. Please log in.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: const Icon(Icons.warning, color: Color(0xFFFF4A49), size: 30),
          shouldIconPulse: false,
          snackStyle: SnackStyle.FLOATING,
          isDismissible: true,
          margin: const EdgeInsets.all(10),
        );

        await Future.delayed(Duration(seconds: 2));

        Get.off(() => LoginScreen());
      } else {
        setState(() {
          isLoading = false;
        });

        Get.snackbar(
          "Error",
          "Something went wrong! Not Registered! Try Again...",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
          shouldIconPulse: false,
          snackStyle: SnackStyle.FLOATING,
          isDismissible: true,
          margin: const EdgeInsets.all(10),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      Get.snackbar(
        "Error",
        "Something went wrong! Not Registered! Try Again...",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: Colors.black,
        icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
        shouldIconPulse: false,
        snackStyle: SnackStyle.FLOATING,
        isDismissible: true,
        margin: const EdgeInsets.all(10),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xFFFF4A49),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Expanded(
              flex: 1,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Create Your Account',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Icon(
                      Icons.person_add,
                      size: 50,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: const TextStyle(
                              color: Color(0xFF333333),
                              fontFamily: 'Poppins',
                            ),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          ),
                          validator: (value) => _validateFullName(value!),
                          onChanged: (value) => setState(() {
                            fullname = value;
                          }),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(
                              color: Color(0xFF333333),
                              fontFamily: 'Poppins',
                            ),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                            errorText: _showErrors ? _validateEmail(_emailController.text) : null,
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          ),
                          validator: (value) => _validateEmail(value!),
                          onChanged: (value) => setState(() {
                            email = value;
                          }),
                        ),

                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Role',
                            labelStyle: const TextStyle(
                              color: Color(0xFF333333),
                              fontFamily: 'Poppins',
                            ),
                            border: OutlineInputBorder(
                            ),
                            prefixIcon: Icon(Icons.person),
                            errorText: _showErrors ? _validateRole(selectedRole) : null,
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          ),

                          items: roles.asMap().entries.map((entry) {
                            int index = entry.key + 1;
                            String role = entry.value;
                            return DropdownMenuItem<String>(
                              value: role,
                              child: Row(
                                children: [
                                  Text("$index. ", style: TextStyle(color: Colors.black,fontWeight: FontWeight.normal,)),
                                  SizedBox(width: 8),
                                  Text(role, style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black)),
                                ],
                              ),
                            );
                          }).toList(),

                          selectedItemBuilder: (BuildContext context) {
                            return roles.map((String role) {
                              return Text(
                                role,
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal,),
                              );
                            }).toList();
                          },
                          onChanged: (value) {
                            setState(() {
                              selectedRole = value;
                            });
                          },
                          validator: (value) => _validateRole(value),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        if (selectedRole == 'Vendor') ...[
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _businessNameController,
                            decoration: InputDecoration(
                              labelText: 'Business Name',
                              labelStyle: const TextStyle(
                                color: Color(0xFF333333),
                                fontFamily: 'Poppins',
                              ),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.business),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            validator: (value) => _validateBusinessName(value!),
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _phoneNumberController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              labelStyle: const TextStyle(
                                color: Color(0xFF333333),
                                fontFamily: 'Poppins',
                              ),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            validator: (value) => _validatePhoneNumber(value!),
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: 'Address',
                              labelStyle: const TextStyle(
                                color: Color(0xFF333333),
                                fontFamily: 'Poppins',
                              ),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            validator: (value) => _validateAddress(value!),
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _stripeAccountIdController,
                            decoration: InputDecoration(
                              labelText: 'Stripe Account ID',
                              labelStyle: const TextStyle(
                                color: Color(0xFF333333),
                                fontFamily: 'Poppins',
                              ),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.payment),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            validator: (value) => _validateStripeAccountId(value!),
                          ),
                        ],
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(
                              color: Color(0xFF333333),
                              fontFamily: 'Poppins',
                            ),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                              color: Colors.grey,
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          ),
                          validator: (value) => _validatePassword(value!),
                          onChanged: (value) => setState(() {
                            Password = value;
                          }),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            labelStyle: const TextStyle(
                              color: Color(0xFF333333),
                              fontFamily: 'Poppins',
                            ),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.verified),
                            suffixIcon: IconButton(
                              icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                              color: Colors.grey,
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          ),
                          validator: (value) => _validateConfirmPassword(value!),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(0xFFFF4A49), // Red
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account?",style: TextStyle(
                              fontFamily: 'Poppins',
                            ),),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(opacity: animation, child: child);
                                    },
                                  ),
                                );
                              },
                              child: const Text(
                                "Sign In",
                                style: TextStyle(color: Color(0xFFFF4A49), fontWeight: FontWeight.bold, fontFamily: 'Poppins',),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}