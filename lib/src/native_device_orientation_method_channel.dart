import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart'
    show MethodChannel, EventChannel, DeviceOrientation;
import 'package:native_device_orientation/src/native_device_orientation_platform_interface.dart';

DeviceOrientation _fromString(
  String orientationString,
  DeviceOrientation defaultOrientation,
) =>
    switch (orientationString) {
      'PortraitUp' => DeviceOrientation.portraitUp,
      'PortraitDown' => DeviceOrientation.portraitDown,
      'LandscapeLeft' => DeviceOrientation.landscapeLeft,
      'LandscapeRight' => DeviceOrientation.landscapeRight,
      _ => defaultOrientation,
    };

class _OrientationStream {
  final Stream<OrientationParams> stream;
  final bool useSensor;

  _OrientationStream({required this.stream, required this.useSensor});
}

/// An implementation of [NativeDeviceOrientationPlatform] that uses method channels.
class MethodChannelNativeDeviceOrientation
    extends NativeDeviceOrientationPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_device_orientation');
  @visibleForTesting
  final eventChannel = const EventChannel('native_device_orientation_events');

  _OrientationStream? _stream;

  @override
  Future<void> pause() {
    return methodChannel.invokeMethod('pause');
  }

  @override
  Future<void> resume() {
    return methodChannel.invokeMethod('resume');
  }

  @override
  Future<DeviceOrientation> orientation({
    bool useSensor = false,
    DeviceOrientation defaultOrientation = DeviceOrientation.portraitUp,
  }) async {
    final params = <String, dynamic>{'useSensor': useSensor};
    final orientationString =
        await methodChannel.invokeMethod('getOrientation', params);
    return _fromString(orientationString, defaultOrientation);
  }

  @override
  Stream<OrientationParams> onOrientationChanged({
    bool useSensor = false,
    bool checkIsAutoRotate = true,
    DeviceOrientation defaultOrientation = DeviceOrientation.portraitUp,
  }) {
    if (_stream == null || _stream!.useSensor != useSensor) {
      final params = <String, dynamic>{
        'useSensor': useSensor,
        'checkIsAutoRotate': checkIsAutoRotate,
      };
      _stream = _OrientationStream(
        stream:
            eventChannel.receiveBroadcastStream(params).map((dynamic event) {
          if (event is Map) {
            return (
              orientation:
                  _fromString(event['orientation'], defaultOrientation),
              isAutoRotate: event['isAutoRotate'],
            );
          }
          return (
            orientation: _fromString(event, defaultOrientation),
            isAutoRotate: null,
          );
        }),
        useSensor: useSensor,
      );
    }
    return _stream!.stream;
  }
}
