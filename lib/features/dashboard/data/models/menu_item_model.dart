import 'package:flutter/material.dart';

enum MenuCategory { all, core, services, insights }

class MenuItemModel {
  final String title;
  final IconData icon;
  final MenuCategory category;
  final bool isAvailable;
  final String routeName;

  const MenuItemModel({
    required this.title,
    required this.icon,
    required this.category,
    this.isAvailable = true,
    required this.routeName,
  });
}

// Static dataset definitions matching your system's capabilities
const List<MenuItemModel> zimHerbalMenuItems = [
  MenuItemModel(
      title: "Herbs",
      icon: Icons.local_florist,
      category: MenuCategory.core,
      routeName: '/herbs'),
  MenuItemModel(
      title: "Remedies",
      icon: Icons.healing,
      category: MenuCategory.core,
      routeName: '/remedies'),
  MenuItemModel(
      title: "Conditions",
      icon: Icons.sick_outlined,
      category: MenuCategory.core,
      routeName: '/conditions'),
  MenuItemModel(
      title: "Herbal Store",
      icon: Icons.storefront_outlined,
      category: MenuCategory.services,
      routeName: '/store'),
  MenuItemModel(
      title: "Telemedicine",
      icon: Icons.medical_services_outlined,
      category: MenuCategory.services,
      routeName: '/telemed'),
  MenuItemModel(
      title: "Contributions",
      icon: Icons.volunteer_activism_outlined,
      category: MenuCategory.services,
      isAvailable: true,
      routeName: '/contributions'),
  MenuItemModel(
      title: "AI Chatbot",
      icon: Icons.smart_toy_outlined,
      category: MenuCategory.services,
      isAvailable: false,
      routeName: ''),
];
