import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EditProfilePage extends StatefulWidget {
  final String currentUsername;
  final String? currentGender;
  final DateTime? currentBirthday;
  final String? currentAvatar;

  const EditProfilePage({
    super.key,
    required this.currentUsername,
    this.currentGender,
    this.currentBirthday,
    this.currentAvatar,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _usernameController;
  String? _selectedGender;
  DateTime? _selectedBirthday;
  String? _selectedAvatar;
  bool _isLoading = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Prefer not to say'];

  final List<String> _avatars = [
    'assets/avatars/1.png',
    'assets/avatars/2.png',
    'assets/avatars/3.png',
    'assets/avatars/4.png',
  ];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
    _selectedGender = widget.currentGender;
    _selectedBirthday = widget.currentBirthday;
    _selectedAvatar = widget.currentAvatar;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  Future<void> _updateProfile() async {
    String newUsername = _usernameController.text.trim();

    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username cannot be empty"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // 1. Check if the username is already taken
      if (newUsername != widget.currentUsername) {
        final QuerySnapshot result = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: newUsername)
            .get();

        if (result.docs.isNotEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("This username is already taken."), backgroundColor: Colors.orange),
            );
          }
          setState(() { _isLoading = false; });
          return;
        }
      }

      // 2. Update the main user profile
      Map<String, dynamic> updateData = {
        'username': newUsername,
      };

      if (_selectedGender != null) updateData['gender'] = _selectedGender;
      if (_selectedBirthday != null) updateData['birthday'] = DateFormat('yyyy-MM-dd').format(_selectedBirthday!);
      if (_selectedAvatar != null) updateData['avatar'] = _selectedAvatar;

      await FirebaseFirestore.instance.collection('users').doc(uid).set(updateData, SetOptions(merge: true));

      // --- 3. BULLETPROOF LEADERBOARD SYNC ---
      // If they changed their name, we MUST update all 4 leaderboards!
      if (newUsername != widget.currentUsername) {
        final List<String> games = ["Job Hunter", "Phish Shooter", "Glitch Hunter", "Cyber Snake"];

        for (String game in games) {
          try {
            final docRef = FirebaseFirestore.instance
                .collection('leaderboards')
                .doc(game)
                .collection('scores')
                .doc(uid);

            // Check if they actually have a score in this specific game
            final docSnap = await docRef.get();
            if (docSnap.exists) {
              // If they do, overwrite their old name with the new one!
              await docRef.update({'username': newUsername});
              debugPrint("Successfully updated name in $game");
            }
          } catch (e) {
            debugPrint("Failed to sync name for $game: $e");
          }
        }
      }

      // 4. Success!
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // --- CUSTOM SEAMLESS HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 2.0),
                        child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
                      ),
                    ),
                  ),
                  const Text(
                      "Edit Profile",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5)
                  ),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 40),

              // --- AVATAR SELECTION SECTION ---
              const Center(child: Text("Choose your Agent Avatar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey))),
              const SizedBox(height: 16),

              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _avatars.length,
                  itemBuilder: (context, index) {
                    final avatarPath = _avatars[index];
                    bool isSelected = _selectedAvatar == avatarPath;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatar = avatarPath),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 16),
                        padding: EdgeInsets.all(isSelected ? 4 : 0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.blueAccent : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                              : [],
                        ),
                        child: CircleAvatar(
                          radius: isSelected ? 38 : 35,
                          backgroundColor: Colors.white,
                          backgroundImage: AssetImage(avatarPath),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),

              // --- FORM SECTION ---
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Username", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      decoration: _customInputDecoration(hint: "Enter new username", icon: Icons.person_outline),
                    ),
                    const SizedBox(height: 24),

                    const Text("Gender", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                      decoration: _customInputDecoration(hint: "Select Gender", icon: Icons.transgender_outlined),
                      items: _genderOptions.map((String gender) {
                        return DropdownMenuItem<String>(value: gender, child: Text(gender));
                      }).toList(),
                      onChanged: (String? newValue) => setState(() => _selectedGender = newValue),
                    ),
                    const SizedBox(height: 24),

                    const Text("Birthday", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectBirthday(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cake_outlined, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              _selectedBirthday == null
                                  ? "Select Birthday"
                                  : DateFormat('MMMM d, yyyy').format(_selectedBirthday!),
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedBirthday == null ? Colors.grey[600] : Colors.black87,
                                fontWeight: _selectedBirthday == null ? FontWeight.normal : FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.calendar_month_rounded, color: Colors.blueAccent, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- SAVE BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text("Save Profile", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _customInputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500]),
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)),
    );
  }
}