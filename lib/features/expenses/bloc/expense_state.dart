import 'package:equatable/equatable.dart';
import 'package:splitsathi/features/expenses/models/expense_model.dart';

enum ExpenseStatus { initial, loading, loaded, adding, added, error }

class ExpenseState extends Equatable {
  final ExpenseStatus status;
  final List<ExpenseModel> expenses;
  final String? errorMessage;

  const ExpenseState({
    this.status = ExpenseStatus.initial,
    this.expenses = const [],
    this.errorMessage,
  });

  double get totalAmount => expenses.fold(0.0, (sum, e) => sum + e.amount);

  ExpenseState copyWith({
    ExpenseStatus? status,
    List<ExpenseModel>? expenses,
    String? errorMessage,
  }) {
    return ExpenseState(
      status: status ?? this.status,
      expenses: expenses ?? this.expenses,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, expenses, errorMessage];
}
