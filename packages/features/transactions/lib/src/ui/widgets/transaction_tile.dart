import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:intl/intl.dart';
import 'package:core/core.dart';
import 'package:auth/auth.dart';
import '../../models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectChanged;
  final VoidCallback? onLongPress;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectChanged,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    
    return ListTile(
      onTap: isSelectionMode ? () => onSelectChanged?.call(!isSelected) : onTap,
      onLongPress: onLongPress,
      leading: isSelectionMode
          ? Checkbox(
              value: isSelected,
              onChanged: onSelectChanged,
              activeColor: AppColors.primary,
            )
          : CircleAvatar(
              backgroundColor: _parseColor(transaction.category.color).withValues(alpha: 0.1),
              child: CategoryIcon(
                icon: transaction.category.icon,
                color: _parseColor(transaction.category.color),
                size: 20,
              ),
            ),
      title: Text(
        transaction.description.isNotEmpty 
            ? transaction.description 
            : transaction.category.name,
        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        DateFormat('MMM dd, yyyy').format(transaction.date.toLocal()),
        style: AppTypography.bodySmall,
      ),
      trailing: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final currency = authState is AuthAuthenticated 
              ? authState.user.currency 
              : 'USD';
          
          return Text(
            '${isIncome ? '+' : '-'}${CurrencyFormatter.format(CurrencyConverter.convert(transaction.amount, 'USD', currency), currency: currency)}',
            style: AppTypography.bodyLarge.copyWith(
              color: isIncome ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
