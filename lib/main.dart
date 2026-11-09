import 'package:flutter/material.dart';
import 'view.dart';
import 'view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final vm = ReadingViewModel();
  await vm.load();
  runApp(ReadingApp(vm: vm));
}

class ReadingApp extends StatelessWidget {
  const ReadingApp({super.key, required this.vm});
  final ReadingViewModel vm;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '余白の本棚 | 読書記録',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF31594B),
        surface: const Color(0xFFFAF9F5),
      ),
      scaffoldBackgroundColor: const Color(0xFFFAF9F5),
      fontFamily: 'Hiragino Sans',
      fontFamilyFallback: const ['Noto Sans JP', 'Yu Gothic', 'sans-serif'],
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFF343F39), height: 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF31594B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE3E6DF)),
        ),
      ),
    ),
    home: ReadingView(vm: vm),
  );
}
