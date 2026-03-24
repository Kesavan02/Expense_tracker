import 'package:equatable/equatable.dart';

class AdminUserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final String avatar;
  final String currency;
  final DateTime createdAt;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.avatar,
    required this.currency,
    required this.createdAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      avatar: json['avatar'] as String? ?? '',
      currency: json['currency'] as String? ?? 'USD',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, name, email, role, avatar, currency, createdAt];
}

class AdminStatsModel extends Equatable {
  final int total;
  final int thisWeek;
  final int thisMonth;
  final int thisYear;
  final List<ChartPoint> chartPoints;

  const AdminStatsModel({
    required this.total,
    required this.thisWeek,
    required this.thisMonth,
    required this.thisYear,
    required this.chartPoints,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>;
    final rawChart = json['chart'] as List<dynamic>;

    return AdminStatsModel(
      total: summary['total'] as int? ?? 0,
      thisWeek: summary['thisWeek'] as int? ?? 0,
      thisMonth: summary['thisMonth'] as int? ?? 0,
      thisYear: summary['thisYear'] as int? ?? 0,
      chartPoints: rawChart.map((e) => ChartPoint.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  @override
  List<Object?> get props => [total, thisWeek, thisMonth, thisYear, chartPoints];
}

class ChartPoint extends Equatable {
  final int year;
  final int? month;
  final int? week;
  final int count;

  const ChartPoint({required this.year, this.month, this.week, required this.count});

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] as Map<String, dynamic>;
    return ChartPoint(
      year: id['year'] as int? ?? 0,
      month: id['month'] as int?,
      week: id['week'] as int?,
      count: json['count'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [year, month, week, count];
}
