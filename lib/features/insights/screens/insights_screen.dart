import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitsathi/core/constants/expense_categories.dart';
import 'package:splitsathi/core/di/service_locator.dart';
import 'package:splitsathi/core/theme/app_theme.dart';
import 'package:splitsathi/features/insights/cubit/insights_cubit.dart';
import 'package:splitsathi/services/analytics_service.dart';

const List<Color> _chartColors = [
  AppTheme.primaryColor,
  AppTheme.secondaryColor,
  Color(0xFFFFA726),
  Color(0xFFEF5350),
  Color(0xFF66BB6A),
  Color(0xFF42A5F5),
  Color(0xFFAB47BC),
  Color(0xFF26C6DA),
];

class InsightsScreen extends StatelessWidget {
  final String groupId;
  const InsightsScreen({super.key, required this.groupId});
  @override
  Widget build(BuildContext context) {
    return BlocProvider<InsightsCubit>(
      create: (_) => getIt<InsightsCubit>()..watchInsights(groupId),
      child: const _InsightsView(),
    );
  }
}

class _InsightsView extends StatelessWidget {
  const _InsightsView();

  @override
  Widget build(BuildContext context) {
    getIt<AnalyticsService>().logInsightsViewed();
    return Scaffold(
      appBar: AppBar(title: Text('insights'.tr())),
      body: BlocBuilder<InsightsCubit, InsightsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.breakdown.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsetsGeometry.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 56,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'no_data_for_insights'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'total_spent'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${state.totalSpent.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 50,
                          sections: List.generate(state.breakdown.length, (
                            index,
                          ) {
                            final item = state.breakdown[index];
                            final color =
                                _chartColors[index % _chartColors.length];
                            return PieChartSectionData(
                              color: color,
                              value: item.totalAmount,
                              title: '${item.percentage.toStringAsFixed(0)}%',
                              radius: 65,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms)
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1, 1),
                    ),
                const SizedBox(height: 28),

                Text(
                  'by_category'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                ...List.generate(state.breakdown.length, (index) {
                  final item = state.breakdown[index];
                  final color = _chartColors[index % _chartColors.length];

                  return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),

                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                ExpenseCategories.iconForId(item.category),
                                color: color,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'category_${item.category}'.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '₹${item.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.percentage.toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (300 + index * 60).ms)
                      .slideX(begin: -0.05, end: 0);
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
