
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/product_model.dart';
import '../../providers/product_provider.dart';
import '../widgets/product_form.dart';

class AddEditProductScreen extends StatelessWidget {
  final Product? product;

  const AddEditProductScreen({
    super.key,
    this.product,
  });

  @override
  Widget build(BuildContext context) {
    final isEditing = product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ProductForm(
          product: product,
          onSubmit: (formProduct) async {
            final provider = context.read<ProductProvider>();

            if (isEditing) {
              await provider.updateProduct(formProduct);
            } else {
              final newProduct = formProduct.copyWith(
                id: provider.generateProductId(),
              );

              await provider.addProduct(newProduct);
            }

            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEditing
                      ? 'Product updated successfully'
                      : 'Product added successfully',
                ),
              ),
            );

            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
