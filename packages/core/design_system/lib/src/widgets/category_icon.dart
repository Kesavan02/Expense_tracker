import 'package:flutter/material.dart';
import 'package:core/core.dart';

class CategoryIcon extends StatelessWidget {
  final String icon;
  final Color? color;
  final double? size;

  const CategoryIcon({
    super.key,
    required this.icon,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (IconHelper.isEmoji(icon)) {
      return Text(
        icon,
        style: TextStyle(
          fontSize: size ?? 24,
        ),
      );
    }

    return Icon(
      IconHelper.getIconByName(icon),
      color: color,
      size: size,
    );
  }
}
