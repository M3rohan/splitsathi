import 'package:equatable/equatable.dart';

class AddExpenseFormState extends Equatable {
  final String category;
  final String? paidBy;
  final List<String> splitBetween;
  final String splitType;
  final Map<String, double> customSplits;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isRecurring;
  final String recurrenceFrequency;

  const AddExpenseFormState({
    this.category = 'general',
    this.paidBy,
    this.splitBetween = const [],
    this.splitType = 'equal',
    this.customSplits = const {},
    this.isSubmitting = false,
    this.errorMessage,
    this.isRecurring = false,
    this.recurrenceFrequency = 'monthly',
  });

  AddExpenseFormState copyWith({
    String? category,
    String? paidBy,
    List<String>? splitBetween,
    String? splitType,
    Map<String, double>? customSplits,
    bool? isSubmitting,
    String? errorMessage,
    bool? isRecurring,
    String? recurrenceFrequency,
  }) {
    return AddExpenseFormState(
      category: category ?? this.category,
      paidBy: paidBy ?? this.paidBy,
      splitBetween: splitBetween ?? this.splitBetween,
      splitType: splitType ?? this.splitType,
      customSplits: customSplits ?? this.customSplits,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
    );
  }

  @override
  List<Object?> get props => [
    category,
    paidBy,
    splitBetween,
    splitType,
    customSplits,
    isSubmitting,
    errorMessage,
    isRecurring,
    recurrenceFrequency,
  ];
}
