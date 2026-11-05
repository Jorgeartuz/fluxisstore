import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fluxisstore_app/main.dart';
import 'package:fluxisstore_app/models/producto/producto.dart';
import 'package:fluxisstore_app/models/producto/producto_response.dart';
import 'package:fluxisstore_app/screens/producto_delete_dialog.dart';
import 'package:fluxisstore_app/screens/producto_list_screen.dart';
import 'package:fluxisstore_app/services/remote/api_service.dart';
import 'package:fluxisstore_app/services/remote/producto_service.dart';

/// [HttpOverrides] que evita solicitudes de red reales durante las pruebas.
/// Cualquier intento de abrir una conexión lanza [SocketException], que el
/// [ApiService] convierte en [NetworkException] con el mensaje
/// "Unable to connect to the server."
class NoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return NoNetworkHttpClient();
  }
}

class NoNetworkHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    throw const SocketException('No network access in tests');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Crea un [ProductoService] con un [MockClient] que responde según el
/// handler proporcionado.
ProductoService createService(MockClientHandler handler) {
  final mockClient = MockClient(handler);
  final apiService = ApiService(
    baseUrl: 'https://test.fluxis.co',
    client: mockClient,
  );
  return ProductoService(apiService: apiService);
}

void main() {
  // ===========================================================================
  // Modelo Producto
  // ===========================================================================

  group('Producto model', () {
    test('fromJson parsea correctamente todos los campos', () {
      final json = <String, dynamic>{
        'sku': 1,
        'descripcion': 'Lápiz azul',
        'precio': 1500,
        'stock': 50,
      };

      final producto = Producto.fromJson(json);

      expect(producto.sku, 1);
      expect(producto.descripcion, 'Lápiz azul');
      expect(producto.precio, 1500);
      expect(producto.stock, 50);
    });

    test('toJson serializa correctamente todos los campos', () {
      const producto = Producto(
        sku: 2,
        descripcion: 'Cuaderno',
        precio: 3500.50,
        stock: 12,
      );

      final json = producto.toJson();

      expect(json['sku'], 2);
      expect(json['descripcion'], 'Cuaderno');
      expect(json['precio'], 3500.50);
      expect(json['stock'], 12);
    });

    test('copyWith crea una copia con los campos modificados', () {
      const original = Producto(
        sku: 1,
        descripcion: 'Original',
        precio: 100,
        stock: 10,
      );

      final copia = original.copyWith(descripcion: 'Modificado', stock: 20);

      expect(copia.sku, 1);
      expect(copia.descripcion, 'Modificado');
      expect(copia.precio, 100);
      expect(copia.stock, 20);
    });
  });

  // ===========================================================================
  // Parsers de ProductoResponse
  // ===========================================================================

  group('ProductoResponse parsers', () {
    test('fromJsonList extrae la lista de la envoltura data', () {
      final json = <String, dynamic>{
        'total': 2,
        'data': [
          <String, dynamic>{
            'sku': 1,
            'descripcion': 'Lápiz',
            'precio': 100,
            'stock': 10,
          },
          <String, dynamic>{
            'sku': 2,
            'descripcion': 'Borrador',
            'precio': 200,
            'stock': 5,
          },
        ],
      };

      final lista = ProductoResponse.fromJsonList(json);

      expect(lista.length, 2);
      expect(lista[0].sku, 1);
      expect(lista[0].descripcion, 'Lápiz');
      expect(lista[1].sku, 2);
      expect(lista[1].descripcion, 'Borrador');
    });

    test('fromJsonDetail extrae el objeto interno de data', () {
      final json = <String, dynamic>{
        'data': <String, dynamic>{
          'sku': 1,
          'descripcion': 'Lápiz',
          'precio': 100,
          'stock': 10,
        },
      };

      final producto = ProductoResponse.fromJsonDetail(json);

      expect(producto.sku, 1);
      expect(producto.descripcion, 'Lápiz');
      expect(producto.precio, 100);
      expect(producto.stock, 10);
    });

    test('fromJsonCreateUpdate extrae el objeto de la respuesta de crear', () {
      final json = <String, dynamic>{
        'message': 'Producto creado exitosamente',
        'data': <String, dynamic>{
          'sku': 5,
          'descripcion': 'Regla',
          'precio': 800,
          'stock': 30,
        },
      };

      final producto = ProductoResponse.fromJsonCreateUpdate(json);

      expect(producto.sku, 5);
      expect(producto.descripcion, 'Regla');
    });

    test('parserCreateUpdate acepta dynamic y delega en fromJsonCreateUpdate', () {
      final json = <String, dynamic>{
        'message': 'Producto actualizado',
        'data': <String, dynamic>{
          'sku': 5,
          'descripcion': 'Regla larga',
          'precio': 900,
          'stock': 25,
        },
      };

      final producto = ProductoResponse.parserCreateUpdate(json);

      expect(producto.sku, 5);
      expect(producto.descripcion, 'Regla larga');
      expect(producto.precio, 900);
    });
  });

  // ===========================================================================
  // ProductoService con MockClient
  // ===========================================================================

  group('ProductoService con MockClient', () {
    test('listarProductos devuelve lista en respuesta exitosa', () async {
      final service = createService((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/productos');
        return http.Response(
          jsonEncode({
            'total': 2,
            'data': [
              {'sku': 1, 'descripcion': 'A', 'precio': 10, 'stock': 5},
              {'sku': 2, 'descripcion': 'B', 'precio': 20, 'stock': 3},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final response = await service.listarProductos();

      expect(response.isSuccess, true);
      expect(response.data, isNotNull);
      expect(response.data!.length, 2);
      expect(response.data![0].sku, 1);
      expect(response.data![1].descripcion, 'B');
    });

    test('consultarProducto devuelve producto en respuesta exitosa', () async {
      final service = createService((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/productos/1');
        return http.Response(
          jsonEncode({
            'data': {'sku': 1, 'descripcion': 'Lápiz', 'precio': 100, 'stock': 10},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final response = await service.consultarProducto(1);

      expect(response.isSuccess, true);
      expect(response.data, isNotNull);
      expect(response.data!.sku, 1);
      expect(response.data!.descripcion, 'Lápiz');
    });

    test('crearProducto devuelve producto creado en respuesta exitosa', () async {
      final service = createService((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/productos');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['descripcion'], 'Nuevo');
        expect(body['precio'], 500);
        return http.Response(
          jsonEncode({
            'message': 'Producto creado exitosamente',
            'data': {'sku': 10, 'descripcion': 'Nuevo', 'precio': 500, 'stock': 8},
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      const producto = Producto(
        sku: 0,
        descripcion: 'Nuevo',
        precio: 500,
        stock: 8,
      );

      final response = await service.crearProducto(producto);

      expect(response.isSuccess, true);
      expect(response.data, isNotNull);
      expect(response.data!.sku, 10);
    });

    test('actualizarProducto devuelve producto actualizado en respuesta exitosa',
        () async {
      final service = createService((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/productos/1');
        return http.Response(
          jsonEncode({
            'message': 'Producto actualizado',
            'data': {'sku': 1, 'descripcion': 'Editado', 'precio': 150, 'stock': 20},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      const producto = Producto(
        sku: 1,
        descripcion: 'Editado',
        precio: 150,
        stock: 20,
      );

      final response = await service.actualizarProducto(1, producto);

      expect(response.isSuccess, true);
      expect(response.data, isNotNull);
      expect(response.data!.descripcion, 'Editado');
    });

    test('eliminarProducto devuelve éxito en respuesta 200', () async {
      final service = createService((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/productos/1');
        return http.Response(
          jsonEncode({'message': 'Producto eliminado exitosamente'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final response = await service.eliminarProducto(1);

      expect(response.isSuccess, true);
    });

    test('listarProductos maneja error HTTP 500', () async {
      final service = createService((request) async {
        return http.Response(
          jsonEncode({'message': 'Error interno del servidor'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final response = await service.listarProductos();

      expect(response.isSuccess, false);
      expect(response.data, isNull);
      expect(response.message, 'Error interno del servidor');
    });

    test('consultarProducto maneja error 404', () async {
      final service = createService((request) async {
        return http.Response(
          jsonEncode({'message': 'Producto no encontrado'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final response = await service.consultarProducto(999);

      expect(response.isSuccess, false);
      expect(response.isNotFound, true);
      expect(response.message, 'Producto no encontrado');
    });
  });

  // ===========================================================================
  // Diálogo de confirmación de eliminación
  // ===========================================================================

  group('showDeleteConfirmationDialog', () {
    testWidgets('devuelve false al presionar Cancelar', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDeleteConfirmationDialog(context);
              },
              child: const Text('Mostrar'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mostrar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar producto?'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('devuelve true al presionar Eliminar', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDeleteConfirmationDialog(context);
              },
              child: const Text('Mostrar'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mostrar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(result, true);
    });
  });

  // ===========================================================================
  // Widget tests de la aplicación
  // ===========================================================================

  group('FluxisStoreApp', () {
    testWidgets('rendera MaterialApp sin errores', (tester) async {
      HttpOverrides.global = NoNetworkHttpOverrides();
      addTearDown(() => HttpOverrides.global = null);

      await tester.pumpWidget(const FluxisStoreApp());

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('ProductoListScreen', () {
    setUp(() {
      HttpOverrides.global = NoNetworkHttpOverrides();
    });

    tearDown(() {
      HttpOverrides.global = null;
    });

    testWidgets('muestra indicador de carga al iniciar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProductoListScreen()),
      );

      // El primer frame muestra el estado de carga.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra AppBar con título Productos', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProductoListScreen()),
      );

      expect(find.text('Productos'), findsOneWidget);
    });

    testWidgets('muestra botón flotante para agregar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProductoListScreen()),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('muestra mensaje de error cuando no hay conexión',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProductoListScreen()),
      );

      // Avanza los frames hasta que la operación async falle.
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}
