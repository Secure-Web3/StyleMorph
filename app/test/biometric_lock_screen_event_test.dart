import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/services/biometric_service.dart';
import 'package:stylemorph/main.dart';

Future<void> _sendScreenLockMethodCall(String method) async {
  final codec = const StandardMethodCodec();
  final data = codec.encodeMethodCall(MethodCall(method));
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        BiometricService.screenLockChannelName,
        data,
        (_) {},
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Screen-Lock-Aware Biometric Lock', () {
    test('cold start defaults biometricUnlockedProvider to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(biometricUnlockedProvider), isFalse);
    });

    test(
      'BiometricService.registerScreenLockListener invokes callback on onScreenLocked and unregisters on dispose',
      () async {
        final service = BiometricService();
        var lockEvents = 0;

        final dispose = service.registerScreenLockListener(() {
          lockEvents++;
        });

        await _sendScreenLockMethodCall('otherMethod');
        expect(lockEvents, 0);

        await _sendScreenLockMethodCall('onScreenLocked');
        expect(lockEvents, 1);

        dispose();
        await _sendScreenLockMethodCall('onScreenLocked');
        expect(lockEvents, 1);
      },
    );

    testWidgets(
      'brief app pause/resume does NOT re-lock, while native onScreenLocked DOES re-lock',
      (WidgetTester tester) async {
        late WidgetRef capturedRef;
        final container = ProviderContainer(
          overrides: [
            biometricLockEnabledProvider.overrideWith((ref) async => true),
          ],
        );
        addTearDown(container.dispose);

        await container.read(biometricLockEnabledProvider.future);
        container.read(biometricUnlockedProvider.notifier).state = true;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const StyleMorphApp();
              },
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Brief app switch: paused -> resumed without screen lock must stay unlocked.
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();

        expect(capturedRef.read(biometricUnlockedProvider), isTrue);

        // Native OS screen-lock event (ACTION_SCREEN_OFF / protectedDataWillBecomeUnavailable)
        // must re-lock immediately.
        await _sendScreenLockMethodCall('onScreenLocked');
        await tester.pump();

        expect(capturedRef.read(biometricUnlockedProvider), isFalse);
      },
    );
  });
}
