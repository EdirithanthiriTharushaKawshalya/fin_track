import 'package:fin_track/features/dashboard/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../core/models/category_model.dart';

final categoryStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getCategories();
});

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _activeType = 'expense';

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color activeColor = _activeType == 'income'
        ? const Color(0xFF03DAC6)
        : const Color(0xFFCF6679);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Adaptive Ambient Glow
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withOpacity(isDark ? 0.05 : 0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildFloatingToggle(context, activeColor),
                const SizedBox(height: 16),
                Expanded(
                  child: categoriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFBB86FC))),
                    error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                    data: (allCategories) {
                      final filtered = allCategories.where((c) => c.type == _activeType).toList();
                      return _buildCategoryList(context, filtered, activeColor);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Configure', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Categories', style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFloatingToggle(BuildContext context, Color activeColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _togglePart(context, 'EXPENSES', 'expense', const Color(0xFFCF6679)),
          _togglePart(context, 'INCOME', 'income', const Color(0xFF03DAC6)),
        ],
      ),
    );
  }

  Widget _togglePart(BuildContext context, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _activeType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.black : (isDark ? Colors.white24 : Colors.black26),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, List<CategoryModel> categories, Color activeColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (categories.isEmpty) {
      return Center(child: Text("No ${_activeType} categories yet.", style: GoogleFonts.inter(color: isDark ? Colors.white10 : Colors.black12, fontSize: 14)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      itemCount: categories.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final cat = categories[index];
        return Dismissible(
          key: Key(cat.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(28)),
            child: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
          onDismissed: (_) => ref.read(firestoreServiceProvider).deleteCategory(cat.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  activeColor.withOpacity(isDark ? 0.12 : 0.08),
                  isDark ? const Color(0xFF121212) : Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: activeColor.withOpacity(isDark ? 0.08 : 0.2)),
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Color(cat.colorCode).withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(IconData(cat.iconCode, fontFamily: 'MaterialIcons'), color: Color(cat.colorCode), size: 22),
              ),
              title: Text(cat.name, style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 15)),
              trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      backgroundColor: const Color(0xFFBB86FC),
      shape: const StadiumBorder(),
      child: const Icon(Icons.add, color: Colors.black, size: 28),
      onPressed: () => _showAddCategoryDialog(context),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int selectedIcon = Icons.category.codePoint;
    final List<IconData> icons = [Icons.fastfood, Icons.directions_car, Icons.shopping_bag, Icons.home, Icons.medical_services, Icons.sports_esports, Icons.school, Icons.pets, Icons.work, Icons.monetization_on, Icons.flight, Icons.build];

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Text('New Category', style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      labelStyle: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black45, fontSize: 12),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFBB86FC))),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(alignment: Alignment.centerLeft, child: Text("Select Icon", style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: icons.map((icon) {
                      final isSelected = selectedIcon == icon.codePoint;
                      return GestureDetector(
                        onTap: () => setState(() => selectedIcon = icon.codePoint),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFBB86FC) : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black54), size: 20),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(child: Text('Discard', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38)), onPressed: () => Navigator.pop(context)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBB86FC), shape: const StadiumBorder()),
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty) {
                      ref.read(firestoreServiceProvider).addCategory(name: nameCtrl.text, type: _activeType, iconCode: selectedIcon, colorCode: _activeType == 'income' ? 0xFF03DAC6 : 0xFFCF6679);
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Create', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}