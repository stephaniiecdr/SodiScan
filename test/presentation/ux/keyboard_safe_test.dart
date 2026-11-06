import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_consumption_repository.dart';
import '../../helpers/pump_home_app.dart';

void main() {
  const smallPhone = Size(360, 640);
  const keyboardHeight = 300.0;

  late FakeConsumptionRepository repository;

  setUp(() => repository = FakeConsumptionRepository(items: [indomieConsumption()]));

  Finder productName() => find.byKey(const Key('productNameField'));
  Finder sodium() => find.byKey(const Key('sodiumField'));
  Finder submit() => find.byKey(const Key('submitButton'));

  bool hasFocus(WidgetTester tester, Finder field) {
    return tester.widget<EditableText>(find.descendant(of: field, matching: find.byType(EditableText))).focusNode.hasFocus;
  }

  Future<void> openManualInput(WidgetTester tester) async {
    await pumpHomeApp(tester, repository: repository, size: smallPhone);
    await tester.tap(find.byKey(const Key('manualInputButton')));
    await tester.pumpAndSettle();
  }

  Future<void> showKeyboard(WidgetTester tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboardHeight);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
  }

  testWidgets('field aktif dan tombol Simpan tetap terlihat di atas keyboard', (tester) async {
    await openManualInput(tester);

    await tester.tap(sodium());
    await showKeyboard(tester);

    const visibleBottom = 640 - keyboardHeight;
    expect(tester.getRect(sodium()).bottom, lessThanOrEqualTo(visibleBottom));
    expect(tester.getRect(submit()).bottom, lessThanOrEqualTo(visibleBottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tombol Next di keyboard pindah ke field sodium, Done langsung menyimpan', (tester) async {
    await openManualInput(tester);

    await tester.tap(productName());
    await tester.enterText(productName(), 'Bakso');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(hasFocus(tester, sodium()), isTrue);

    await tester.enterText(sodium(), '600');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Konsumsi berhasil disimpan.'), findsOneWidget);
    expect(find.text('Bakso'), findsOneWidget);
  });

  testWidgets('validasi gagal memfokuskan field pertama yang salah agar terlihat', (tester) async {
    await openManualInput(tester);

    await tester.tap(submit());
    await tester.pump();
    expect(hasFocus(tester, productName()), isTrue);

    await tester.enterText(productName(), 'Bakso');
    await tester.ensureVisible(submit());
    await tester.tap(submit());
    await tester.pump();
    expect(hasFocus(tester, sodium()), isTrue);
    expect(find.text('Jumlah sodium wajib diisi.'), findsOneWidget);
  });

  testWidgets('tap di luar field menutup keyboard', (tester) async {
    await openManualInput(tester);

    await tester.tap(productName());
    await tester.pump();
    expect(hasFocus(tester, productName()), isTrue);

    await tester.tapAt(tester.getCenter(find.textContaining('Gunakan Input Manual')));
    await tester.pump();
    expect(hasFocus(tester, productName()), isFalse);
  });
}
