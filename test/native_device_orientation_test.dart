import 'package:flutter_test/flutter_test.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:native_device_orientation/src/native_device_orientation_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeDeviceOrientationPlatform with MockPlatformInterfaceMixin implements NativeDeviceOrientationPlatform {
  @override
  Stream<NativeDeviceOrientation> onOrientationChanged({
    bool useSensor = false,
    bool checkIsAutoRotate = true,
    NativeDeviceOrientation defaultOrientation = NativeDeviceOrientation.portraitUp,
  }) async* {
    yield NativeDeviceOrientation.landscapeLeft;
    yield NativeDeviceOrientation.landscapeRight;
  }

  @override
  Future<NativeDeviceOrientation> orientation({
    bool useSensor = false,
    NativeDeviceOrientation defaultOrientation = NativeDeviceOrientation.portraitUp,
  }) async {
    if (useSensor) {
      return NativeDeviceOrientation.landscapeLeft;
    } else {
      return NativeDeviceOrientation.landscapeRight;
    }
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}
}

void main() {
  final NativeDeviceOrientationPlatform initialPlatform = NativeDeviceOrientationPlatform.instance;

  test('$MethodChannelNativeDeviceOrientation is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativeDeviceOrientation>());
  });

  group('test', () {
    setUp(() {
      MockNativeDeviceOrientationPlatform fakePlatform = MockNativeDeviceOrientationPlatform();
      NativeDeviceOrientationPlatform.instance = fakePlatform;
    });

    test('pause', () async {
      await NativeDeviceOrientationPlatform.instance.pause();
    });

    test('resume', () async {
      await NativeDeviceOrientationPlatform.instance.resume();
    });

    test('orientation', () async {
      expect(await NativeDeviceOrientationPlatform.instance.orientation(), NativeDeviceOrientation.landscapeRight);
      expect(
        await NativeDeviceOrientationPlatform.instance.orientation(useSensor: true),
        NativeDeviceOrientation.landscapeLeft,
      );
    });

    test('onOrientationChanged', () async {
      final stream = NativeDeviceOrientationPlatform.instance.onOrientationChanged();

      var numEvents = 0;

      final sub = stream.listen((event) {
        numEvents += 1;
      });

      await sub.asFuture();
      expect(numEvents, 2);
    });
  });
}
