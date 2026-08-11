import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitsathi/core/security/biometric_service.dart';

class SettingsState extends Equatable {
  final bool biometricSupported;
  final bool biometricEnabled;

  const SettingsState({
    this.biometricSupported = false,
    this.biometricEnabled = false,
  });

  SettingsState copyWith({bool? biometricSupported, bool? biometricEnabled}) {
    return SettingsState(
      biometricSupported: biometricSupported ?? this.biometricSupported,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  @override
  List<Object?> get props => [biometricSupported, biometricEnabled];
}

class SettingsCubit extends Cubit<SettingsState> {
  final BiometricService _biometricService;

  SettingsCubit({required BiometricService biometricService})
    : _biometricService = biometricService,
      super(const SettingsState()) {
    _init();
  }

  Future<void> _init() async {
    final supported = await _biometricService.isDeviceSupported();
    final enabled = await _biometricService.isBiometricEnabled();
    emit(
      state.copyWith(biometricSupported: supported, biometricEnabled: enabled),
    );
  }

  Future<void> toggleBiometric(bool value) async {
    if (value) {
      final authenticated = await _biometricService.authenticate(
        reason: 'Confirm to enable biometric lock',
      );
      if (!authenticated) return;
    }

    await _biometricService.setBiometricEnabled(value);
    emit(state.copyWith(biometricEnabled: value));
  }
}
