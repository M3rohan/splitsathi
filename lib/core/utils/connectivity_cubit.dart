import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConnectivityCubit extends Cubit<bool> {
  Timer? _debounceTimer;
  StreamSubscription? _subscription;
  ConnectivityCubit() : super(true) {
    _listenToConnection();
  }

  void _listenToConnection() {
    _subscription = FirebaseFirestore.instance
        .collection('_connectivity_check')
        .doc('ping')
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snapshot) {
            final isOffline =
                snapshot.metadata.isFromCache &&
                !snapshot.metadata.hasPendingWrites;
            _debounceTimer?.cancel();
            if (isOffline) {
              _debounceTimer = Timer(const Duration(milliseconds: 2500), () {
                if (!isClosed) emit(false);
              });
            } else {
              emit(true);
            }
          },
          onError: (_) {
            if (!isClosed) emit(false);
          },
        );
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    return super.close();
  }
}
