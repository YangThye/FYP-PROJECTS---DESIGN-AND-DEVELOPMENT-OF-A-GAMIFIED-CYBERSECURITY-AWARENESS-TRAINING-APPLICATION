import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'preliminary_check_page.dart'; // <-- ADDED IMPORT

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDate;

  final List<String> _genderOptions = ['Male', 'Female', 'Prefer not to say'];

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  // --- NATIVE DATE PICKER FUNCTION ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthdayController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              const Text(
                'Create Account',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Text(
                "Join the academy and secure your digital world.",
                style: TextStyle(fontSize: 16, color: Colors.blueGrey[400], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),

              _buildTextField(
                  hintText: 'Username',
                  controller: _usernameController,
                  icon: Icons.person_outline
              ),
              const SizedBox(height: 16),

              _buildTextField(
                  hintText: 'Email address',
                  controller: _emailController,
                  inputType: TextInputType.emailAddress,
                  icon: Icons.email_outlined
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.blueGrey),
                decoration: InputDecoration(
                  hintText: 'Gender',
                  hintStyle: TextStyle(color: Colors.blueGrey.shade300, fontWeight: FontWeight.w500),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.people_outline, color: Colors.blueGrey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                ),
                items: _genderOptions.map((String gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildTextField(
                    hintText: 'Birthday (YYYY-MM-DD)',
                    controller: _birthdayController,
                    icon: Icons.cake_outlined,
                    suffixIcon: const Icon(Icons.calendar_month_rounded, color: Colors.blueAccent),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                hintText: 'Enter password',
                isPassword: true,
                isVisible: _isPasswordVisible,
                controller: _passwordController,
                icon: Icons.lock_outline,
                onVisibilityToggle: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                hintText: 'Re-enter password',
                isPassword: true,
                isVisible: _isConfirmPasswordVisible,
                controller: _confirmPasswordController,
                icon: Icons.lock_outline,
                onVisibilityToggle: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    String username = _usernameController.text.trim();
                    String email = _emailController.text.trim();
                    String password = _passwordController.text.trim();
                    String confirmPassword = _confirmPasswordController.text.trim();

                    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || _selectedGender == null || _birthdayController.text.isEmpty) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill in all fields"), backgroundColor: Colors.orange),
                      );
                      return;
                    }

                    final emailRegExp = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");
                    if (!emailRegExp.hasMatch(email)) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a valid email address."), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    if (password != confirmPassword) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Passwords do not match!"), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    final passwordRegExp = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[^a-zA-Z0-9]).{8,}$');
                    if (!passwordRegExp.hasMatch(password)) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Password must be at least 8 characters and include 1 uppercase, 1 lowercase, and 1 symbol."),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 4),
                        ),
                      );
                      return;
                    }

                    setState(() { _isLoading = true; });

                    try {
                      final usernameQuery = await FirebaseFirestore.instance
                          .collection('users')
                          .where('username', isEqualTo: username)
                          .get();

                      if (usernameQuery.docs.isNotEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Username is already taken. Please choose another."),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                        setState(() { _isLoading = false; });
                        return;
                      }

                      UserCredential userCredential = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(email: email, password: password);

                      String uid = userCredential.user!.uid;

                      await FirebaseFirestore.instance.collection('users').doc(uid).set({
                        'username': username,
                        'email': email,
                        'gender': _selectedGender,
                        'birthday': _birthdayController.text,
                        'quizzes_completed': 0,
                        'badges': [],
                        'created_at': FieldValue.serverTimestamp(),
                      });

                      // --- FIX: ROUTE TO PRELIMINARY CHECK PAGE INSTEAD OF HOME ---
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PreliminaryCheckPage(),
                          ),
                              (Route<dynamic> route) => false,
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      String errorMessage = "An error occurred. Please try again.";
                      if (e.code == 'weak-password') {
                        errorMessage = "The password provided is too weak.";
                      } else if (e.code == 'email-already-in-use') {
                        errorMessage = "An account already exists for that email.";
                      } else if (e.code == 'invalid-email') {
                        errorMessage = "Please enter a valid email address.";
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
                        );
                      }
                    } catch (e) {
                      debugPrint("General Error: $e");
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Database Error: $e"), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() { _isLoading = false; });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text("Create Account", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    TextEditingController? controller,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
    TextInputType inputType = TextInputType.text,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType: inputType,
      style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.blueGrey.shade300, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: icon != null ? Icon(icon, color: Colors.blueGrey) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        suffixIcon: suffixIcon ?? (isPassword
            ? IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.blueGrey),
          onPressed: onVisibilityToggle,
        )
            : null),
      ),
    );
  }
}