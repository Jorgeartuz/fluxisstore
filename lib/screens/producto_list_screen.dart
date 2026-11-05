import 'package:flutter/material.dart';

import '../models/producto/producto.dart';
import '../services/remote/api_service.dart';
import '../services/remote/producto_service.dart';
import 'producto_detail_screen.dart';
import 'producto_form_screen.dart';

/// Pantalla de listado de productos de FluxisStore.
///
/// Consulta los productos reales mediante [ProductoService.listarProductos] y
/// los presenta en tarjetas. Maneja los estados de carga, error, lista vacía
/// y éxito. Incluye un botón flotante para agregar productos y permite
/// acceder al detalle de cada producto.
class ProductoListScreen extends StatefulWidget {
  const ProductoListScreen({super.key});

  @override
  State<ProductoListScreen> createState() => _ProductoListScreenState();
}

class _ProductoListScreenState extends State<ProductoListScreen> {
  final _service = ProductoService();
  List<Producto>? _productos;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _service.listarProductos();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _productos = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response.message ?? 'Error al cargar los productos.';
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

  Future<void> _irADetalle(Producto producto) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductoDetailScreen(sku: producto.sku),
      ),
    );
    if (result == true && mounted) {
      _cargarProductos();
    }
  }

  Future<void> _irACrear() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ProductoFormScreen(),
      ),
    );
    if (result == true && mounted) {
      _cargarProductos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Productos'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargarProductos,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _irACrear,
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_productos == null || _productos!.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _cargarProductos,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _productos!.length,
        itemBuilder: (_, index) => _buildProductCard(_productos![index]),
      ),
    );
  }

  Widget _buildErrorState() {
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
              onPressed: _cargarProductos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No hay productos registrados',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _irACrear,
              icon: const Icon(Icons.add),
              label: const Text('Agregar producto'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Producto producto) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00695C).withValues(alpha: 0.1),
          child: const Icon(Icons.inventory_2_outlined,
              color: Color(0xFF00695C)),
        ),
        title: Text(
          producto.descripcion,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('SKU: ${producto.sku}'),
            Row(
              children: [
                const Icon(Icons.inventory, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Stock: ${producto.stock}'),
              ],
            ),
          ],
        ),
        trailing: Text(
          '\$${producto.precio.toDouble().toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00695C),
          ),
        ),
        onTap: () => _irADetalle(producto),
      ),
    );
  }
}
