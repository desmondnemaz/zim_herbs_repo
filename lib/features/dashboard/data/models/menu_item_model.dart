import 'package:flutter/material.dart';

enum MenuCategory { all, core, services, insights }

class MenuItemModel {
  final String title;
  final IconData icon;
  final MenuCategory category;
  final bool isAvailable;
  final String? badgeText;
  final String routeName;

  const MenuItemModel({
    required this.title,
    required this.icon,
    required this.category,
    this.isAvailable = true,
    this.badgeText,
    required this.routeName,
  });
}

// Static dataset definitions matching your system's capabilities
const List<MenuItemModel> zimHerbalMenuItems = [
  MenuItemModel(
      title: "Herbs",
      icon: Icons.local_florist_rounded,
      category: MenuCategory.core,
      routeName: '/herbs'),
  MenuItemModel(
      title: "Remedies",
      icon: Icons.healing_rounded,
      category: MenuCategory.core,
      routeName: '/remedies'),
  MenuItemModel(
      title: "Ailments",
      icon: Icons.monitor_heart_rounded,
      category: MenuCategory.core,
      routeName: '/ailments'),
  MenuItemModel(
      title: "Herbal Store",
      icon: Icons.storefront_rounded,
      category: MenuCategory.services,
      badgeText: "SOON",
      routeName: '/store'),
  MenuItemModel(
      title: "Telemedicine",
      icon: Icons.medical_services_rounded,
      category: MenuCategory.services,
      badgeText: "SOON",
      routeName: '/telemed'),
  MenuItemModel(
      title: "Contributions",
      icon: Icons.volunteer_activism_rounded,
      category: MenuCategory.services,
      isAvailable: true,
      routeName: '/contributions'),
  MenuItemModel(
      title: "AI Chatbot",
      icon: Icons.smart_toy_rounded,
      category: MenuCategory.services,
      isAvailable: false,
      badgeText: "SOON",
      routeName: ''),
];
