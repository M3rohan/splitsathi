import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitsathi/core/utils/debt_simplifier.dart';
import 'package:splitsathi/features/expenses/models/expense_model.dart';
import 'package:splitsathi/features/expenses/repository/expense_repository.dart';
import 'package:splitsathi/features/groups/models/group_model.dart';
import 'package:splitsathi/features/groups/repository/group_repository.dart';

enum GroupDetailStatus { loading, loaded, notFound, error }

class GroupDetailState extends Equatable {
  final GroupDetailStatus status;
  final GroupModel? group;
  final List<Map<String, dynamic>> members;
  final List<ExpenseModel> expenses;
  final Map<String, double> netBalances;
  final List<SettlementTransaction> settlements;

  const GroupDetailState({
    this.status = GroupDetailStatus.loading,
    this.group,
    this.members = const [],
    this.expenses = const [],
    this.netBalances = const {},
    this.settlements = const [],
  });

  GroupDetailState copyWith({
    GroupDetailStatus? status,
    GroupModel? group,
    List<Map<String, dynamic>>? members,
    List<ExpenseModel>? expenses,
    Map<String, double>? netBalances,
    List<SettlementTransaction>? settlements,
  }) {
    return GroupDetailState(
      status: status ?? this.status,
      group: group ?? this.group,
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
      netBalances: netBalances ?? this.netBalances,
      settlements: settlements ?? this.settlements,
    );
  }

  @override
  List<Object?> get props => [
    status,
    group,
    members,
    expenses,
    netBalances,
    settlements,
  ];
}

class GroupDetailCubit extends Cubit<GroupDetailState> {
  final GroupRepository _groupRepository;
  final ExpenseRepository _expenseRepository;
  StreamSubscription<GroupModel?>? _groupSubscription;
  StreamSubscription<List<ExpenseModel>>? _expensesSubscription;

  GroupDetailCubit({
    required GroupRepository groupRepository,
    required ExpenseRepository expenseRepository,
  }) : _groupRepository = groupRepository,
       _expenseRepository = expenseRepository,
       super(const GroupDetailState());

  void watchGroup(String groupId) {
    _groupSubscription?.cancel();
    _groupSubscription = _groupRepository
        .watchGroup(groupId)
        .listen(
          (group) async {
            if (group == null) {
              emit(state.copyWith(status: GroupDetailStatus.notFound));
              return;
            }

            final members = await _groupRepository.getMembersInfo(
              group.memberIds,
            );
            emit(
              state.copyWith(
                status: GroupDetailStatus.loaded,
                group: group,
                members: members,
              ),
            );
            _watchExpenses(groupId, group.memberIds);
          },
          onError: (_) {
            emit(state.copyWith(status: GroupDetailStatus.error));
          },
        );
  }

  void _watchExpenses(String groupId, List<String> memberIds) {
    _expensesSubscription?.cancel();
    _expensesSubscription = _expenseRepository.watchExpenses(groupId).listen((
      expenses,
    ) {
      final netBalances = DebtSimplifier.calculateNetBalances(
        expenses,
        memberIds,
      );

      final settlements = DebtSimplifier.simplifyDebts(netBalances);

      emit(
        state.copyWith(
          expenses: expenses,
          netBalances: netBalances,
          settlements: settlements,
        ),
      );
    });
  }

  @override
  Future<void> close() {
    _groupSubscription?.cancel();
    _expensesSubscription?.cancel();
    return super.close();
  }
}
