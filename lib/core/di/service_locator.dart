import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:splitsathi/core/security/biometric_service.dart';
import 'package:splitsathi/core/theme/theme_cubit.dart';
import 'package:splitsathi/core/utils/connectivity_cubit.dart';
import 'package:splitsathi/features/auth/bloc/auth_bloc.dart';
import 'package:splitsathi/features/auth/repository/auth_repository.dart';
import 'package:splitsathi/features/expenses/bloc/expense_bloc.dart';
import 'package:splitsathi/features/expenses/cubit/add_expense_form_cubit.dart';
import 'package:splitsathi/features/expenses/repository/expense_repository.dart';
import 'package:splitsathi/features/groups/bloc/group_bloc.dart';
import 'package:splitsathi/features/groups/cubit/create_group_form_cubit.dart';
import 'package:splitsathi/features/groups/cubit/group_detail_cubit.dart';
import 'package:splitsathi/features/groups/repository/group_repository.dart';
import 'package:splitsathi/features/home/cubit/home_summary_cubit.dart';
import 'package:splitsathi/features/insights/cubit/insights_cubit.dart';
import 'package:splitsathi/features/notifications/bloc/notification_bloc.dart';
import 'package:splitsathi/features/notifications/repository/notification_repository.dart';
import 'package:splitsathi/features/profile/cubit/settings_cubit.dart';
import 'package:splitsathi/features/profile/repository/profile_repository.dart';

final getIt = GetIt.instance;
Future<void> setupServiceLocator() async {
  // Firebase instances
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );
  getIt.registerLazySingleton<FirebaseMessaging>(
    () => FirebaseMessaging.instance,
  );

  // Cubits/Blocs
  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      firebaseAuth: getIt<FirebaseAuth>(),
      firebaseFirestore: getIt<FirebaseFirestore>(),
    ),
  );

  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<GroupRepository>(
    () => GroupRepository(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerLazySingleton<GroupBloc>(
    () => GroupBloc(groupRepository: getIt<GroupRepository>()),
  );

  getIt.registerFactory<CreateGroupFormCubit>(
    () => CreateGroupFormCubit(groupRepository: getIt<GroupRepository>()),
  );

  getIt.registerFactory<GroupDetailCubit>(
    () => GroupDetailCubit(
      groupRepository: getIt<GroupRepository>(),
      expenseRepository: getIt<ExpenseRepository>(),
    ),
  );

  getIt.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepository(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerFactory<ExpenseBloc>(
    () => ExpenseBloc(expenseRepository: getIt<ExpenseRepository>()),
  );

  getIt.registerFactory<AddExpenseFormCubit>(
    () => AddExpenseFormCubit(
      expenseRepository: getIt<ExpenseRepository>(),
      notificationRepository: getIt<NotificationRepository>(),
    ),
  );

  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerLazySingleton<NotificationBloc>(
    () => NotificationBloc(
      notificationRepository: getIt<NotificationRepository>(),
    ),
  );

  getIt.registerFactory<InsightsCubit>(
    () => InsightsCubit(expenseRepository: getIt<ExpenseRepository>()),
  );

  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerLazySingleton<BiometricService>(() => BiometricService());

  getIt.registerFactory<SettingsCubit>(
    () => SettingsCubit(biometricService: getIt<BiometricService>()),
  );

  getIt.registerLazySingleton<ConnectivityCubit>(() => ConnectivityCubit());

  getIt.registerFactory<HomeSummaryCubit>(
    () => HomeSummaryCubit(expenseRepository: getIt<ExpenseRepository>()),
  );
}
