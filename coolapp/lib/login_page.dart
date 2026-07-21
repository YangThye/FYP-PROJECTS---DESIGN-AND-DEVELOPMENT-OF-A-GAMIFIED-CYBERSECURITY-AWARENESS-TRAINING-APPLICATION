import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'signup_page.dart';
import 'main.dart';
import 'preliminary_check_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('remembered_email');

    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- FORGOT PASSWORD DIALOG ---
  Future<void> _showResetPasswordDialog() async {
    final TextEditingController resetEmailController = TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Reset Password", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter your email address and we'll send you a link to reset your password.",
                style: TextStyle(color: Colors.blueGrey.shade400),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Email address",
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                String email = resetEmailController.text.trim();

                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter an email address."), backgroundColor: Colors.orange),
                  );
                  return;
                }

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Reset link sent! Check your inbox."),
                          backgroundColor: Colors.green
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Error: Could not send link. Check the email address."),
                          backgroundColor: Colors.red
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Send Link", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // --- MATCH APP BACKGROUND ---
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // --- MATCH APP TYPOGRAPHY ---
              const Text(
                'Welcome\nto CyberShield',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.2, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Text(
                "Log in to continue your mission.",
                style: TextStyle(fontSize: 16, color: Colors.blueGrey[400], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 40),

              // --- REDESIGNED TEXT FIELDS ---
              _buildTextField(
                hintText: 'Email address',
                controller: _emailController,
                inputType: TextInputType.emailAddress,
                icon: Icons.email_outlined,
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
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Switch(
                        value: _rememberMe,
                        onChanged: (value) => setState(() => _rememberMe = value),
                        activeColor: Colors.blueAccent,
                      ),
                      Text("Remember me", style: TextStyle(color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  TextButton(
                    onPressed: _showResetPasswordDialog,
                    child: const Text("Forgot password?", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- REDESIGNED LOGIN BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55, // Matched height with other pages
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    String email = _emailController.text.trim();
                    String password = _passwordController.text.trim();

                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter both email and password"), backgroundColor: Colors.orange),
                      );
                      return;
                    }

                    setState(() { _isLoading = true; });

                    try {
                      UserCredential userCredential = await FirebaseAuth.instance
                          .signInWithEmailAndPassword(email: email, password: password);

                      final uid = userCredential.user!.uid;

                      final prefs = await SharedPreferences.getInstance();
                      if (_rememberMe) {
                        await prefs.setString('remembered_email', email);
                      } else {
                        await prefs.remove('remembered_email');
                      }

                      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

                      if (context.mounted) {
                        bool isVerifiedAgent = false;

                        if (userDoc.exists && userDoc.data() != null) {
                          final data = userDoc.data() as Map<String, dynamic>;
                          if (data['onboarding_complete'] == true) {
                            isVerifiedAgent = true;
                          }
                        }

                        if (isVerifiedAgent) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyHomePage(
                                username: userCredential.user?.email ?? "Agent",
                              ),
                            ),
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const PreliminaryCheckPage()),
                          );
                        }
                      }
                    } on FirebaseAuthException catch (e) {
                      String errorMessage = "Login failed. Please try again.";

                      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
                        errorMessage = "No account found for that email.";
                      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                        errorMessage = "Incorrect password.";
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
                        );
                      }
                    } catch (e) {
                      debugPrint("General Error: $e");
                    } finally {
                      if (mounted) setState(() { _isLoading = false; });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, // Matched app color
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0, // Flat modern look
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text("Sign in", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don’t have an account? ", style: TextStyle(color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupPage()),
                      );
                    },
                    child: const Text("Sign up", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- REDESIGNED TEXT FIELD BUILDER ---
  Widget _buildTextField({
    required String hintText,
    TextEditingController? controller,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
    TextInputType inputType = TextInputType.text,
    IconData? icon,
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
        fillColor: Colors.white, // Modern white background
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
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.blueGrey),
          onPressed: onVisibilityToggle,
        )
            : null,
      ),
    );
  }
}