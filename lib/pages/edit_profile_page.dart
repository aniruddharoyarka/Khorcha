import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isEmailVerified = false;
  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isFetching = false);
      return;
    }

    try {
      await user.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      displayNameController.text = data?['name'] ?? "User";
      emailController.text = updatedUser?.email ?? "No Email";
      isEmailVerified = updatedUser?.emailVerified ?? false;
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isFetching = false;
        });
      }
    }
  }

  Future<void> saveProfileChanges() async {
    FocusScope.of(context).unfocus();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newName = displayNameController.text.trim();
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newName.isEmpty) {
      _showCustomSnackBar("Name cannot be empty", true);
      return;
    }

    bool isChangingPassword = currentPassword.isNotEmpty ||
        newPassword.isNotEmpty ||
        confirmPassword.isNotEmpty;

    if (isChangingPassword) {
      if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
        _showCustomSnackBar("All password fields are required to change your password", true);
        return;
      }
      if (newPassword != confirmPassword) {
        _showCustomSnackBar("New passwords do not match", true);
        return;
      }
      if (newPassword.length < 6) {
        _showCustomSnackBar("Password must be at least 6 characters", true);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'name': newName}, SetOptions(merge: true));

      if (isChangingPassword && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
      }

      if (!mounted) return;
      _showCustomSnackBar("Profile updated successfully", false);
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      String message = "Failed to update profile";
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = "Current password is incorrect";
      } else if (e.code == 'too-many-requests') {
        message = "Too many attempts. Try again later";
      }
      if (!mounted) return;
      _showCustomSnackBar(message, true);
    } catch (e) {
      if (!mounted) return;
      _showCustomSnackBar("Something went wrong", true);
      debugPrint("Update error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> triggerPasswordReset() async {
    final email = emailController.text.trim();
    if (email.isEmpty || email == "No Email") {
      _showCustomSnackBar("No valid email to send reset link to.", true);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showCustomSnackBar("Password reset email sent to $email!", false);
    } catch (e) {
      _showCustomSnackBar("Failed to send password reset email.", true);
    }
  }

  void _showCustomSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF03624C),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 10,
      ),
    );
  }

  @override
  void dispose() {
    displayNameController.dispose();
    emailController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F7F6),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF03624C))),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Stack(
          children: [
            // header
            Container(
              height: size.height * 0.35,
              decoration: const BoxDecoration(
                color: Color(0xFF03624C),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(60),
                  bottomRight: Radius.circular(60),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -40,
                    left: -40,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 120,
                    right: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // App Bar
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Text(
                              "Edit Profile",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Foreground Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.12),

                    // Profile Avatar Overlapping Header
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF4F7F6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFF03624C),
                        child: Icon(Icons.person_rounded, size: 55, color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Profile Info Card
                    _buildSectionCard(
                      title: "Personal Information",
                      children: [
                        _buildTextField(
                          controller: displayNameController,
                          label: "Full Name",
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: emailController,
                          label: "Email Address",
                          icon: Icons.email_outlined,
                          enabled: false,
                        ),
                        if (isEmailVerified)
                          const Padding(
                            padding: EdgeInsets.only(top: 8, left: 10),
                            child: Row(
                              children: [
                                Icon(Icons.verified_rounded, color: Color(0xFF048A6B), size: 16),
                                SizedBox(width: 5),
                                Text("Email Verified", style: TextStyle(color: Color(0xFF048A6B), fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // Password Card
                    _buildSectionCard(
                      title: "Security",
                      children: [
                        _buildPasswordField(
                          controller: currentPasswordController,
                          label: "Current Password",
                          obscure: obscureCurrent,
                          toggle: () => setState(() => obscureCurrent = !obscureCurrent),
                        ),
                        const SizedBox(height: 20),
                        _buildPasswordField(
                          controller: newPasswordController,
                          label: "New Password",
                          obscure: obscureNew,
                          toggle: () => setState(() => obscureNew = !obscureNew),
                        ),
                        const SizedBox(height: 20),
                        _buildPasswordField(
                          controller: confirmPasswordController,
                          label: "Confirm New Password",
                          obscure: obscureConfirm,
                          toggle: () => setState(() => obscureConfirm = !obscureConfirm),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: triggerPasswordReset,
                            icon: const Icon(Icons.lock_reset_rounded, color: Color(0xFF03624C), size: 18),
                            label: const Text(
                                "Send Reset Link via Email",
                                style: TextStyle(color: Color(0xFF03624C), fontWeight: FontWeight.w700, fontSize: 14)
                            ),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 35),

                    //  Save Button
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF048A6B), Color(0xFF03624C)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF03624C).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : saveProfileChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                            : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Save Changes",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF03624C).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 25),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      style: TextStyle(fontWeight: FontWeight.w600, color: enabled ? Colors.black87 : Colors.black45),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: enabled ? Colors.black45 : Colors.black38, fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(color: Color(0xFF03624C), fontWeight: FontWeight.w700),
        prefixIcon: Icon(icon, color: enabled ? const Color(0xFF03624C) : Colors.black26),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF03624C), width: 2),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(color: Color(0xFF03624C), fontWeight: FontWeight.w700),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF03624C)),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.black38,
          ),
          onPressed: toggle,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF03624C), width: 2),
        ),
      ),
    );
  }
}