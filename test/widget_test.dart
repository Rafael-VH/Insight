import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:insight/core/injection/injection_container.dart' as di;
import 'package:insight/features/navigation/presentation/screens/main_screen.dart';
import 'package:insight/features/upload/presentation/screens/home/upload_home_screen.dart';
import 'package:insight/main.dart';

void main() {
  testWidgets('app arranca hasta MainScreen tras el splash', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await di.init();
    await tester.pumpWidget(const MyApp());
    // Tiempo para que ThemeBloc cargue el tema
    await tester.pump(const Duration(milliseconds: 500));
    // Secuencia del splash: 200+900+100+1200+900+500ms (3.8s).
    // Pasos cortos: cada await de la secuencia necesita su propio frame para
    // continuar (timer -> animación -> timer). 50 pasos de 100ms = 5s cubren todo.
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Frame del pushReplacement
    await tester.pump();

    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.byType(UploadHomeScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Inicio'), findsOneWidget);
  });
}