import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:auth/auth.dart' hide sl;
import 'package:local_storage/local_storage.dart';
import 'package:transactions/transactions.dart' hide sl;
import 'package:budgeting/budgeting.dart' hide sl;
import 'package:profile_settings/profile_settings.dart';
import 'package:core/core.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  final hiveService = HiveService();
  await hiveService.init();

  // Register TypeAdapters
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(BudgetModelAdapter());

  // Initialize all dependencies across all packages
  await di.initDependencies();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => di.sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider(create: (context) => di.sl<TransactionsBloc>()),
        BlocProvider(create: (context) => di.sl<AdminBloc>()),
      ],
      child: const ExpenseTrackerApp(),
    ),
  );
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        textTheme: AppTypography.getTextTheme(isDark: false),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        textTheme: AppTypography.getTextTheme(isDark: true),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (previous, current) {
          // Never rebuild the root navigator for an auth error.
          // The LoginScreen's own listener handles showing the snackbar.
          if (current is AuthError) return false;
          // Also don't rebuild for AuthLoading when we're already on the auth screen
          // (i.e. previous was unauthenticated/error — login attempt in progress)
          if (current is AuthLoading && previous is! AuthAuthenticated) {
            return false;
          }
          return true;
        },
        builder: (context, state) {
          if (state is AuthInitial) {
            // Show a splash or loading screen while checking auth state
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          if (state is AuthAuthenticated) {
            // Evaluate role navigation
            if (state.user.role == 'admin') {
              return const DashboardScreen();
            } else {
              return const HomeScreen(); // Changed from TransactionsScreen to HomeScreen
            }
          }

          // Unauthenticated or Error state directs to Login/Signup Swapper
          return const AuthScreen();
        },
      ),
    );
  }
}

