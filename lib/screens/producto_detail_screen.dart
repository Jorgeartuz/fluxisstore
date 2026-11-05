import 'package:flutter/material.dart';

import '../models/producto/producto.dart';
import '../services/remote/api_service.dart';
import '../services/remote/producto_service.dart';
import 'producto_delete_dialog.dart';
import 'producto_form_screen.dart';

/// Pantalla de detalle de un producto de FluxisStore.
///
/// Consulta los datos mediante [ProductoService.consultarProducto] y muestra
/// SKU, descripción, precio y stock. Incluye botones para editar y eliminar
/// el producto.
class ProductoDetailScreen extends StatefulWidget {
  const ProductoDetailScreen({super.key, required this.sku});

  final int sku;

  @override
  State<ProductoDetailScreen> createState() => _ProductoDetailScreenState();
}

class _ProductoDetailScreenState extends State<ProductoDetailScreen> {
  final _service = ProductoService();
  Producto? _producto;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarProducto();
  }

  Future<void> _cargarProducto() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _service.consultarProducto(widget.sku);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _producto = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response.message ?? 'Error al cargar el producto.';
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _irAEditar() async {
    if (_producto == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductoFormScreen(producto: _producto),
      ),
    );
    if (result == true && mounted) {
      _cargarProducto();
    }
  }

  Future<void> _confirmarEliminacion() async {
    final confirmed = await showDeleteConfirmationDialog(context);
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final response = await _service.eliminarProducto(widget.sku);
      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto eliminado exitosamente'),
              backgroundColor: Color(0xFF00695C),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  response.message ?? 'Error al eliminar el producto.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Detalle del producto'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _cargarProducto,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_producto == null) {
      return const Center(child: Text('No se encontró el producto.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProductCard(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    final p = _producto!;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF00695C).withValues(alpha: 0.1),
              child: const Icon(Icons.inventory_2_outlined,
                  size: 36, color: Color(0xFF00695C)),
            ),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.tag, 'SKU', '${p.sku}'),
            const Divider(height: 24),
            _buildDetailRow(
                Icons.description, 'Descripción', p.descripcion),
            const Divider(height: 24),
            _buildDetailRow(
                Icons.attach_money, 'Precio',
                '\$${p.precio.toDouble().toStringAsFixed(2)}'),
            const Divider(height: 24),
            _buildDetailRow(Icons.inventory, 'Stock', '${p.stock}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00695C), size: 22),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _irAEditar,
            icon: const Icon(Icons.edit),
            label: const Text('Editar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00695C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _confirmarEliminacion,
            icon: const Icon(Icons.delete),
            label: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
