
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/product_model.dart';

class ProductForm extends StatefulWidget {
  final Product? product;
  final void Function(Product product) onSubmit;

  const ProductForm({
    super.key,
    this.product,
    required this.onSubmit,
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _categoryController;
  late final TextEditingController _brandController;
  late final TextEditingController _stockController;
  late final TextEditingController _imageController;

  @override
  void initState() {
    super.initState();

    final p = widget.product;

    _titleController = TextEditingController(text: p?.title ?? '');
    _descriptionController =
        TextEditingController(text: p?.description ?? '');
    _priceController =
        TextEditingController(text: p?.price.toString() ?? '');
    _categoryController =
        TextEditingController(text: p?.category ?? '');
    _brandController =
        TextEditingController(text: p?.brand ?? '');
    _stockController =
        TextEditingController(text: p?.stock.toString() ?? '1');
    _imageController =
        TextEditingController(text: p?.thumbnail ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) return;

    final old = widget.product;

    final product = Product(
      id: old?.id ?? 0,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _categoryController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      rating: old?.rating ?? 0,
      stock: int.tryParse(_stockController.text.trim()) ?? 0,
      brand: _brandController.text.trim().isEmpty
          ? 'Unknown'
          : _brandController.text.trim(),
      thumbnail: _imageController.text.trim(),
      images: _imageController.text.trim().isEmpty
          ? []
          : [_imageController.text.trim()],
    );

    widget.onSubmit(product);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _field(_titleController, 'Product Name'),
          _field(_descriptionController, 'Description', maxLines: 3),
          _field(
            _priceController,
            'Price',
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: (value) {
              if (value == null || double.tryParse(value) == null ||
                  double.parse(value) <= 0) {
                return 'Enter a valid price';
              }
              return null;
            },
          ),
          _field(_categoryController, 'Category'),
          _field(_brandController, 'Brand', required: false),
          _field(
            _stockController,
            'Stock',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || int.tryParse(value) == null ||
                  int.parse(value) < 0) {
                return 'Enter a valid stock';
              }
              return null;
            },
          ),
          _field(_imageController, 'Image URL', required: false),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saveProduct,
              icon: const Icon(Icons.save),
              label: Text(
                widget.product == null
                    ? 'Add Product'
                    : 'Update Product',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
      TextEditingController controller,
      String label, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
        bool required = true,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator ?? (required ? _validate : null),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
