import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:intl/intl.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_bloc_events_states.dart';
import '../models/admin_models.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _range = 'monthly';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const _ranges = ['weekly', 'monthly', 'yearly', 'all'];
  static const _rangeLabels = ['Weekly', 'Monthly', 'Yearly', 'All-time'];

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const LoadAdminDashboard(range: 'monthly'));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadRange(String range) {
    setState(() => _range = range);
    context.read<AdminBloc>().add(LoadAdminDashboard(range: range));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: const Text('User Management')),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading || state is AdminInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is AdminError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Retry',
                    onPressed: () => _loadRange(_range),
                  ),
                ],
              ),
            );
          }

          if (state is AdminLoaded) {
            return _buildContent(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AdminLoaded state) {
    final filteredUsers = _searchQuery.isEmpty
        ? state.users
        : state.users.where((u) {
            final q = _searchQuery.toLowerCase();
            return u.name.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q);
          }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16,
        top: MediaQuery.paddingOf(context).top,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stat Cards ──
          _buildStatCards(state.stats),
          const SizedBox(height: 24),

          // ── Time Range Toggle ──
          Text('Registration Trend', style: AppTypography.headlineSmall),
          const SizedBox(height: 12),
          _buildRangeToggle(),
          const SizedBox(height: 16),

          // ── Bar Chart ──
          _buildBarChart(state.stats.chartPoints),
          const SizedBox(height: 28),

          // ── Search ──
          Text('User Details', style: AppTypography.headlineSmall),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or email…',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 12),

          // ── Data Table ──
          _buildUserTable(filteredUsers),
        ],
      ),
    );
  }

  // ── Stat cards ─────────────────────────────────────────────────
  Widget _buildStatCards(AdminStatsModel stats) {
    final mediaQuery = MediaQuery.of(context).size.width;
    final cards = [
      _StatCard(
        label: 'Total Users',
        value: stats.total,
        icon: Icons.people,
        color: AppColors.primary,
      ),
      _StatCard(
        label: 'This Week',
        value: stats.thisWeek,
        icon: Icons.date_range,
        color: AppColors.info,
      ),
      _StatCard(
        label: 'This Month',
        value: stats.thisMonth,
        icon: Icons.calendar_month,
        color: AppColors.success,
      ),
      _StatCard(
        label: 'This Year',
        value: stats.thisYear,
        icon: Icons.calendar_today,
        color: AppColors.warning,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: mediaQuery > 800
          ? 4
          : mediaQuery > 600
          ? 3
          : 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: cards.map((c) => _buildStatCard(c)).toList(),
    );
  }

  Widget _buildStatCard(_StatCard c) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(c.icon, color: c.color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  c.value.toString(),
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: c.color,
                  ),
                ),
                Text(c.label, style: AppTypography.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Range toggle ────────────────────────────────────────────────
  Widget _buildRangeToggle() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_ranges.length, (i) {
          final selected = _range == _ranges[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_rangeLabels[i]),
              selected: selected,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => _loadRange(_ranges[i]),
            ),
          );
        }),
      ),
    );
  }

  // ── Bar chart ───────────────────────────────────────────────────
  Widget _buildBarChart(List<ChartPoint> points) {
    if (points.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.withValues(alpha: 0.05),
        ),
        child: Text('No data for this period', style: AppTypography.bodyMedium),
      );
    }

    final maxY = points
        .map((p) => p.count)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < points.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: points[i].count.toDouble(),
              color: AppColors.primary,
              width: points.length <= 7 ? 24 : (points.length <= 12 ? 14 : 8),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY * 1.2,
                color: AppColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ],
        ),
      );
    }

    String label(ChartPoint p) {
      if (p.week != null) return 'W${p.week}';
      if (p.month != null) {
        return DateFormat('MMM').format(DateTime(p.year, p.month!));
      }
      return '${p.year}';
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.withValues(alpha: 0.04),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2 + 1,
          barGroups: barGroups,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
            getDrawingHorizontalLine: (v) => FlLine(
              color: Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, m) => v % 1 == 0
                    ? Text('${v.toInt()}', style: const TextStyle(fontSize: 10))
                    : const SizedBox.shrink(),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) {
                  final i = v.toInt();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label(points[i]),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final count = rod.toY.toInt();
                return BarTooltipItem(
                  '$count user${count == 1 ? '' : 's'}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── User data table ─────────────────────────────────────────────
  Widget _buildUserTable(List<AdminUserModel> users) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text('No users found', style: AppTypography.bodyMedium),
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            AppColors.primary.withValues(alpha: 0.1),
          ),
          dataRowMinHeight: 52,
          dataRowMaxHeight: 64,
          columnSpacing: 20,
          columns: const [
            DataColumn(
              label: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text(
                'Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Role',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Currency',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Joined',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: List.generate(users.length, (i) {
            final user = users[i];
            final isEven = i % 2 == 0;
            return DataRow(
              color: WidgetStateProperty.all(
                isEven
                    ? Colors.transparent
                    : AppColors.primary.withValues(alpha: 0.03),
              ),
              cells: [
                DataCell(Text('${i + 1}', style: AppTypography.bodySmall)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(user.name, style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
                DataCell(Text(user.email, style: AppTypography.bodySmall)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: user.role == 'admin'
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : AppColors.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: user.role == 'admin'
                            ? AppColors.warning
                            : AppColors.info,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(user.currency, style: AppTypography.bodySmall)),
                DataCell(
                  Text(
                    dateFormat.format(user.createdAt),
                    style: AppTypography.bodySmall,
                  ),
                ),
                DataCell(
                  user.role == 'admin'
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          tooltip: 'Delete user',
                          onPressed: () => _confirmDelete(context, user),
                        ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminUserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete "${user.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminBloc>().add(DeleteAdminUser(user.id));
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
