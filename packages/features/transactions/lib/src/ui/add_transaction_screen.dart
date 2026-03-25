import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:intl/intl.dart';
import 'package:core/core.dart';
import 'package:auth/auth.dart';
import '../bloc/transactions_bloc.dart';
import '../bloc/transactions_event.dart';
import '../bloc/transactions_state.dart';
import '../models/category_model.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'expense';
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _showCategoryError = false;

  @override
  void initState() {
    super.initState();
    context.read<TransactionsBloc>().add(LoadCategories());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Add Transaction')),
      body: BlocConsumer<TransactionsBloc, TransactionsState>(
        listener: (context, state) {
          if (state is TransactionsError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final categories = state is TransactionsLoaded
              ? state.categories.where((c) => c.type == _type).toList()
              : <CategoryModel>[];

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
                top: MediaQuery.paddingOf(context).top + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTypeToggle(),
                  const SizedBox(height: 24),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, authState) {
                      final currency = authState is AuthAuthenticated
                          ? authState.user.currency
                          : 'USD';
                      final symbol = CurrencyFormatter.getSymbol(currency);

                      return AppTextField(
                        label: 'Amount',
                        controller: _amountController,
                        hintText: '0.00',
                        keyboardType: TextInputType.number,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Text(
                            symbol,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter amount';
                          }
                          final numValue = double.tryParse(value);
                          if (numValue == null) return 'Invalid number';
                          if (numValue <= 0) return 'Amount must be > 0';
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCategorySelector(categories),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Description',
                    controller: _descriptionController,
                    hintText: 'What was this for?',
                    prefixIcon: const Icon(Icons.description),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDatePicker(),
                  const SizedBox(height: 32),
                  AppButton(label: 'Save Transaction', onPressed: _submitForm),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeToggle() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'expense',
          label: Text('Expense'),
          icon: Icon(Icons.remove_circle_outline),
        ),
        ButtonSegment(
          value: 'income',
          label: Text('Income'),
          icon: Icon(Icons.add_circle_outline),
        ),
      ],
      selected: {_type},
      onSelectionChanged: (newSelection) {
        setState(() {
          _type = newSelection.first;
          _selectedCategory = null; // Clear category when type changes
          _showCategoryError = false;
        });
      },
    );
  }

  Widget _buildCategorySelector(List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return Text(
        'No categories available for this type.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.error),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: AppTypography.bodySmall),
        const SizedBox(height: 12),
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = _selectedCategory?.id == category.id;
            final color = _parseColor(category.color);

            return InkWell(
              onTap: () => setState(() {
                _selectedCategory = category;
                _showCategoryError = false;
              }),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : Colors.grey.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        category.icon.isNotEmpty ? category.icon : '💰',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        category.name,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 11,
                          color: isSelected ? color : null,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_showCategoryError)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Please select a category',
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date', style: AppTypography.bodySmall),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              prefixIcon: const Icon(Icons.calendar_today),
            ),
            child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
          ),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        setState(() => _showCategoryError = true);
        return;
      }
      setState(() => _showCategoryError = false);

      final authState = context.read<AuthBloc>().state;
      String currency = 'USD';
      if (authState is AuthAuthenticated) {
        currency = authState.user.currency;
      }

      final amountInLocal = double.parse(_amountController.text);
      final amountInUSD = CurrencyConverter.convert(
        amountInLocal,
        currency,
        'USD',
      );

      context.read<TransactionsBloc>().add(
        AddTransactionRequested(
          amount: amountInUSD,
          type: _type,
          category: _selectedCategory!,
          description: _descriptionController.text.trim(),
          date: _selectedDate,
        ),
      );

      Navigator.of(context).pop();
    }
  }
}
