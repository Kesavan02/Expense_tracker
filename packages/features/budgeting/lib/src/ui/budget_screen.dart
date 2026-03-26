import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:transactions/transactions.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import '../bloc/budget_bloc.dart';

import '../bloc/budget_state.dart';
import '../models/budget_model.dart';
import 'widgets/add_budget_dialog.dart';

class BudgetOverviewScreen extends StatelessWidget {
  const BudgetOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Budgets')),
      body: MultiBlocListener(
        listeners: [
          BlocListener<BudgetBloc, BudgetState>(
            listener: (context, state) {
              if (state is BudgetError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final currency = authState is AuthAuthenticated ? authState.user.currency : 'USD';
            
            return BlocBuilder<BudgetBloc, BudgetState>(
              builder: (context, budgetState) {
                return BlocBuilder<TransactionsBloc, TransactionsState>(
                  builder: (context, txState) {

                if (budgetState is BudgetLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (budgetState is BudgetLoaded) {
                  final budgets = budgetState.budgets;
                  if (budgets.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.builder(
                    padding: EdgeInsets.only(
                      top: MediaQuery.paddingOf(context).top + 24,
                      left: 16,
                      right: 16,
                      bottom: 100,
                    ),
                    itemCount: budgets.length,
                    itemBuilder: (context, index) {
                      final budget = budgets[index];
                      final spent = _calculateSpent(budget, txState);
                      return _buildBudgetCard(context, budget, spent, currency);
                    },
                  );
                }


                return const Center(child: Text('Failed to load budgets.'));
              },
            );
          },
        );}
      ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  double _calculateSpent(BudgetModel budget, TransactionsState txState) {
    if (txState is! TransactionsLoaded) return 0;
    
    return txState.transactions
        .where((tx) => 
            tx.category.id == budget.category.id &&
            tx.date.isAfter(budget.startDate.subtract(const Duration(seconds: 1))) &&
            tx.date.isBefore(budget.endDate.add(const Duration(seconds: 1))))
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'No budgets set yet',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a budget to track your spending limits.',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.grey.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, BudgetModel budget, double spent, String currency) {
    final amountInCurrency = CurrencyConverter.convert(budget.amount, 'USD', currency);
    final spentInCurrency = CurrencyConverter.convert(spent, 'USD', currency);
    
    final percent = (spent / budget.amount).clamp(0.0, 1.0);
    final isOver = spent > budget.amount;
    final color = Color(int.parse(budget.category.color.replaceFirst('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withAlpha(25),
                  child: CategoryIcon(icon: budget.category.icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.category.name,
                        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${CurrencyFormatter.format(spentInCurrency, currency: currency)} / ${CurrencyFormatter.format(amountInCurrency, currency: currency)} spent',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isOver)
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                backgroundColor: Colors.grey.withAlpha(25),
                color: isOver ? AppColors.error : color,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(percent * 100).toInt()}% used',
                  style: AppTypography.bodySmall.copyWith(
                    color: isOver ? AppColors.error : null,
                    fontWeight: isOver ? FontWeight.bold : null,
                  ),
                ),
                Text(
                  'Ends ${budget.endDate.day}/${budget.endDate.month}',
                  style: AppTypography.bodySmall.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  void _showAddBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<BudgetBloc>()),
          BlocProvider.value(value: context.read<TransactionsBloc>()),
          BlocProvider.value(value: context.read<AuthBloc>()),
        ],
        child: const AddBudgetDialog(),
      ),
    );
  }
}