// ---------------------------------------------------------
// Temporary Placeholder Screens
// (These will eventually live in packages/features)
// ---------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AnalysisPeriod _selectedPeriod = AnalysisPeriod.monthly;

  @override
  void initState() {
    super.initState();
    // Fetch transactions when home screen loads
    context.read<TransactionsBloc>().add(LoadTransactions());
    context.read<TransactionsBloc>().add(LoadCategories());
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) {
      if (bloc.state is AuthAuthenticated) {
        return (bloc.state as AuthAuthenticated).user;
      }
      return null;
    });

    return Scaffold(
      extendBodyBehindAppBar: true, // Needed for blur effect behind app bar
      appBar: GlassAppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: AppTypography.bodyMedium),
            Text(
              user?.name ?? "User",
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'View Analytics Data',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AnalysisScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          // IconButton(
          //   icon: const Icon(Icons.logout),
          //   onPressed: () {
          //     context.read<AuthBloc>().add(AuthLogoutRequested());
          //   },
          // ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<TransactionsBloc, TransactionsState>(
          builder: (context, state) {
            final currency = user?.currency ?? 'USD';
            double balance = 0;
            double income = 0;
            double expenses = 0;
            if (state is TransactionsLoaded) {
              final totals = _calculatePeriodTotals(
                state.transactions,
                _selectedPeriod,
              );
              balance = CurrencyConverter.convert(
                totals.balance,
                'USD',
                currency,
              );
              income = CurrencyConverter.convert(
                totals.income,
                'USD',
                currency,
              );
              expenses = CurrencyConverter.convert(
                totals.expenses,
                'USD',
                currency,
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<TransactionsBloc>().add(LoadTransactions());
              },
              child: ListView(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 16.0,
                  top: 24.0,
                ),
                children: [
                  _buildBalanceCard(balance, income, expenses, currency),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TransactionsScreen(),
                            ),
                          );
                        },
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  if (state is TransactionsLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (state is TransactionsLoaded &&
                      state.transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text('No transactions for this month.'),
                      ),
                    )
                  else if (state is TransactionsLoaded)
                    ...state.transactions
                        .take(5)
                        .map(
                          (tx) => ListTile(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TransactionDetailsScreen(transaction: tx),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundColor: Color(
                                int.parse(
                                  tx.category.color.replaceFirst('#', '0xFF'),
                                ),
                              ),
                              child: CategoryIcon(
                                icon: tx.category.icon,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(tx.category.name),
                            subtitle: Text(
                              tx.date.toLocal().toString().split(' ')[0],
                            ),
                            trailing: Text(
                              CurrencyFormatter.format(
                                CurrencyConverter.convert(
                                  tx.amount,
                                  'USD',
                                  currency,
                                ),
                                currency: currency,
                              ),
                              style: TextStyle(
                                color: tx.type == 'income'
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open Transaction feature
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBalanceCard(
    double balance,
    double income,
    double expenses,
    String currency,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current ${_getPeriodName(_selectedPeriod)} Balance',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: AppColors.primary,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AnalysisPeriod>(
                    value: _selectedPeriod,
                    isDense: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white70,
                      size: 20,
                    ),
                    items: AnalysisPeriod.values.map((period) {
                      return DropdownMenuItem(
                        value: period,
                        child: Text(
                          _getPeriodName(period),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPeriod = val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(balance, currency: currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIncomeExpenseColumn(
                'Income',
                income,
                Icons.arrow_downward,
                AppColors.success,
                currency,
              ),
              _buildIncomeExpenseColumn(
                'Expenses',
                expenses,
                Icons.arrow_upward,
                Colors.redAccent,
                currency,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseColumn(
    String title,
    double amount,
    IconData icon,
    Color iconColor,
    String currency,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              CurrencyFormatter.format(amount, currency: currency),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  ({double balance, double income, double expenses}) _calculatePeriodTotals(
    List<TransactionModel> transactions,
    AnalysisPeriod period,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    double incomeTotal = 0;
    double expensesTotal = 0;

    for (final tx in transactions) {
      final txDate = tx.date.toLocal();
      bool include = false;

      switch (period) {
        case AnalysisPeriod.weekly:
          // Start of week (Sunday)
          // DateTime.weekday: 1 = Mon, 7 = Sun. 
          // If Sun (7), days to subtract = 0. If Mon (1), subtract 1.
          final daysToSubtract = today.weekday % 7;
          final weekStart = today.subtract(Duration(days: daysToSubtract));
          if (!txDate.isBefore(weekStart)) include = true;
          break;
        case AnalysisPeriod.monthly:
          // Same month and year
          if (txDate.year == now.year && txDate.month == now.month) {
            include = true;
          }
          break;
        case AnalysisPeriod.yearly:
          // Same year
          if (txDate.year == now.year) {
            include = true;
          }
          break;
      }

      if (include) {
        if (tx.type == 'income') {
          incomeTotal += tx.amount;
        } else {
          expensesTotal += tx.amount;
        }
      }
    }

    return (
      balance: incomeTotal - expensesTotal,
      income: incomeTotal,
      expenses: expensesTotal,
    );
  }

  String _getPeriodName(AnalysisPeriod period) {
    switch (period) {
      case AnalysisPeriod.weekly:
        return 'Week';
      case AnalysisPeriod.monthly:
        return 'Month';
      case AnalysisPeriod.yearly:
        return 'Year';
    }
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const LoadAdminDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) {
      if (bloc.state is AuthAuthenticated) {
        return (bloc.state as AuthAuthenticated).user;
      }
      return null;
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Dashboard', style: AppTypography.bodySmall),
            Text(
              'Hey, ${user?.name ?? "Admin"}',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'User Management',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<AdminBloc>(),
                    child: const UserManagementScreen(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
        ],
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AdminError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is AdminLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AdminBloc>().add(const LoadAdminDashboard());
              },
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildStatsCard(
                    'Total Registered Users',
                    state.stats.total.toString(),
                    Icons.people_outline,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'System Categories',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppColors.primary,
                        ),
                        onPressed: () => _showAddCategoryDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (state.categories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('No categories found.')),
                    )
                  else
                    ...state.categories.map(
                      (cat) => Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(
                              int.parse(cat.color.replaceFirst('#', '0xFF')),
                            ),
                            child: CategoryIcon(
                              icon: cat.icon,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            cat.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Type: ${cat.type.toUpperCase()}'),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: AppColors.error,
                            ),
                            onPressed: () {
                              context.read<AdminBloc>().add(
                                DeleteAdminCategory(cat.id),
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
          return const Center(child: Text('No Data'));
        },
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedType = 'expense';
    String selectedColor = '#FF0000';
    String selectedIcon = 'category';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'income', child: Text('Income')),
                      DropdownMenuItem(
                        value: 'expense',
                        child: Text('Expense'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedColor,
                    decoration: const InputDecoration(labelText: 'Color'),
                    items: const [
                      DropdownMenuItem(
                        value: '#FF0000',
                        child: Text('Red', style: TextStyle(color: Colors.red)),
                      ),
                      DropdownMenuItem(
                        value: '#00FF00',
                        child: Text(
                          'Green',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                      DropdownMenuItem(
                        value: '#0000FF',
                        child: Text(
                          'Blue',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      DropdownMenuItem(
                        value: '#FFA500',
                        child: Text(
                          'Orange',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedColor = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      showIconPicker(
                        context,
                        initialIcon: selectedIcon,
                        onIconSelected: (icon) {
                          setState(() => selectedIcon = icon);
                        },
                      );
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Select Icon',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        children: [
                          CategoryIcon(icon: selectedIcon),
                          const SizedBox(width: 12),
                          Text(selectedIcon),
                          const Spacer(),
                          const Icon(Icons.search, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    final bloc = this.context.read<AdminBloc>();
                    bloc.add(
                      AddAdminCategory(
                        CategoryModel(
                          id: '', // Will be assigned by API
                          name: nameController.text.trim(),
                          type: selectedType,
                          icon: selectedIcon,
                          color: selectedColor,
                        ),
                      ),
                    );
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
