import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/settings_tile.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;

  String name = "Loading...";

  Future<void> fetchName() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          name = doc['name'] ?? "User";
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchName();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), // Match dashboard
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // 1. Redesigned Profile Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF03624C).withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 45,
                          backgroundColor: Color(0xFF03624C),
                          child: Icon(Icons.person_rounded, color: Colors.white, size: 45),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, color: Color(0xFF03624C), size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? "No Email",
                        style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfilePage(),
                            ),
                          );
                          fetchName();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF03624C).withOpacity(0.1),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Edit Profile",
                          style: TextStyle(
                            color: Color(0xFF03624C),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Redesigned Settings Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SettingsTile(
                        icon: Icons.account_balance_wallet_rounded,
                        title: "Monthly Budget",
                        onTap: () => _showBudgetDialog(context),
                      ),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF4F7F6)),

                      // --- NEW: MANAGE CATEGORIES OPTION ---
                      SettingsTile(
                        icon: Icons.category_rounded,
                        title: "Manage Categories",
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageCategoriesPage()));
                        },
                      ),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF4F7F6)),

                      SettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: "About Khorcha",
                        onTap: () => _showAboutBottomSheet(context),
                      ),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF4F7F6)),
                      SettingsTile(
                        icon: Icons.logout_rounded,
                        title: "Logout",
                        onTap: () => _showLogoutDialog(context),
                        trailing: const SizedBox(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    int currentBudget = 0;

    try {
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        currentBudget = doc['budget'] ?? 0;
      }
    } catch (e) {
      debugPrint("Error fetching budget: $e");
    }

    final TextEditingController budgetController = TextEditingController(text: currentBudget.toString());

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 25),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF03624C).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Color(0xFF03624C)),
                    ),
                    const SizedBox(width: 15),
                    const Text("Monthly Budget", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Enter Amount",
                    prefixText: "৳ ",
                    filled: true,
                    fillColor: const Color(0xFFF4F7F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF03624C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () async {
                      final newBudget = int.tryParse(budgetController.text.trim());
                      if (newBudget == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a valid number")));
                        return;
                      }
                      try {
                        await docRef.set({'budget': newBudget}, SetOptions(merge: true));
                        if (context.mounted) Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Budget saved successfully")));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save budget")));
                      }
                    },
                    child: const Text("Save Budget", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAboutBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 25),
              const Text("About Khorcha", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87)),
              const SizedBox(height: 5),
              const Text("Version 1.0.0", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Color(0xFFF4F7F6), thickness: 2),
              ),
              const Text(
                "Khorcha is your personal finance companion.\nDeveloped by Aniruddha Roy Arka",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              ),
              const SizedBox(width: 15),
              const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          content: const Text("Are you sure you want to log out? You will need to login again to access your account.", style: TextStyle(color: Colors.black54)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}

// =========================================================================
// NEW: MANAGE CATEGORIES PAGE
// =========================================================================

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  final user = FirebaseAuth.instance.currentUser;

  void _showAddCategoryDialog(String type) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Add $type Category"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Category Name",
            filled: true,
            fillColor: Color(0xFFF4F7F6),
            border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(15))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF03624C)),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final field = type == 'Income' ? 'incomeCategories' : 'expenseCategories';
                await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                  field: FieldValue.arrayUnion([controller.text.trim()])
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(String type, String categoryName) async {
    final field = type == 'Income' ? 'incomeCategories' : 'expenseCategories';
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      field: FieldValue.arrayRemove([categoryName])
    });
  }

  Widget _buildCategoryList(List<dynamic> categories, String type) {
    if (categories.isEmpty) {
      return Center(
        child: Text("No $type categories found.\nClick the + button to add one.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFF4F7F6),
              child: Icon(Icons.category, color: Color(0xFF03624C), size: 20),
            ),
            title: Text(cat, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteCategory(type, cat),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: Text("Error: Not logged in")));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          title: const Text("Categories", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black87),
          bottom: const TabBar(
            labelColor: Color(0xFF03624C),
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFF03624C),
            tabs: [
              Tab(text: "Expense"),
              Tab(text: "Income"),
            ],
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF03624C)));

            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final expenseCategories = data['expenseCategories'] ?? [];
            final incomeCategories = data['incomeCategories'] ?? [];

            return TabBarView(
              children: [
                _buildCategoryList(expenseCategories, "Expense"),
                _buildCategoryList(incomeCategories, "Income"),
              ],
            );
          },
        ),
        floatingActionButton: Builder(
            builder: (ctx) {
              return FloatingActionButton(
                backgroundColor: const Color(0xFF03624C),
                child: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  final tabIndex = DefaultTabController.of(ctx).index;
                  _showAddCategoryDialog(tabIndex == 0 ? "Expense" : "Income");
                },
              );
            }
        ),
      ),
    );
  }
}