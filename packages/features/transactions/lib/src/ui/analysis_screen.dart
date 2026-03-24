import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:core/core.dart';
import 'package:auth/auth.dart';
import '../bloc/transactions_bloc.dart';
import '../bloc/transactions_state.dart';
import '../models/transaction_model.dart';
import 'consolidated_graph_screen.dart';
import 'dart:math' as math;

enum AnalysisPeriod { weekly, monthly, yearly }

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  AnalysisPeriod _selectedPeriod = AnalysisPeriod.yearly;
  int? _selectedYear;
  int _drilledMonth = DateTime.now().month;
  int _drilledWeek = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text('Financial Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'Consolidated Growth',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ConsolidatedGraphScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<TransactionsBloc, TransactionsState>(
                builder: (context, state) {
                  if (state is TransactionsLoading ||
                      state is TransactionsInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is TransactionsError) {
                    return Center(child: Text(state.message));
                  }

                  if (state is TransactionsLoaded) {
                    final transactions = state.transactions;
                    if (transactions.isEmpty) {
                      return const Center(child: Text('No data to analyze.'));
                    }

                    // Calculate available years
                    final availableYears =
                        transactions
                            .map((tx) => tx.date.toLocal().year)
                            .toSet()
                            .toList()
                          ..sort();

                    if ((_selectedYear == null ||
                            !availableYears.contains(_selectedYear)) &&
                        availableYears.isNotEmpty) {
                      _selectedYear = availableYears.last;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (availableYears.isNotEmpty)
                          _buildNavigationBar(availableYears),
                        Expanded(
                          child: BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, authState) {
                              final currency = authState is AuthAuthenticated
                                  ? authState.user.currency
                                  : 'USD';
                              return _buildChart(transactions, currency);
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar(List<int> availableYears) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.05);


    // Breadcrumb label
    final String breadcrumb;
    final VoidCallback? onBack;
    if (_selectedPeriod == AnalysisPeriod.weekly) {
      breadcrumb =
          '$_selectedYear  ›  ${DateFormat.MMMM().format(DateTime(_selectedYear!, _drilledMonth))}  ›  Week $_drilledWeek';
      onBack = () => setState(() => _selectedPeriod = AnalysisPeriod.monthly);
    } else if (_selectedPeriod == AnalysisPeriod.monthly) {
      breadcrumb =
          '$_selectedYear  ›  ${DateFormat.MMMM().format(DateTime(_selectedYear!, _drilledMonth))}';
      onBack = () => setState(() => _selectedPeriod = AnalysisPeriod.yearly);
    } else {
      breadcrumb = '$_selectedYear';
      onBack = null;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // ── Back button (only when drilled in) ──
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: onBack != null
                ? GestureDetector(
                    key: const ValueKey('back'),
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : const SizedBox(key: ValueKey('no-back'), width: 0),
          ),

          // ── Breadcrumb path ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                breadcrumb,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // ── Year dropdown (handles any number of years) ──
          Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedYear,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  isDense: true,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  dropdownColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E2235)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  items: availableYears.map((year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(
                        year.toString(),
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: year == _selectedYear
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: year == _selectedYear
                              ? AppColors.primary
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedYear = val;
                        _selectedPeriod = AnalysisPeriod.yearly;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildChart(List<TransactionModel> transactions, String currency) {
    final groupedData = _groupTransactions(transactions, currency);

    if (groupedData.isEmpty) {
      return const Center(child: Text('No data for this period.'));
    }

    // Find max value to set Y-axis limit
    double maxY = 0;
    for (final dayData in groupedData.values) {
      final income = dayData['income'] ?? 0.0;
      final expense = dayData['expense'] ?? 0.0;
      maxY = math.max(maxY, math.max(income, expense));
    }

    if (maxY == 0) {
      maxY = 100; // default scale if all 0
    }

    // Give 20% breathing room at top
    maxY = maxY * 1.2;

    final barGroups = <BarChartGroupData>[];
    final titles = groupedData.keys.toList();

    for (int i = 0; i < titles.length; i++) {
      final title = titles[i];
      final income =
          groupedData[title]!['income']?.toDouble().roundToDouble() ?? 0.0;
      final expense =
          groupedData[title]!['expense']?.toDouble().roundToDouble() ?? 0.0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: income,
              color: AppColors.success,
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: expense,
              color: AppColors.error,
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 8.0,
        right: 24.0,
        bottom: 24.0,
        top: 16.0,
      ),
      child: Column(
        children: [
          _buildLegend(),
          const SizedBox(height: 32),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: barGroups,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Theme.of(context).cardColor,
                  ),
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.spot == null) {
                      return;
                    }
                    if (event is FlTapUpEvent) {
                      final index = response.spot!.touchedBarGroupIndex;
                      if (_selectedPeriod == AnalysisPeriod.yearly) {
                        final income =
                            groupedData.values.elementAt(index)['income'] ?? 0;
                        final expense =
                            groupedData.values.elementAt(index)['expense'] ?? 0;
                        if (income > 0 || expense > 0) {
                          setState(() {
                            _selectedPeriod = AnalysisPeriod.monthly;
                            _drilledMonth = index + 1;
                          });
                        }
                      } else if (_selectedPeriod == AnalysisPeriod.monthly) {
                        final income =
                            groupedData.values.elementAt(index)['income'] ?? 0;
                        final expense =
                            groupedData.values.elementAt(index)['expense'] ?? 0;
                        if (income > 0 || expense > 0) {
                          setState(() {
                            _selectedPeriod = AnalysisPeriod.weekly;
                            _drilledWeek = index + 1;
                          });
                        }
                      }
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < titles.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              titles[value.toInt()],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            _formatCompactCurrency(value, currency),
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.2),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Income', AppColors.success),
        const SizedBox(width: 24),
        _buildLegendItem('Expense', AppColors.error),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatCompactCurrency(double amount, String currencyCode) {
    if (amount >= 1000) {
      return '${NumberFormat.compact().format(amount)} $currencyCode';
    }
    return '${amount.toInt()} $currencyCode';
  }

  Map<String, Map<String, double>> _groupTransactions(
    List<TransactionModel> transactions,
    String currency,
  ) {
    final groupedData = <String, Map<String, double>>{};
    final now = DateTime.now();
    final targetYear = _selectedYear ?? now.year;
    final targetMonth = _selectedPeriod != AnalysisPeriod.yearly
        ? _drilledMonth
        : now.month;

    if (_selectedPeriod == AnalysisPeriod.weekly) {
      // Show days for the specific week of the month
      final firstDayOfMonth = DateTime(targetYear, targetMonth, 1);
      final firstDayOfWeek = firstDayOfMonth.add(
        Duration(days: (_drilledWeek - 1) * 7),
      );

      for (int i = 0; i < 7; i++) {
        final date = firstDayOfWeek.add(Duration(days: i));
        // Ensure we don't spill into the next month if week 5
        if (date.month != targetMonth) break;
        final dayStr = DateFormat('MMM d').format(date);
        groupedData[dayStr] = {'income': 0.0, 'expense': 0.0};
      }

      for (var tx in transactions) {
        final localDate = tx.date.toLocal();
        if (localDate.year == targetYear && localDate.month == targetMonth) {
          int weekNum = ((localDate.day - 1) / 7).floor() + 1;
          if (weekNum > 5) weekNum = 5;
          if (weekNum == _drilledWeek) {
            final dayStr = DateFormat('MMM d').format(localDate);
            if (groupedData.containsKey(dayStr)) {
              final convertedAmount = CurrencyConverter.convert(
                tx.amount,
                'USD',
                currency,
              );
              groupedData[dayStr]![tx.type] =
                  (groupedData[dayStr]![tx.type] ?? 0) + convertedAmount;
            }
          }
        }
      }
    } else if (_selectedPeriod == AnalysisPeriod.monthly) {
      // Weeks of the selected month
      groupedData['Week 1'] = {'income': 0.0, 'expense': 0.0};
      groupedData['Week 2'] = {'income': 0.0, 'expense': 0.0};
      groupedData['Week 3'] = {'income': 0.0, 'expense': 0.0};
      groupedData['Week 4'] = {'income': 0.0, 'expense': 0.0};
      groupedData['Week 5'] = {'income': 0.0, 'expense': 0.0};

      for (var tx in transactions) {
        final localDate = tx.date.toLocal();
        if (localDate.year == targetYear && localDate.month == targetMonth) {
          int weekNum = ((localDate.day - 1) / 7).floor() + 1;
          if (weekNum > 5) weekNum = 5;
          final weekStr = 'Week $weekNum';
          final convertedAmount = CurrencyConverter.convert(
            tx.amount,
            'USD',
            currency,
          );
          groupedData[weekStr]![tx.type] =
              (groupedData[weekStr]![tx.type] ?? 0) + convertedAmount;
        }
      }
    } else {
      // 12 Months of the current year
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      for (var m in months) {
        groupedData[m] = {'income': 0.0, 'expense': 0.0};
      }

      for (var tx in transactions) {
        final localDate = tx.date.toLocal();
        if (localDate.year == targetYear) {
          final monthStr = DateFormat('MMM').format(localDate);
          final convertedAmount = CurrencyConverter.convert(
            tx.amount,
            'USD',
            currency,
          );
          groupedData[monthStr]![tx.type] =
              (groupedData[monthStr]![tx.type] ?? 0) + convertedAmount;
        }
      }
    }

    return groupedData;
  }
}
