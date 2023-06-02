import 'dart:async';

import 'package:flutter_phone_lib/flutter_phone_lib.dart';

import '../../../dependency_locator.dart';
import '../use_case.dart';
import '../user/connectivity/connectivity.dart';
import 'metrics.dart';
import 'track_voip_call.dart';

class TrackVoipCallStartedUseCase extends UseCase {
  final _metricsRepository = dependencyLocator<MetricsRepository>();
  final _connectivityRepository = dependencyLocator<ConnectivityRepository>();

  void call({
    required String via,
    required CallDirection direction,
  }) {
    unawaited(
      _connectivityRepository.currentType.then((connectivityType) {
        _metricsRepository.track('voip-call-started', {
          'via': via,
          'direction': direction.toTrackString(),
          'connection': connectivityType.toString(),
        });
      }),
    );
  }
}
