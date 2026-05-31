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
      title: "Treatments",
      icon: Icons.healing,
      category: MenuCategory.core,
      routeName: '/treatments'),
  MenuItemModel(
      title: "Diseases",
      icon: Icons.sick_outlined,
      category: MenuCategory.core,
      routeName: '/diseases'),
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
      title: "Practitioners",
      icon: Icons.groups,
      category: MenuCategory.services,
      isAvailable: false,
      routeName: ''),
  MenuItemModel(
      title: "AI Chatbot",
      icon: Icons.smart_toy_outlined,
      category: MenuCategory.services,
      isAvailable: false,
      routeName: ''),
  MenuItemModel(
      title: "Knowledge",
      icon: Icons.psychology_alt,
      category: MenuCategory.insights,
      isAvailable: false,
      routeName: ''),
  MenuItemModel(
      title: "Innovation",
      icon: Icons.lightbulb_outline,
      category: MenuCategory.insights,
      isAvailable: false,
      routeName: ''),
];
