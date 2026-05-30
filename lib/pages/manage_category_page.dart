import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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