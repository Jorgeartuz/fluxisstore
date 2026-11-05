/// Modelo de dominio que representa un producto de FluxisStore.
///
/// Cada producto tiene un identificador único [sku], una descripción
/// textual, un precio y la cantidad disponible en inventario.
class Producto {
  final int sku;
  final String descripcion;
  final num precio;
  final int stock;

  const Producto({
    required this.sku,
    required this.descripcion,
    required this.precio,
    required this.stock,
  });

  /// Construye un [Producto] a partir del JSON de un objeto individual.
  ///
  /// Este método espera el objeto interno del producto, es decir, el
  /// contenido que la API coloca dentro de la clave `data`:
  ///
  /// ```json
  /// {"sku": 1, "descripcion": "...", "precio": 100, "stock": 10}
  /// ```
  ///
  /// La extracción de la envoltura `data` la realizan los parsers de
  /// [ProductoResponse], no este método.
  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      sku: json['sku'] as int,
      descripcion: json['descripcion'] as String,
      precio: json['precio'] as num,
      stock: json['stock'] as int,
    );
  }

  /// Serializa el producto al formato JSON que espera la API en POST y PUT.
  Map<String, dynamic> toJson() => {
        'sku': sku,
        'descripcion': descripcion,
        'precio': precio,
        'stock': stock,
      };

  /// Devuelve una copia de este producto con los campos indicados reemplazados.
  Producto copyWith({
    int? sku,
    String? descripcion,
    num? precio,
    int? stock,
  }) {
    return Producto(
      sku: sku ?? this.sku,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
    );
  }

  @override
  String toString() =>
      'Producto(sku: $sku, descripcion: $descripcion, precio: $precio, stock: $stock)';
}
