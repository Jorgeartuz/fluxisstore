import 'producto.dart';

/// Parsers para las respuestas JSON de la API de FluxisStore.
///
/// FluxisStore envuelve sus respuestas de distintas maneras según la
/// operación. Esta clase centraliza la extracción de la envoltura `data`
/// para que [ProductoService] pueda entregar modelos limpios a la UI.
///
/// Estructuras de respuesta confirmadas:
///
/// - **Listado**: `{"total": 8, "data": [...]}`
/// - **Detalle**: `{"data": {...}}`
/// - **Crear / Actualizar**: `{"message": "...", "data": {...}}`
/// - **Eliminar**: `{"message": "..."}`
class ProductoResponse {
  ProductoResponse._();

  // ---------------------------------------------------------------------------
  // Listado
  // ---------------------------------------------------------------------------

  /// Parser para el listado de productos.
  ///
  /// La API devuelve:
  /// ```json
  /// {"total": 8, "data": [{"sku": 1, ...}, ...]}
  /// ```
  ///
  /// [ApiService.get] con `fromJsonList` entrega el body completo decodificado
  /// como `dynamic`. Este método extrae la lista interna de la clave `data`
  /// y convierte cada elemento a [Producto].
  static List<Producto> fromJsonList(dynamic data) {
    final map = data as Map<String, dynamic>;
    final list = map['data'] as List;
    return list
        .cast<Map<String, dynamic>>()
        .map((e) => Producto.fromJson(e))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Detalle
  // ---------------------------------------------------------------------------

  /// Parser para la consulta individual de un producto.
  ///
  /// La API devuelve:
  /// ```json
  /// {"data": {"sku": 1, "descripcion": "...", "precio": 100, "stock": 10}}
  /// ```
  ///
  /// [ApiService.get] con `fromJson` entrega el body completo decodificado
  /// como `Map<String, dynamic>`. Este método extrae el objeto interno de la
  /// clave `data` y lo convierte a [Producto].
  static Producto fromJsonDetail(Map<String, dynamic> json) {
    final inner = json['data'] as Map<String, dynamic>;
    return Producto.fromJson(inner);
  }

  // ---------------------------------------------------------------------------
  // Crear / Actualizar
  // ---------------------------------------------------------------------------

  /// Parser para las respuestas de crear y actualizar.
  ///
  /// La API devuelve:
  /// ```json
  /// {"message": "Producto creado exitosamente", "data": {"sku": 1, ...}}
  /// ```
  ///
  /// Este parser extrae el objeto interno de la clave `data` y lo convierte
  /// a [Producto]. El mensaje de confirmación queda accesible mediante
  /// [ApiResponse.message] cuando se usa sin parser (tipo `dynamic`).
  ///
  /// Se usa con `post` (parámetro `fromJson` = `FromJson<T>`).
  static Producto fromJsonCreateUpdate(Map<String, dynamic> json) {
    final inner = json['data'] as Map<String, dynamic>;
    return Producto.fromJson(inner);
  }

  /// Variante [JsonParser] (recibe `dynamic`) del parser de crear/actualizar.
  ///
  /// Se usa con `put` (parámetro `parser` = `JsonParser<T>`), ya que `put`
  /// no ofrece el parámetro `fromJson`. Internamente convierte `data` a
  /// `Map<String, dynamic>` y delega en [fromJsonCreateUpdate].
  static Producto parserCreateUpdate(dynamic data) {
    return fromJsonCreateUpdate(data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // Eliminar
  // ---------------------------------------------------------------------------

  /// La respuesta de eliminación solo contiene un mensaje:
  /// ```json
  /// {"message": "Producto eliminado exitosamente"}
  /// ```
  ///
  /// No se necesita parser porque [ApiService] ya extrae `message` de forma
  /// automática en [ApiResponse.message]. Se deja esta documentación como
  /// referencia; el servicio puede usar `delete<dynamic>` sin parser.
}
