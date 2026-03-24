import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:transactions/transactions.dart';
import 'widgets/transaction_tile.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<TransactionsBloc>().add(LoadTransactions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _isSelectionMode
          ? GlassAppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  });
                },
              ),
              title: Text('${_selectedIds.length} Selected'),
              actions: [
                BlocBuilder<TransactionsBloc, TransactionsState>(
                  builder: (context, state) {
                    if (state is TransactionsLoaded) {
                      final allSelected =
                          _selectedIds.length == state.transactions.length &&
                          state.transactions.isNotEmpty;
                      return IconButton(
                        icon: Icon(
                          allSelected ? Icons.deselect : Icons.select_all,
                        ),
                        tooltip: allSelected ? 'Deselect All' : 'Select All',
                        onPressed: () {
                          setState(() {
                            if (allSelected) {
                              _selectedIds.clear();
                              _isSelectionMode = false;
                            } else {
                              _selectedIds.addAll(
                                state.transactions.map((t) => t.id),
                              );
                            }
                          });
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                if (_selectedIds.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    tooltip: 'Delete Selected',
                    onPressed: () {
                      context.read<TransactionsBloc>().add(
                        DeleteTransactionsRequested(_selectedIds.toList()),
                      );
                      setState(() {
                        _isSelectionMode = false;
                        _selectedIds.clear();
                      });
                    },
                  ),
              ],
            )
          : GlassAppBar(
              title: const Text('Transactions'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.analytics_outlined),
                  tooltip: 'View Analytics Data',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AnalysisScreen()),
                    );
                  },
                ),
                // IconButton(
                //   icon: const Icon(Icons.refresh),
                //   onPressed: () => context.read<TransactionsBloc>().add(
                //     const LoadTransactions(),
                //   ),
                // ),
                // IconButton(
                //   icon: const Icon(Icons.person),
                //   onPressed: () {
                //     Navigator.of(context).push(
                //       MaterialPageRoute(builder: (_) => const ProfileScreen()),
                //     );
                //   },
                // ),
                // IconButton(
                //   icon: const Icon(Icons.logout),
                //   onPressed: () {
                //     context.read<AuthBloc>().add(AuthLogoutRequested());
                //   },
                // ),
              ],
            ),
      body: RefreshIndicator(
        onRefresh: () async =>
            context.read<TransactionsBloc>().add(const LoadTransactions()),
        child: BlocBuilder<TransactionsBloc, TransactionsState>(
          builder: (context, state) {
            if (state is TransactionsInitial || state is TransactionsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TransactionsError) {
              return Center(child: Text(state.message));
            }

            if (state is TransactionsLoaded) {
              final allTransactions = state.transactions;
              final transactions = _searchQuery.isEmpty
                  ? allTransactions
                  : allTransactions.where((tx) {
                      final noteMatch = tx.description.toLowerCase().contains(
                        _searchQuery,
                      );
                      final yearMatch = tx.date
                          .toLocal()
                          .year
                          .toString()
                          .contains(_searchQuery);
                      return noteMatch || yearMatch;
                    }).toList();

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        bottom: 16.0,
                        top: MediaQuery.paddingOf(context).top + 10,
                      ),
                      child: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, authState) {
                          final currency = authState is AuthAuthenticated
                              ? authState.user.currency
                              : 'USD';
                          return _buildSummaryCard(state, currency);
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: AppTextField(
                        controller: _searchController,
                        hintText: 'Search by year or notes...',
                        prefixIcon: const Icon(Icons.search),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim().toLowerCase();
                          });
                        },
                        label: '',
                      ),
                    ),
                  ),
                  if (transactions.isEmpty)
                    const SliverFillRemaining(
                      child: Center(child: Text('No transactions yet.')),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final tx = transactions[index];
                        return TransactionTile(
                          transaction: tx,
                          isSelectionMode: _isSelectionMode,
                          isSelected: _selectedIds.contains(tx.id),
                          onTap: () {
                            if (!_isSelectionMode) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TransactionDetailsScreen(transaction: tx),
                                ),
                              );
                            } else {
                              setState(() {
                                if (_selectedIds.contains(tx.id)) {
                                  _selectedIds.remove(tx.id);
                                  if (_selectedIds.isEmpty) {
                                    _isSelectionMode = false;
                                  }
                                } else {
                                  _selectedIds.add(tx.id);
                                }
                              });
                            }
                          },
                          onSelectChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedIds.add(tx.id);
                              } else {
                                _selectedIds.remove(tx.id);
                                if (_selectedIds.isEmpty) {
                                  _isSelectionMode = false;
                                }
                              }
                            });
                          },
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              setState(() {
                                _isSelectionMode = true;
                                _selectedIds.add(tx.id);
                              });
                            }
                          },
                        );
                      }, childCount: transactions.length),
                    ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildSummaryCard(TransactionsLoaded state, String currency) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Total Balance', style: AppTypography.bodyMedium),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(
                CurrencyConverter.convert(state.balance, 'USD', currency),
                currency: currency,
              ),
              style: AppTypography.headlineLarge.copyWith(
                color: state.balance >= 0 ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Income',
                  CurrencyConverter.convert(state.totalIncome, 'USD', currency),
                  AppColors.success,
                  Icons.arrow_upward,
                  currency,
                ),
                _buildSummaryItem(
                  'Expenses',
                  CurrencyConverter.convert(
                    state.totalExpenses,
                    'USD',
                    currency,
                  ),
                  AppColors.error,
                  Icons.arrow_downward,
                  currency,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double amount,
    Color color,
    IconData icon,
    String currency,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(amount, currency: currency),
          style: AppTypography.bodyLarge.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
