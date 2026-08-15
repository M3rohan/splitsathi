import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitsathi/core/utils/debt_simplifier.dart';
import 'package:splitsathi/features/expenses/repository/expense_repository.dart';
import 'package:splitsathi/features/groups/models/group_model.dart';

class HomeSummaryState extends Equatable {
  final double totalBalance;
  final bool isLoading;

  const HomeSummaryState({this.totalBalance = 0, this.isLoading = true});

  HomeSummaryState copyWith({double? totalBalance, bool? isLoading}) {
    return HomeSummaryState(
      totalBalance: totalBalance ?? this.totalBalance,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [totalBalance, isLoading];
}

class HomeSummaryCubit extends Cubit<HomeSummaryState> {
  final ExpenseRepository _expenseRepository;
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, double> _groupBalances = {};

  HomeSummaryCubit({required ExpenseRepository expenseRepository})
    : _expenseRepository = expenseRepository,
      super(const HomeSummaryState());

  void updateGroups(List<GroupModel> groups, String currentUserId) {
    final currentGroupIds = groups.map((g) => g.id).toSet();

    final staleIds = _subscriptions.keys
        .where((id) => !currentGroupIds.contains(id))
        .toList();

    for (final id in staleIds) {
      _subscriptions[id]?.cancel();
      _subscriptions.remove(id);
      _groupBalances.remove(id);
    }

    if (groups.isEmpty) {
      emit(const HomeSummaryState(totalBalance: 0, isLoading: false));
      return;
    }

    for (final group in groups) {
      if (_subscriptions.containsKey(group.id)) continue;

      _subscriptions[group.id] = _expenseRepository
          .watchExpenses(group.id)
          .listen((expenses) {
            final balances = DebtSimplifier.calculateNetBalances(
              expenses,
              group.memberIds,
            );
            _groupBalances[group.id] = balances[currentUserId] ?? 0.0;
            _emitTotal();
          });
    }
  }

  void _emitTotal() {
    final total = _groupBalances.values.fold(0.0, (sum, v) => sum + v);
    emit(HomeSummaryState(totalBalance: total, isLoading: false));
  }

  @override
  Future<void> close() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    return super.close();
  }
}
