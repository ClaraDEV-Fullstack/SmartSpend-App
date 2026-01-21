// lib/screens/categories/category_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedType = 'expense';
  String _selectedColor = '#FF6B6B';
  String _selectedIcon = 'category';

  final List<Map<String, dynamic>> _categoryTypes = [
    {'value': 'expense', 'label': 'Expense'},
    {'value': 'income', 'label': 'Income'},
  ];

  final List<Map<String, dynamic>> _categoryColors = [
    {'value': '#FF6B6B', 'color': Color(0xFFFF6B6B)},
    {'value': '#4ECDC4', 'color': Color(0xFF4ECDC4)},
    {'value': '#45B7D1', 'color': Color(0xFF45B7D1)},
    {'value': '#96CEB4', 'color': Color(0xFF96CEB4)},
    {'value': '#FFEAA7', 'color': Color(0xFFFFEAA7)},
    {'value': '#DDA0DD', 'color': Color(0xFFDDA0DD)},
    {'value': '#98D8C8', 'color': Color(0xFF98D8C8)},
    {'value': '#F7DC6F', 'color': Color(0xFFF7DC6F)},
  ];

  final List<Map<String, dynamic>> _categoryIcons = [
    {'value': 'fastfood', 'icon': Icons.fastfood},
    {'value': 'directions_car', 'icon': Icons.directions_car},
    {'value': 'attach_money', 'icon': Icons.attach_money},
    {'value': 'bolt', 'icon': Icons.bolt},
    {'value': 'movie', 'icon': Icons.movie},
    {'value': 'shopping_cart', 'icon': Icons.shopping_cart},
    {'value': 'home', 'icon': Icons.home},
    {'value': 'medical_services', 'icon': Icons.medical_services},
    {'value': 'school', 'icon': Icons.school},
    {'value': 'flight', 'icon': Icons.flight},
    {'value': 'sports_soccer', 'icon': Icons.sports_soccer},
    {'value': 'pets', 'icon': Icons.pets},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedType = widget.category!.type;
      _selectedColor = widget.category!.color;
      _selectedIcon = widget.category!.icon;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Type field
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Category Type',
                  border: OutlineInputBorder(),
                ),
                items: _categoryTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['value'],
                    child: Text(type['label']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Color field
              const Text(
                'Select Color',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categoryColors.length,
                  itemBuilder: (context, index) {
                    final colorData = _categoryColors[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = colorData['value'];
                        });
                      },
                      child: Container(
                        width: 50,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: colorData['color'],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == colorData['value']
                                ? Colors.black
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Icon field
              const Text(
                'Select Icon',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _categoryIcons.length,
                  itemBuilder: (context, index) {
                    final iconData = _categoryIcons[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIcon = iconData['value'];
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedIcon == iconData['value']
                              ? Colors.grey[200]
                              : null,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedIcon == iconData['value']
                                ? Colors.blue
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          iconData['icon'],
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(widget.category == null ? 'Add Category' : 'Update Category'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

      final category = Category(
        id: widget.category?.id ?? 0,
        name: _nameController.text,
        type: _selectedType,
        color: _selectedColor,
        icon: _selectedIcon,
      );

      try {
        if (widget.category == null) {
          await categoryProvider.addCategory(category);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category added successfully')),
          );
        } else {
          await categoryProvider.updateCategory(category);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category updated successfully')),
          );
        }
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}