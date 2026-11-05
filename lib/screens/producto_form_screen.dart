import 'package:flutter/material.dart';

import '../models/producto/producto.dart';
import '../services/remote/api_service.dart';
import '../services/remote/producto_service.dart';

/// Pantalla de formulario para crear y editar productos de FluxisStore.
///
/// Si [producto] es `null`, opera en modo **crear** (POST /productos).
/// Si [producto] no es `null`, opera en modo **editar** (PUT /productos/$sku)
/// y precarga los datos actuales del producto.
///
/// El campo SKU no es editable: en modo crear el servidor lo asigna, y en
/// modo editar se conserva el SKU original.
class ProductoFormScreen extends StatefulWidget {
  const ProductoFormScreen({super.key, this.producto});

  /// Producto a editar. Si es `null`, la pantalla opera en modo crear.
  final Producto? producto;

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _service = ProductoService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _descripcionController;
  late final TextEditingController _precioController;
  late final TextEditingController _stockController;

  bool _isSaving = false;

  bool get _isEditMode => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _descripcionController = TextEditingController(text: p?.descripcion ?? '');
    _precioController =
        TextEditingController(text: p != null ? _numToString(p.precio) : '');
    _stockController =
        TextEditingController(text: p != null ? '${p.stock}' : '');
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  /// Convierte un [num] a string, omitiendo el decimal si es un entero.
  String _numToString(num value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  // ---------------------------------------------------------------------------
  // Validadores
  // ---------------------------------------------------------------------------

  String? _validateDescripcion(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La descripción es obligatoria';
    }
    return null;
  }

  String? _validatePrecio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El precio es obligatorio';
    }
    final precio = num.tryParse(value.trim());
    if (precio == null) {
      return 'El precio debe ser un número válido';
    }
    if (precio < 0) {
      return 'El precio no puede ser negativo';
    }
    return null;
  }

  String? _validateStock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El stock es obligatorio';
    }
    final stock = int.tryParse(value.trim());
    if (stock == null) {
      return 'El stock debe ser un número entero válido';
    }
    if (stock < 0) {
      return 'El stock no puede ser negativo';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Guardar
  // ---------------------------------------------------------------------------

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final descripcion = _descripcionController.text.trim();
    final precio = num.parse(_precioController.text.trim());
    final stock = int.parse(_stockController.text.trim());

    try {
      if (_isEditMode) {
        final producto = Producto(
          sku: widget.producto!.sku,
          descripcion: descripcion,
          precio: precio,
          stock: stock,
        );
        final response =
            await _service.actualizarProducto(widget.producto!.sku, producto);
        if (response.isSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto actualizado exitosamente'),
                backgroundColor: Color(0xFF00695C),
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          _showError(response.message ?? 'Error al actualizar el producto.');
        }
      } else {
        final producto = Producto(
          sku: 0,
          descripcion: descripcion,
          precio: precio,
          stock: stock,
        );
        final response = await _service.crearProducto(producto);
        if (response.isSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto creado exitosamente'),
                backgroundColor: Color(0xFF00695C),
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          _showError(response.message ?? 'Error al crear el producto.');
        }
      }
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar producto' : 'Nuevo producto'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildDescripcionField(),
              const SizedBox(height: 16),
              _buildPrecioField(),
              const SizedBox(height: 16),
              _buildStockField(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescripcionField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Descripción',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF00695C),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ingrese la descripción del producto',
                prefixIcon: Icon(Icons.description),
              ),
              validator: _validateDescripcion,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrecioField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Precio',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF00695C),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '0.00',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _validatePrecio,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stock',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF00695C),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '0',
                prefixIcon: Icon(Icons.inventory),
              ),
              keyboardType: TextInputType.number,
              validator: _validateStock,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _guardar,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(_isEditMode ? Icons.save : Icons.check),
        label: Text(_isEditMode ? 'Guardar cambios' : 'Crear producto'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00695C),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF00695C).withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
