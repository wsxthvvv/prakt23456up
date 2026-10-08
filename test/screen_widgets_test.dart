import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prakt2up/auth/auth_notifier.dart';
import 'package:prakt2up/core/validators.dart';
import 'package:prakt2up/screens/home_screen.dart';
import 'package:prakt2up/state/load_status.dart';
import 'package:prakt2up/storage/app_storage.dart';
import 'package:prakt2up/widgets/entity_form.dart';
import 'package:prakt2up/widgets/list_status_body.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('list shows a progress indicator while loading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ListStatusBody(
            status: LoadStatus.loading,
            error: null,
            isEmpty: false,
            onRetry: _noop,
            child: Text('каталог'),
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('каталог'), findsNothing);
  });

  testWidgets('empty list shows the empty message and hides the indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ListStatusBody(
            status: LoadStatus.success,
            error: null,
            isEmpty: true,
            onRetry: _noop,
            child: Text('каталог'),
          ),
        ),
      ),
    );
    expect(find.text('Ничего не найдено'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('failed list shows the error and repeats the request', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListStatusBody(
            status: LoadStatus.error,
            error: 'Не удалось соединиться с сервером.',
            isEmpty: false,
            onRetry: () => retries++,
            child: const Text('каталог'),
          ),
        ),
      ),
    );
    expect(find.text('Не удалось соединиться с сервером.'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    expect(retries, 1);
  });

  testWidgets('form does not accept an empty product name', (tester) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    addTearDown(name.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: Column(
              children: [
                labeledField(
                  TextFieldSpec(
                    label: 'Название',
                    controller: name,
                    validator: V.combine([
                      V.required('Укажите название'),
                      V.length(min: 2, max: 120),
                    ]),
                  ),
                ),
                FilledButton(
                  onPressed: () => formKey.currentState!.validate(),
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Сохранить'));
    await tester.pump();
    expect(find.text('Укажите название'), findsOneWidget);
  });

  testWidgets('buyer home hides administration', (tester) async {
    final prepared = await tester.runAsync(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'auth_access_token': 'access',
        'auth_refresh_token': 'refresh',
        'auth_profile': '{"id":3,"username":"buyer","fullName":"Соколова Анна","email":"anna.sokolova@nyamka.test","role":"buyer"}',
        'auth_session_started': now,
        'auth_last_activity': now,
      });
      final notifier = AuthNotifier(await SharedPreferences.getInstance());
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(requestOptions: options, statusCode: 200, data: {}),
            );
          },
        ),
      );
      notifier.bind(dio);
      await notifier.restore();
      return (
        notifier,
        AppStorage(await SharedPreferences.getInstance(), null),
      );
    });
    final auth = prepared!.$1;
    final storage = prepared.$2;
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthNotifier>.value(value: auth),
          ChangeNotifierProvider<AppStorage>.value(value: storage),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('Мои заказы'), findsOneWidget);
    expect(find.text('Пользователи'), findsNothing);
    expect(find.text('Статистика'), findsNothing);
  });
}

void _noop() {}
