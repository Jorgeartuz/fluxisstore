import 'package:flutter/material.dart';

/// Diálogo de confirmación de eliminación de producto.
///
/// Muestra un [AlertDialog] con el mensaje "¿Eliminar producto?" y dos
/// botones: **Cancelar** y **Eliminar**.
///
/// La eliminación se ejecuta **únicamente** después de que el usuario
/// confirma. Esta función solo retorna la decisión del usuario; la llamada
/// a [ProductoService.eliminarProducto] la realiza la pantalla que invoca
/// este diálogo.
///
/// Devuelve `true` si el usuario confirma la eliminación, `false` en caso
/// contrario.
Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
          SizedBox(width: 8),
          Text('¿Eliminar producto?'),
        ],
      ),
      content: const Text(
        '¿Está seguro que desea eliminar este producto? Esta acción no se '
        'puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  return result ?? false;
}
