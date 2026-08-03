import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitsathi/features/expenses/models/expense_model.dart';
import 'package:splitsathi/features/expenses/repository/expense_repository.dart';

class CategoryBreakdown extends Equatable {
  final String category;
  final double totalAmount;
  final double percentage;

  const CategoryBreakdown({
    required this.category,
    required this.totalAmount,
    required this.percentage,
  });

  @override
  List<Object?> get props => [category, totalAmount, percentage];
}

class InsightsState extends Equatable {
  final List<CategoryBreakdown> breakdown;
  final double totalSpent;
  final bool isLoading;

  const InsightsState({
    this.breakdown = const [],
    this.totalSpent = 0,
    this.isLoading = true,
  });

  InsightsState copyWith({
    List<CategoryBreakdown>? breakdown,
    double? totalSpent,
    bool? isLoading,
  }) {
    return InsightsState(
      breakdown: breakdown ?? this.breakdown,
      totalSpent: totalSpent ?? this.totalSpent,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [breakdown, totalSpent, isLoading];
}

class InsightsCubit extends Cubit<InsightsState> {
  final ExpenseRepository _expenseRepository;
  StreamSubscription<List<ExpenseModel>>? _subscription;

  InsightsCubit({required ExpenseRepository expenseRepository})
    : _expenseRepository = expenseRepository,
      super(const InsightsState());

  void watchInsights(String groupId) {
    _subscription?.cancel();
    _subscription = _expenseRepository.watchExpenses(groupId).listen((
      expenses,
    ) {
      if (expenses.isEmpty) {
        emit(const InsightsState(isLoading: false));
        return;
      }

      final totals = <String, double>{};
      double total = 0;

      for (final expense in expenses) {
        totals[expense.category] =
            (totals[expense.category] ?? 0) + expense.amount;

        total += expense.amount;
      }

      final breakdown = totals.entries.map((entry) {
        return CategoryBreakdown(
          category: entry.key,
          totalAmount: entry.value,
          percentage: total > 0 ? (entry.value / total) * 100 : 0,
        );
      }).toList()..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

      emit(
        InsightsState(
          breakdown: breakdown,
          totalSpent: total,
          isLoading: false,
        ),
      );
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
