/// Configuración centralizada de FluxisStore.
///
/// Contiene constantes de configuración de la aplicación, como la URL base
/// de la API REST. Centralizar estos valores evita hardcodear URLs en los
/// servicios y facilita el cambio de entorno (desarrollo, producción, etc.).
class AppConfig {
  AppConfig._();

  /// URL base de la API REST de FluxisStore.
  ///
  /// Todas las peticiones de [ApiService] se construyen a partir de esta URL.
  /// El recurso de productos se accede mediante el endpoint `/productos`.
  static const String apiBaseUrl = 'https://fluxisstore.apis.fluxis.co';
}
