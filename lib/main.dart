import 'package:flutter/material.dart';

import 'screens/producto_list_screen.dart';

void main() {
  runApp(const FluxisStoreApp());
}

/// Widget raíz de la aplicación FluxisStore.
///
/// Configura el [MaterialApp] con el tema visual de FluxisStore: color
/// principal verde azulado `#00695C`, fondo gris claro `#F5F5F5` y
/// pantalla inicial en [ProductoListScreen].
class FluxisStoreApp extends StatelessWidget {
  const FluxisStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FluxisStore',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C),
          primary: const Color(0xFF00695C),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00695C),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00695C),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00695C),
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      home: const ProductoListScreen(),
    );
  }
}
