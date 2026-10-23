import 'package:camion/features/home/data/models/categories_model/get_categories_model.dart';
import 'package:camion/features/home/presentation/screens/category_screen.dart';
import 'package:flutter/material.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key, required this.categories});

  final List<GeTCategoriesModel> categories;

  @override
  Widget build(BuildContext context) {
    return const CategoryScreen(showBackButton: true);
  }
}
