import 'package:fin_track/features/dashboard/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/category_model.dart';
import '../../core/services/firestore_service.dart';

// Provider to fetch categories
final categoryStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getCategories();
});

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Manage Categories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFBB86FC),
          labelColor: const Color(0xFFBB86FC),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (allCategories) {
          final expenses = allCategories
              .where((c) => c.type == 'expense')
              .toList();
          final income = allCategories
              .where((c) => c.type == 'income')
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(expenses, isExpense: true),
              _buildCategoryList(income, isExpense: false),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFBB86FC),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _showAddCategoryDialog(context),
      ),
    );
  }

  Widget _buildCategoryList(
    List<CategoryModel> categories, {
    required bool isExpense,
  }) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            Text(
              "No ${isExpense ? 'Expense' : 'Income'} categories yet.",
              style: const TextStyle(color: Colors.white24),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return Dismissible(
          key: Key(cat.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red.withOpacity(0.2),
            child: const Icon(Icons.delete, color: Colors.red),
          ),
          onDismissed: (_) =>
              ref.read(firestoreServiceProvider).deleteCategory(cat.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(cat.colorCode).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconData(cat.iconCode, fontFamily: 'MaterialIcons'),
                  color: Color(cat.colorCode),
                ),
              ),
              title: Text(
                cat.name,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    String type = _tabController.index == 0 ? 'expense' : 'income';
    int selectedIcon = Icons.category.codePoint;
    int selectedColor = 0xFFBB86FC;

    // A small set of predefined icons for the user to pick
    final List<IconData> icons = [
      Icons.fastfood,
      Icons.directions_car,
      Icons.shopping_bag,
      Icons.home,
      Icons.medical_services,
      Icons.sports_esports,
      Icons.school,
      Icons.pets,
      Icons.work,
      Icons.monetization_on,
      Icons.flight,
      Icons.build,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              'New Category',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    prefixIcon: Icon(Icons.edit, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Select Icon",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: icons.map((icon) {
                    final isSelected = selectedIcon == icon.codePoint;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => selectedIcon = icon.codePoint),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFBB86FC)
                              : Colors.white10,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? Colors.black : Colors.white70,
                          size: 20,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('CANCEL'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('CREATE'),
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty) {
                    ref
                        .read(firestoreServiceProvider)
                        .addCategory(
                          name: nameCtrl.text,
                          type: type,
                          iconCode: selectedIcon,
                          colorCode: type == 'income' ? 0xFF03DAC6 : 0xFFCF6679,
                        );
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
