import 'package:equatable/equatable.dart';
import 'package:splitsathi/features/expenses/models/expense_model.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class ExpensesSubscriptionRequested extends ExpenseEvent {
  final String groupId;
  const ExpensesSubscriptionRequested(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

class ExpensesUpdated extends ExpenseEvent {
  final List<ExpenseModel> expenses;
  const ExpensesUpdated(this.expenses);
  @override
  List<Object?> get props => [expenses];
}

class ExpenseAddRequested extends ExpenseEvent {
  final ExpenseModel expense;
  const ExpenseAddRequested(this.expense);
  @override
  List<Object?> get props => [expense];
}
