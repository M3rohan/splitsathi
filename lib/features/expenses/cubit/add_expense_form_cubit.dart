import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitsathi/core/di/service_locator.dart';
import 'package:splitsathi/core/utils/recurrence_helper.dart';
import 'package:splitsathi/features/expenses/cubit/add_expense_form_state.dart';
import 'package:splitsathi/features/expenses/models/expense_model.dart';
import 'package:splitsathi/features/expenses/repository/expense_repository.dart';
import 'package:splitsathi/features/notifications/repository/notification_repository.dart';
import 'package:splitsathi/services/analytics_service.dart';

class AddExpenseFormCubit extends Cubit<AddExpenseFormState> {
  final ExpenseRepository _expenseRepository;
  final NotificationRepository _notificationRepository;

  AddExpenseFormCubit({
    required ExpenseRepository expenseRepository,
    required NotificationRepository notificationRepository,
  }) : _expenseRepository = expenseRepository,
       _notificationRepository = notificationRepository,
       super(const AddExpenseFormState());

  void initWithMembers(List<String> allMemberIds, String currentUserId) {
    emit(state.copyWith(paidBy: currentUserId, splitBetween: allMemberIds));
  }

  void selectCategory(String categoryId) {
    emit(state.copyWith(category: categoryId));
  }

  void selectPaidBy(String userId) {
    emit(state.copyWith(paidBy: userId));
  }

  void toggleSplitMember(String userId) {
    final current = List<String>.from(state.splitBetween);
    if (current.contains(userId)) {
      if (current.length == 1) {
        return;
      }
      current.remove(userId);
    } else {
      current.add(userId);
    }
    emit(state.copyWith(splitBetween: current));
  }

  void setSplitType(String type) {
    emit(state.copyWith(splitType: type, customSplits: {}));
  }

  void setCustomSplitAmount(String userId, double amount) {
    final updated = Map<String, double>.from(state.customSplits);
    updated[userId] = amount;
    emit(state.copyWith(customSplits: updated));
  }

  double get customSplitsSum =>
      state.customSplits.values.fold(0.0, (sum, v) => sum + v);

  void toggleRecurring(bool value) {
    emit(state.copyWith(isRecurring: value));
  }

  void selectRecurrenceFrequency(String frequency) {
    emit(state.copyWith(recurrenceFrequency: frequency));
  }

  Future<bool> submit({
    required String groupId,
    required String groupName,
    required String description,
    required double amount,
    required List<String> allMemberIds,
    required String actorName,
    required String actorUserId,
  }) async {
    if (state.paidBy == null || state.splitBetween.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Please select who paid and who is splitting',
        ),
      );
      return false;
    }

    if (state.splitType == 'custom') {
      final sum = customSplitsSum;
      if ((sum - amount).abs() > 0.01) {
        emit(
          state.copyWith(
            errorMessage:
                'Custom split amounts (₹${sum.toStringAsFixed(2)}) must add up to the total (₹${amount.toStringAsFixed(2)})',
          ),
        );
        return false;
      }
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      final expense = ExpenseModel(
        id: '',
        groupId: groupId,
        description: description,
        amount: amount,
        paidBy: state.paidBy!,
        splitBetween: state.splitBetween,
        splitType: state.splitType,
        customSplits: state.splitType == 'custom' ? state.customSplits : null,
        category: state.category,
        isRecurring: state.isRecurring,
        recurrenceFrequency: state.isRecurring
            ? state.recurrenceFrequency
            : null,
        nextDueDate: state.isRecurring
            ? RecurrenceHelper.calculateNextDueDate(state.recurrenceFrequency)
            : null,
      );
      await _expenseRepository.addExpense(expense);
      getIt<AnalyticsService>().logExpenseAdded(
        category: state.category,
        splitType: state.splitType,
        isRecurring: state.isRecurring,
      );

      _notificationRepository.notifyNewExpense(
        memberIds: allMemberIds,
        excludeUserId: actorUserId,
        actorName: actorName,
        groupId: groupId,
        groupName: groupName,
        expenseId: '',
        description: description,
        amount: amount,
      );

      emit(state.copyWith(isSubmitting: false));
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to add expense.Please try again.',
        ),
      );
      return false;
    }
  }
}
