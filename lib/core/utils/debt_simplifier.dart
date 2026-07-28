import 'package:splitsathi/features/expenses/models/expense_model.dart';

class MemberBalance {
  final String userId;
  final double netBalance; // positive = owed money, negative = owes money

  MemberBalance({required this.userId, required this.netBalance});
}

class SettlementTransaction {
  final String fromUserId; // who pays
  final String toUserId; // who receives
  final double amount;

  SettlementTransaction({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });
}

class DebtSimplifier {
  DebtSimplifier._();

  static Map<String, double> calculateNetBalances(
    List<ExpenseModel> expenses,
    List<String> memberIds,
  ) {
    final balances = {for (final id in memberIds) id: 0.0};

    for (final expense in expenses) {
      // The payer gets credited the full amount
      balances[expense.paidBy] =
          (balances[expense.paidBy] ?? 0) + expense.amount;

      // Everyone in the split gets debited their share
      for (final memberId in expense.splitBetween) {
        final share = expense.amountPerPerson(memberId);
        balances[memberId] = (balances[memberId] ?? 0) - share;
      }
    }
    return balances;
  }

  static List<SettlementTransaction> simplifyDebts(
    Map<String, double> netBalances,
  ) {
    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    netBalances.forEach((userId, balance) {
      if (balance > 0.01) {
        creditors.add(MapEntry(userId, balance));
      } else if (balance < -0.01) {
        debtors.add(MapEntry(userId, -balance));
      }
    });

    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    final transactions = <SettlementTransaction>[];
    int i = 0, j = 0;

    final creditorAmounts = creditors.map((e) => e.value).toList();
    final debtorAmounts = debtors.map((e) => e.value).toList();

    while (i < creditors.length && j < debtors.length) {
      final settleAmount = creditorAmounts[i] < debtorAmounts[j]
          ? creditorAmounts[i]
          : debtorAmounts[j];

      if (settleAmount > 0.01) {
        transactions.add(
          SettlementTransaction(
            fromUserId: debtors[j].key,
            toUserId: creditors[i].key,
            amount: double.parse(settleAmount.toStringAsFixed(2)),
          ),
        );
      }

      creditorAmounts[i] -= settleAmount;
      debtorAmounts[j] -= settleAmount;

      if (creditorAmounts[i] < 0.01) i++;
      if (debtorAmounts[j] < 0.01) j++;
    }
    return transactions;
  }
}
