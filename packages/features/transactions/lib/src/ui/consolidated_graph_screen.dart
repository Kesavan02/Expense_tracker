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

enum ConsolidatedPeriod { day, days5, month, ytd, year, years5, max }

class ConsolidatedGraphScreen extends StatefulWidget {
  const ConsolidatedGraphScreen({super.key});

  @override
  State<ConsolidatedGraphScreen> createState() => _ConsolidatedGraphScreenState();
}

class _ConsolidatedGraphScreenState extends State<ConsolidatedGraphScreen> {
  ConsolidatedPeriod _selectedPeriod = ConsolidatedPeriod.month;
  
  double? _hoveredValue;
  DateTime? _hoveredDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Consolidated Growth')),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<TransactionsBloc, TransactionsState>(
          builder: (context, state) {
            if (state is TransactionsLoading || state is TransactionsInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TransactionsError) {
              return Center(child: Text(state.message));
            }

            if (state is TransactionsLoaded) {
              final transactions = List<TransactionModel>.from(state.transactions);
              if (transactions.isEmpty) {
                return const Center(child: Text('No data to analyze.'));
              }
              
              return BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  final currency = authState is AuthAuthenticated
                      ? authState.user.currency
                      : 'USD';
                      
                  return _buildContent(transactions, currency);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(List<TransactionModel> transactions, String currency) {
    // Process transactions
    // Sort chronologically
    transactions.sort((a, b) => a.date.compareTo(b.date));

    // Define the cutoff time based on the selected period
    final now = DateTime.now();
    DateTime cutoff;
    switch (_selectedPeriod) {
      case ConsolidatedPeriod.day:
        cutoff = now.subtract(const Duration(days: 1));
        break;
      case ConsolidatedPeriod.days5:
        cutoff = now.subtract(const Duration(days: 5));
        break;
      case ConsolidatedPeriod.month:
        cutoff = DateTime(now.year, now.month - 1, now.day);
        break;
      case ConsolidatedPeriod.ytd:
        cutoff = DateTime(now.year, 1, 1);
        break;
      case ConsolidatedPeriod.year:
        cutoff = DateTime(now.year - 1, now.month, now.day);
        break;
      case ConsolidatedPeriod.years5:
        cutoff = DateTime(now.year - 5, now.month, now.day);
        break;
      case ConsolidatedPeriod.max:
        cutoff = DateTime(2000); // long time ago
        break;
    }

    // Filter transactions (but we need the starting balance!)
    // We should compute the running total from the very beginning.
    double currentBalance = 0.0;
    List<Map<String, dynamic>> dataPoints = [];
    
    // In Robinhood style, we might want to have a continuous line. 
    // To do this, we compute the balance up to the cutoff first.
    
    // For start point:
    double startBalance = 0.0;
    bool pastCutoff = false;

    for (var tx in transactions) {
      final convertedAmount = CurrencyConverter.convert(tx.amount, 'USD', currency);
      if (tx.type == 'income') {
        currentBalance += convertedAmount;
      } else {
        currentBalance -= convertedAmount;
      }
      
      if (!tx.date.isBefore(cutoff)) {
        if (!pastCutoff) {
          pastCutoff = true;
          startBalance = currentBalance - (tx.type == 'income' ? convertedAmount : -convertedAmount);
          // Add a start point exactly at cutoff for continuity
        }
        dataPoints.add({
          'date': tx.date,
          'balance': currentBalance,
        });
      }
    }
    
    // If no points after the cutoff, just use the final balance as a single straight line
    if (dataPoints.isEmpty) {
      dataPoints = [
        {'date': cutoff, 'balance': currentBalance},
        {'date': now, 'balance': currentBalance},
      ];
    } else {
      // Ensure we start exactly at cutoff with the start balance for continuity
      if (dataPoints.first['date'].isAfter(cutoff)) {
        dataPoints.insert(0, {'date': cutoff, 'balance': startBalance});
      }
      // Ensure it ends at 'now'
      dataPoints.add({'date': now, 'balance': currentBalance});
    }

    final double displayValue = _hoveredValue ?? currentBalance;
    final DateTime displayDate = _hoveredDate ?? now;
    
    // Calculate if it's up or down for the selected period
    final firstBalance = dataPoints.first['balance'] as double;
    final isGain = currentBalance >= firstBalance;
    final lineColor = isGain ? AppColors.success : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${NumberFormat.compact().format(displayValue)} $currency',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM d, yyyy h:mm a').format(displayDate),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        // Chart container
        SizedBox(
          height: 250,
          child: _buildChart(dataPoints, lineColor),
        ),
        
        const SizedBox(height: 24),
        
        // Time Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: ConsolidatedPeriod.values.map((period) {
              final isSelected = _selectedPeriod == period;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(_getPeriodLabel(period)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPeriod = period;
                        _hoveredValue = null;
                        _hoveredDate = null;
                      });
                    }
                  },
                  backgroundColor: Colors.transparent,
                  selectedColor: Colors.white.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getPeriodLabel(ConsolidatedPeriod period) {
    switch (period) {
      case ConsolidatedPeriod.day: return '1D';
      case ConsolidatedPeriod.days5: return '5D';
      case ConsolidatedPeriod.month: return '1M';
      case ConsolidatedPeriod.ytd: return 'YTD';
      case ConsolidatedPeriod.year: return '1Y';
      case ConsolidatedPeriod.years5: return '5Y';
      case ConsolidatedPeriod.max: return 'Max';
    }
  }

  Widget _buildChart(List<Map<String, dynamic>> dataPoints, Color lineColor) {
    if (dataPoints.isEmpty) return const SizedBox.shrink();

    final minX = (dataPoints.first['date'] as DateTime).millisecondsSinceEpoch.toDouble();
    final maxX = (dataPoints.last['date'] as DateTime).millisecondsSinceEpoch.toDouble();
    
    double minY = dataPoints.map((e) => e['balance'] as double).reduce((a, b) => a < b ? a : b);
    double maxY = dataPoints.map((e) => e['balance'] as double).reduce((a, b) => a > b ? a : b);
    
    if (minY == maxY) {
      minY -= 100;
      maxY += 100;
    } else {
      final padding = (maxY - minY) * 0.1;
      minY -= padding;
      maxY += padding;
    }

    final spots = dataPoints.map((e) {
      return FlSpot(
        (e['date'] as DateTime).millisecondsSinceEpoch.toDouble(),
        e['balance'] as double,
      );
    }).toList();

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
             getTooltipColor: (_) => Colors.transparent,
             getTooltipItems: (touchedSpots) {
               return touchedSpots.map((spot) => const LineTooltipItem('', TextStyle())).toList();
             },
          ),
          touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
            if (event is FlLongPressEnd || event is FlPanEndEvent || event is FlTapUpEvent) {
               // Only reset if it's explicitly an end of a touch, otherwise keep showing the hovered value.
               // Actually, keeping the last hovered value might feel better on mobile. Let's reset on tap up out of bounds, but for now reset on end.
              setState(() {
                _hoveredValue = null;
                _hoveredDate = null;
              });
            } else if (touchResponse?.lineBarSpots != null && touchResponse!.lineBarSpots!.isNotEmpty) {
              final spot = touchResponse.lineBarSpots!.first;
              setState(() {
                _hoveredValue = spot.y;
                _hoveredDate = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
              });
            }
          },
          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(color: Colors.white.withValues(alpha: 0.5), strokeWidth: 1, dashArray: [3, 3]),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: lineColor,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
              );
            }).toList();
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false, // Straight lines usually look more stock-like
            color: lineColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  lineColor.withValues(alpha: 0.3),
                  lineColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
    );
  }
}
