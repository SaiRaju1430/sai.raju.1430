import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/order_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';

class ProductScreen extends StatelessWidget {
  final ProductModel product;

  const ProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final inCartQty = orderProvider.cart[product.id]?.quantity ?? 0;
    final isOutOfStock = product.quantity <= 0 || !product.available;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.shopping_bag_outlined,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Product Details Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.category,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name and Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Stock Count
                  Text(
                    isOutOfStock 
                        ? 'Temporarily Out of Stock' 
                        : '${product.quantity} items left in stock',
                    style: TextStyle(
                      fontSize: 14,
                      color: isOutOfStock 
                          ? Colors.red 
                          : (product.quantity < 5 ? Colors.orange.shade800 : AppTheme.textSecondary),
                      fontWeight: product.quantity < 5 || isOutOfStock ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Divider(),
                  const SizedBox(height: 12),

                  // Description
                  const Text(
                    'Product Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get this fresh ${product.category} item delivered straight to your hostel building. CampusKart delivers directly to your door at the speed of campus life.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Add / Remove Cart Button
                  if (inCartQty > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Minus
                        IconButton(
                          onPressed: () => orderProvider.removeFromCart(product.id),
                          icon: const Icon(Icons.remove, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Text(
                          '$inCartQty in Cart',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Plus
                        IconButton(
                          onPressed: () => orderProvider.addToCart(product),
                          icon: const Icon(Icons.add, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    )
                  else
                    CustomButton(
                      text: isOutOfStock ? 'OUT OF STOCK' : 'ADD TO CART',
                      onPressed: isOutOfStock || !orderProvider.isOwnerAvailable
                          ? null 
                          : () {
                              orderProvider.addToCart(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added item to cart!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
