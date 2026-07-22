import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:splitsathi/core/theme/theme_cubit.dart';
import 'package:splitsathi/features/auth/bloc/auth_bloc.dart';
import 'package:splitsathi/features/auth/repository/auth_repository.dart';
import 'package:splitsathi/features/groups/bloc/group_bloc.dart';
import 'package:splitsathi/features/groups/cubit/create_group_form_cubit.dart';
import 'package:splitsathi/features/groups/cubit/group_detail_cubit.dart';
import 'package:splitsathi/features/groups/repository/group_repository.dart';

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
    () => GroupDetailCubit(groupRepository: getIt<GroupRepository>()),
  );
}
