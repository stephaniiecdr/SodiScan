import 'package:flutter/widgets.dart';

/// Ruang ekstra di bawah field saat discroll ke atas keyboard, supaya pesan error
/// dan tombol simpan di bawahnya ikut terlihat.
const EdgeInsets fieldScrollPadding = EdgeInsets.fromLTRB(20, 20, 20, 160);

void dismissKeyboard([PointerDownEvent? _]) => FocusManager.instance.primaryFocus?.unfocus();
