import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitsathi/features/expenses/bloc/expense_event.dart';
import 'package:splitsathi/features/expenses/bloc/expense_state.dart';
import 'package:splitsathi/features/expenses/repository/expense_repository.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _expenseRepository;
  StreamSubscription? _expensesSubscription;

  ExpenseBloc({required ExpenseRepository expenseRepository})
    : _expenseRepository = expenseRepository,
      super(const ExpenseState()) {
    on<ExpensesSubscriptionRequested>(_onSubscriptionRequested);
    on<ExpensesUpdated>(_onExpensesUpdated);
    on<ExpenseAddRequested>(_onAddRequested);
  }

  Future<void> _onSubscriptionRequested(
    ExpensesSubscriptionRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseStatus.loading));
    await _expensesSubscription?.cancel();
    _expensesSubscription = _expenseRepository
        .watchExpenses(event.groupId)
        .listen(
          (expenses) => add(ExpensesUpdated(expenses)),
          onError: (_) => emit(state.copyWith(status: ExpenseStatus.error)),
        );
  }

  void _onExpensesUpdated(ExpensesUpdated event, Emitter<ExpenseState> emit) {
    emit(
      state.copyWith(status: ExpenseStatus.loaded, expenses: event.expenses),
    );
  }

  Future<void> _onAddRequested(
    ExpenseAddRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseStatus.adding));
    try {
      await _expenseRepository.addExpense(event.expense);
      emit(state.copyWith(status: ExpenseStatus.added));
    } catch (e) {
      emit(
        state.copyWith(
          status: ExpenseStatus.error,
          errorMessage: 'Failed to add expense. Please try again.',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _expensesSubscription?.cancel();
    return super.close();
  }
}
