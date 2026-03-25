import 'package:flutter/material.dart';

class IconHelper {
  static const Map<String, IconData> icons = {
    'shopping_cart': Icons.shopping_cart,
    'restaurant': Icons.restaurant,
    'commute': Icons.commute,
    'home': Icons.home,
    'electrical_services': Icons.electrical_services,
    'water_drop': Icons.water_drop,
    'phone_iphone': Icons.phone_iphone,
    'wifi': Icons.wifi,
    'health_and_safety': Icons.health_and_safety,
    'school': Icons.school,
    'flight': Icons.flight,
    'hotel': Icons.hotel,
    'directions_car': Icons.directions_car,
    'directions_bus': Icons.directions_bus,
    'directions_bike': Icons.directions_bike,
    'movie': Icons.movie,
    'sports_esports': Icons.sports_esports,
    'fitness_center': Icons.fitness_center,
    'spa': Icons.spa,
    'local_grocery_store': Icons.local_grocery_store,
    'pets': Icons.pets,
    'child_care': Icons.child_care,
    'work': Icons.work,
    'attach_money': Icons.attach_money,
    'trending_up': Icons.trending_up,
    'payment': Icons.payment,
    'account_balance': Icons.account_balance,
    'savings': Icons.savings,
    'credit_card': Icons.credit_card,
    'receipt_long': Icons.receipt_long,
    'inventory': Icons.inventory,
    'construction': Icons.construction,
    'cleaning_services': Icons.cleaning_services,
    'local_shipping': Icons.local_shipping,
    'delivery_dining': Icons.delivery_dining,
    'fastfood': Icons.fastfood,
    'local_cafe': Icons.local_cafe,
    'cake': Icons.cake,
    'celebration': Icons.celebration,
    'checkroom': Icons.checkroom,
    'stroller': Icons.stroller,
    'toys': Icons.toys,
    'category': Icons.category,
    'help_outline': Icons.help_outline,
    'more_horiz': Icons.more_horiz,
    'person': Icons.person,
    'group': Icons.group,
    'public': Icons.public,
    'star': Icons.star,
    'favorite': Icons.favorite,
  };

  static const List<String> emojis = [
    '🍔', '🍕', '🌮', '🥗', '🍎', '🍺', '☕', '🚗', '🚲', '✈️', '🚆', '🚢',
    '🛍️', '👕', '🎁', '🎬', '🎮', '💡', '🏠', '🏢', '🏫', '🏥', '💊', '🔋',
    '📚', '💻', '📱', '💰', '📈', '💳', '🏧', '💸', '💼', '🛠️', '📦', '🚚',
    '🐶', '🐱', '🐹', '⚽', '🏀', '🎾', '🏋️', '🧘', '💆', '🔥', '⭐', '❤️',
  ];

  static bool isEmoji(String icon) {
    if (icon.isEmpty) return false;
    // Simple check for common emoji ranges or common emojis in our list
    return emojis.contains(icon) || icon.runes.length == 1 || (icon.runes.length > 1 && icon.runes.first > 0x1F000);
  }

  static IconData getIconByName(String name) {
    if (isEmoji(name)) return Icons.help_outline; // Default for display, but we'll handle emojis in CategoryIcon
    return icons[name] ?? Icons.help_outline;
  }

  static String getIconName(IconData icon) {
    return icons.entries
        .firstWhere((entry) => entry.value == icon, orElse: () => icons.entries.first)
        .key;
  }

  static List<String> searchIcons(String query) {
    if (query.isEmpty) return icons.keys.toList();
    final lowercaseQuery = query.toLowerCase();
    return icons.keys
        .where((name) => name.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  static List<String> searchEmojis(String query) {
    if (query.isEmpty) return emojis;
    // Emojis don't have descriptions here, but we can search if we had a map.
    // For now, just return all if query is short, or empty if it doesn't match common names (harder without names).
    return emojis;
  }
}
