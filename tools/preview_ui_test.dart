import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:backoffice/app.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('packages/frizeraj_ui/FrizerajSans');
    for (final weight in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      fonts.addFont(
        Future.value(
          ByteData.sublistView(
            File('packages/ui/assets/fonts/manrope/Manrope-$weight.ttf')
                .readAsBytesSync(),
          ),
        ),
      );
    }
    await fonts.load();
    final configFile = File('.dart_tool/package_config.json').absolute;
    final config =
        jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
    final flutterPackage = (config['packages'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((p) => p['name'] == 'flutter');
    final sdk = Directory.fromUri(
      configFile.uri.resolve(flutterPackage['rootUri'] as String),
    ).parent.parent.path;
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File(
              '$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
            ).readAsBytesSync(),
          ),
        ),
      );
    await icons.load();
  });

  testWidgets('Render UI previews', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> capture(String name, Size size, Widget app) async {
      Future<void> waitForFrame() async {
        if (app is FrizerajMobile || app is FrizerajBackoffice) {
          await tester.pumpAndSettle();
        } else if (find.byType(SplashScreen).evaluate().isNotEmpty) {
          await tester.pump(const Duration(milliseconds: 300));
        } else {
          await tester.pumpAndSettle();
        }
      }

      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key: key, child: app));
      await waitForFrame();
      for (final asset in [
        'assets/branding/logo.png',
        SplashBranding.symbolAsset,
        SplashBranding.wordmarkAsset,
      ]) {
        await tester.runAsync(
          () => precacheImage(
            AssetImage(asset, package: 'frizeraj_ui'),
            key.currentContext!,
          ),
        );
      }
      await waitForFrame();
      expect(tester.takeException(), isNull);
      final images = tester.widgetList<RawImage>(find.byType(RawImage));
      if (images.isNotEmpty) {
        expect(images.any((image) => image.image != null), isTrue);
      }
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final rendered = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
        final file = File('docs/previews/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        rendered.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
    }

    MemoryQueueStore store() => MemoryQueueStore(
      seed: demoSeed(),
      clock: demoClock,
      latency: Duration.zero,
    );
    Widget splash({bool error = false}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: frizerajTheme(),
      home: SplashScreen(
        error: error ? const RepositoryUnavailable() : null,
        onRetry: () {},
      ),
    );
    await capture('splash-mobile', const Size(390, 866), splash());
    await capture('splash-desktop', const Size(1440, 1000), splash());
    await capture('splash-landscape', const Size(640, 360), splash());
    await capture('splash-error', const Size(390, 866), splash(error: true));
    await capture(
      'splash-error-landscape',
      const Size(640, 360),
      splash(error: true),
    );
    await capture(
      'mobile-home',
      const Size(390, 844),
      FrizerajMobile(
        minimumSplashDuration: Duration.zero,
        repository: store(),
        initialLocation: '/',
      ),
    );
    await capture(
      'mobile-detail',
      const Size(390, 844),
      FrizerajMobile(
        minimumSplashDuration: Duration.zero,
        repository: store(),
        initialLocation: '/entries/active-0',
      ),
    );
    await capture(
      'mobile-form',
      const Size(390, 844),
      FrizerajMobile(
        minimumSplashDuration: Duration.zero,
        repository: store(),
        initialLocation: '/salons/s3/join',
      ),
    );
    await capture(
      'backoffice-wide',
      const Size(1440, 1000),
      FrizerajBackoffice(
        minimumSplashDuration: Duration.zero,
        repository: store(),
        initialLocation: '/entries/active-1',
      ),
    );
    await capture(
      'backoffice-narrow',
      const Size(600, 1000),
      FrizerajBackoffice(
        minimumSplashDuration: Duration.zero,
        repository: store(),
        initialLocation: '/entries/active-1',
      ),
    );
  });
}
