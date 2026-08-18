import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  //Auth events
  Future<void> logSignUp() => _analytics.logSignUp(signUpMethod: 'email');
  Future<void> logLogin() => _analytics.logLogin(loginMethod: 'email');
  Future<void> logLogout() => _analytics.logEvent(name: 'email');

  //Group events
  Future<void> logGroupCreated({required int memberCount}) =>
      _analytics.logEvent(
        name: 'group_created',
        parameters: {'member_count': memberCount},
      );

  Future<void> logGroupDeleted() => _analytics.logEvent(name: 'group_deleted');
  Future<void> logGroupLeft() => _analytics.logEvent(name: 'group_left');
  Future<void> logMemberRemoved() =>
      _analytics.logEvent(name: 'member_removed');

  //Expense events
  Future<void> logExpenseAdded({
    required String category,
    required String splitType,
    required bool isRecurring,
  }) => _analytics.logEvent(
    name: 'expense_added',
    parameters: {
      'category': category,
      'split_type': splitType,
      'is_recurring': isRecurring,
    },
  );

  Future<void> logExpenseDeleted() =>
      _analytics.logEvent(name: 'expense_deleted');

  // Feature engagement
  Future<void> logInsightsViewed() =>
      _analytics.logEvent(name: 'insights_viewed');
  Future<void> logSettlementViewed() =>
      _analytics.logEvent(name: 'settlement_viewed');
  Future<void> logNotificationTapped() =>
      _analytics.logEvent(name: 'notification_tapped');
  Future<void> logAvatarChanged() =>
      _analytics.logEvent(name: 'avatar_changed');
  Future<void> logThemeChanged({required String mode}) =>
      _analytics.logEvent(name: 'theme_changed', parameters: {'mode': mode});
  Future<void> logLanguageChanged({required String language}) => _analytics
      .logEvent(name: 'language_changed', parameters: {'language': language});
  Future<void> logBiometricToggled({required bool enabled}) => _analytics
      .logEvent(name: 'biometric_toggled', parameters: {'enabled': enabled});

  //  App lifecycle
  Future<void> logAppRated() => _analytics.logEvent(name: 'app_rated');
  Future<void> logAppShared() => _analytics.logEvent(name: 'app_shared');
  Future<void> logAccountDeleted() =>
      _analytics.logEvent(name: 'account_deleted');

  //  User identification
  Future<void> setUserId(String? uid) => _analytics.setUserId(id: uid);
}
