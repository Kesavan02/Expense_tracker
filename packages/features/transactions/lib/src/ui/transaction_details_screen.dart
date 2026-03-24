import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:intl/intl.dart';
import 'package:core/core.dart';
import 'package:auth/auth.dart';
import '../models/transaction_model.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailsScreen({super.key, required this.transaction});

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final categoryColor = _parseColor(transaction.category.color);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Transaction Details')),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          bottom: 24.0,
          top: MediaQuery.paddingOf(context).top + kToolbarHeight + 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Hero Graphic
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    transaction.category.icon.isNotEmpty
                        ? transaction.category.icon
                        : '💰',
                    style: TextStyle(fontSize: 48, color: categoryColor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Amount Display
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final currency = authState is AuthAuthenticated
                    ? authState.user.currency
                    : 'USD';

                final formattedAmount = CurrencyFormatter.format(
                  CurrencyConverter.convert(
                    transaction.amount,
                    'USD',
                    currency,
                  ),
                  currency: currency,
                );

                return Text(
                  '${isIncome ? '+' : '-'}$formattedAmount',
                  textAlign: TextAlign.center,
                  style: AppTypography.displaySmall.copyWith(
                    color: isIncome ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Category Title
            Text(
              transaction.category.name,
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textLightMuted,
              ),
            ),
            const SizedBox(height: 32),

            // Details Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Date'),
                      trailing: Text(
                        DateFormat(
                          'MMMM dd, yyyy',
                        ).format(transaction.date.toLocal()),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.swap_vert_outlined),
                      title: const Text('Transaction Type'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isIncome
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isIncome ? 'Income' : 'Expense',
                          style: TextStyle(
                            color: isIncome
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (transaction.description.isNotEmpty) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notes_outlined),
                        title: const Text('Note'),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            transaction.description,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
