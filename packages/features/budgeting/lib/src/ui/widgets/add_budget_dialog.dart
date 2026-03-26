import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:transactions/transactions.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import '../../bloc/budget_bloc.dart';
import '../../bloc/budget_event.dart';
import '../../models/budget_model.dart';

class AddBudgetDialog extends StatefulWidget {
  const AddBudgetDialog({super.key});

  @override
  State<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<AddBudgetDialog> {
  final _amountController = TextEditingController();
  CategoryModel? _selectedCategory;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final currency = authState is AuthAuthenticated ? authState.user.currency : 'USD';
        final symbol = CurrencyFormatter.getSymbol(currency);

        return BlocBuilder<TransactionsBloc, TransactionsState>(
          builder: (context, state) {
            final categories = state is TransactionsLoaded
                ? state.categories.where((c) => c.type == 'expense').toList()
                : <CategoryModel>[];

            return AlertDialog(
              title: const Text('Create Budget'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<CategoryModel>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              CategoryIcon(
                                icon: cat.icon,
                                size: 20,
                                color: Color(
                                  int.parse(cat.color.replaceFirst('#', '0xFF')),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(cat.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '$symbol ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(
                        '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                    ),
                    ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(
                        '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) setState(() => _endDate = date);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedCategory == null || _amountController.text.isEmpty) {
                      return;
                    }

                    // Convert the entered amount from user's currency back to USD for storage
                    final enteredAmount = double.parse(_amountController.text);
                    final amountInUSD = CurrencyConverter.convert(
                      enteredAmount,
                      currency,
                      'USD',
                    );

                    final budget = BudgetModel(
                      id: '', // Backend generates ID
                      category: _selectedCategory!,
                      amount: amountInUSD,
                      startDate: _startDate,
                      endDate: _endDate,
                    );

                    context.read<BudgetBloc>().add(AddBudget(budget));
                    Navigator.pop(context);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
