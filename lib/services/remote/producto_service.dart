import '../../config/app_config.dart';
import '../../models/producto/producto.dart';
import '../../models/producto/producto_response.dart';
import 'api_service.dart';

/// Servicio de productos de FluxisStore.
///
/// Encapsula las cinco operaciones CRUD del recurso `/productos` utilizando
/// exclusivamente [ApiService] del profesor como cliente HTTP. Cada método
/// devuelve un [ApiResponse] para que la UI decida cómo presentar el resultado
/// (éxito, error HTTP o error de red).
///
/// **Convención de la API de FluxisStore:**
/// - Los errores HTTP (4xx/5xx) se devuelven como [ApiResponse] con
///   [ApiResponse.message] y [ApiResponse.rawData].
/// - Los errores de red, timeout o conversión se lanzan como [ApiException]
///   ([NetworkException], [ApiTimeoutException], [ApiParseException]).
///
/// La UI debe verificar [ApiResponse.isSuccess] antes de consumir
/// [ApiResponse.data].
class ProductoService {
  ProductoService({ApiService? apiService})
      : _api = apiService ?? ApiService(baseUrl: AppConfig.apiBaseUrl);

  final ApiService _api;

  // ---------------------------------------------------------------------------
  // Listar
  // ---------------------------------------------------------------------------

  /// Obtiene el listado completo de productos.
  ///
  /// **Endpoint:** `GET /productos`
  ///
  /// **Respuesta:** `{"total": 8, "data": [...]}`
  ///
  /// Devuelve [ApiResponse] con `data` de tipo `List<Producto>`. En caso de
  /// error HTTP, `data` será `null` y [ApiResponse.message] contendrá el
  /// mensaje del servidor.
  Future<ApiResponse<List<Producto>>> listarProductos() async {
    return _api.get<List<Producto>>(
      '/productos',
      fromJsonList: ProductoResponse.fromJsonList,
    );
  }

  // ---------------------------------------------------------------------------
  // Consultar
  // ---------------------------------------------------------------------------

  /// Obtiene el detalle de un producto por su [sku].
  ///
  /// **Endpoint:** `GET /productos/$sku`
  ///
  /// **Respuesta:** `{"data": {...}}`
  ///
  /// Devuelve [ApiResponse] con `data` de tipo [Producto]. En caso de error
  /// HTTP (por ejemplo, 404 si el SKU no existe), `data` será `null` y
  /// [ApiResponse.message] contendrá el mensaje del servidor.
  Future<ApiResponse<Producto>> consultarProducto(int sku) async {
    return _api.get<Producto>(
      '/productos/$sku',
      fromJson: ProductoResponse.fromJsonDetail,
    );
  }

  // ---------------------------------------------------------------------------
  // Crear
  // ---------------------------------------------------------------------------

  /// Crea un nuevo producto.
  ///
  /// **Endpoint:** `POST /productos`
  ///
  /// **Respuesta:** `{"message": "...", "data": {...}}`
  ///
  /// Envía [producto.toJson()] como cuerpo. Devuelve [ApiResponse] con el
  /// producto creado (incluyendo cualquier campo asignado por el servidor).
  /// En caso de error HTTP, `data` será `null` y [ApiResponse.message]
  /// contendrá el mensaje del servidor.
  Future<ApiResponse<Producto>> crearProducto(Producto producto) async {
    return _api.post<Producto>(
      '/productos',
      body: producto.toJson(),
      fromJson: ProductoResponse.fromJsonCreateUpdate,
    );
  }

  // ---------------------------------------------------------------------------
  // Actualizar
  // ---------------------------------------------------------------------------

  /// Actualiza un producto existente por su [sku].
  ///
  /// **Endpoint:** `PUT /productos/$sku`
  ///
  /// **Respuesta:** `{"message": "...", "data": {...}}`
  ///
  /// Envía [producto.toJson()] como cuerpo. Devuelve [ApiResponse] con el
  /// producto actualizado. En caso de error HTTP, `data` será `null` y
  /// [ApiResponse.message] contendrá el mensaje del servidor.
  Future<ApiResponse<Producto>> actualizarProducto(
    int sku,
    Producto producto,
  ) async {
    return _api.put<Producto>(
      '/productos/$sku',
      body: producto.toJson(),
      parser: ProductoResponse.parserCreateUpdate,
    );
  }

  // ---------------------------------------------------------------------------
  // Eliminar
  // ---------------------------------------------------------------------------

  /// Elimina un producto por su [sku].
  ///
  /// **Endpoint:** `DELETE /productos/$sku`
  ///
  /// **Respuesta:** `{"message": "Producto eliminado exitosamente"}`
  ///
  /// No se usa parser porque la respuesta no incluye un objeto `data`. El
  /// mensaje de confirmación queda accesible en [ApiResponse.message].
  /// En caso de error HTTP, `data` será `null` y [ApiResponse.message]
  /// contendrá el mensaje del servidor.
  Future<ApiResponse<void>> eliminarProducto(int sku) async {
    return _api.delete<void>(
      '/productos/$sku',
    );
  }
}
