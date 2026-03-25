import 'package:design_system/design_system.dart';
import 'package:design_system/src/widgets/category_icon.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart';
import '../colors/app_colors.dart';

class IconPicker extends StatefulWidget {
  final String? initialIcon;
  final ValueChanged<String> onIconSelected;

  const IconPicker({
    super.key,
    this.initialIcon,
    required this.onIconSelected,
  });

  @override
  State<IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<IconPicker> with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late TabController _tabController;
  late List<String> _filteredIcons;
  late List<String> _filteredEmojis;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);
    _filteredIcons = IconHelper.icons.keys.toList();
    _filteredEmojis = IconHelper.emojis;
    _searchController.addListener(_filterItems);
  }

  void _filterItems() {
    setState(() {
      final query = _searchController.text;
      _filteredIcons = IconHelper.searchIcons(query);
      _filteredEmojis = IconHelper.searchEmojis(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Icons'),
              Tab(text: 'Emojis'),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGrid(_filteredIcons),
                _buildGrid(_filteredEmojis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<String> items) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final iconName = items[index];
        final isSelected = iconName == widget.initialIcon;

        return GestureDetector(
          onTap: () {
            widget.onIconSelected(iconName);
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            alignment: Alignment.center,
            child: CategoryIcon(
              icon: iconName,
              color: isSelected ? Colors.white : null,
              size: 24,
            ),
          ),
        );
      },
    );
  }
}

void showIconPicker(BuildContext context, {String? initialIcon, required ValueChanged<String> onIconSelected}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: IconPicker(
        initialIcon: initialIcon,
        onIconSelected: onIconSelected,
      ),
    ),
  );
}
