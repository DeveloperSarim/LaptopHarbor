import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  bool isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    _slideController.forward();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await Supabase.instance.client.from('cart').select('''
            *,
            products!inner(
              *,
              brands!inner(name),
              product_images!inner(image_url, is_primary)
            )
          ''').eq('user_id', user.id);

      setState(() {
        cartItems = response.map((item) {
          final product = item['products'];
          final images = product['product_images'] as List;
          final primaryImage = images.firstWhere(
            (img) => img['is_primary'] == true,
            orElse: () => images.isNotEmpty ? images.first : null,
          );

          return {
            'id': item['id'],
            'product_id': product['id'],
            'name': product['name'],
            'brand': product['brands']['name'],
            'price': product['price'],
            'originalPrice': product['original_price'],
            'image': primaryImage?['image_url'] ??
                'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400',
            'quantity': item['quantity'],
            'specs': [
              product['processor'] ?? 'Intel Core',
              product['ram'] ?? '16GB RAM',
              product['storage'] ?? '512GB SSD'
            ].where((spec) => spec.isNotEmpty).toList(),
            'discount': product['original_price'] != null
                ? (((product['original_price'] - product['price']) /
                            product['original_price']) *
                        100)
                    .round()
                : 0,
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading cart items: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  double get subtotal {
    return cartItems.fold(
        0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  double get totalSavings {
    return cartItems.fold(
        0,
        (sum, item) =>
            sum +
            ((item['originalPrice'] ?? item['price']) - item['price']) *
                item['quantity']);
  }

  double get tax => subtotal * 0.18; // 18% GST
  double get shipping => subtotal > 50000 ? 0 : 500;
  double get total => subtotal + tax + shipping;

  void _updateQuantity(String cartId, String productId, int newQuantity) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      if (newQuantity <= 0) {
        await Supabase.instance.client.from('cart').delete().eq('id', cartId);

        setState(() {
          cartItems.removeWhere((item) => item['id'] == cartId);
        });
      } else {
        await Supabase.instance.client
            .from('cart')
            .update({'quantity': newQuantity}).eq('id', cartId);

        setState(() {
          final index = cartItems.indexWhere((item) => item['id'] == cartId);
          if (index != -1) {
            cartItems[index]['quantity'] = newQuantity;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating cart', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearCart() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('cart')
          .delete()
          .eq('user_id', user.id);

      setState(() {
        cartItems.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Cart cleared successfully', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing cart', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: SpinKitFadingCircle(
          color: Color(0xFF667eea),
          size: 50,
        ),
      );
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          _buildCartHeader(),
          Expanded(
            child: cartItems.isEmpty ? _buildEmptyCart() : _buildCartContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCartHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shopping Cart',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2D3748),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${cartItems.length} items in cart',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Clear Cart', style: GoogleFonts.poppins()),
                    content: Text(
                      'Are you sure you want to remove all items from your cart?',
                      style: GoogleFonts.poppins(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearCart();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Clear Cart'),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                'Clear Cart',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some amazing laptops to get started!',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // You can navigate back to home tab
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Start Shopping',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Savings banner
                if (totalSavings > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                      ),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.savings, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'You\'re saving PKR ${totalSavings.toStringAsFixed(0)} on this order!',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Cart items list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 32),
                    itemBuilder: (context, index) =>
                        _buildCartItemCard(cartItems[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildOrderSummary(),
      ],
    );
  }

  Widget _buildCartItemCard(Map<String, dynamic> item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: item['image'],
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            placeholder: (context, url) => const SpinKitFadingCircle(
              color: Color(0xFF667eea),
              size: 30,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['brand'],
                style: GoogleFonts.poppins(
                  color: const Color(0xFF667eea),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                item['name'],
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (item['specs'] != null && item['specs'].isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: item['specs']
                      .map<Widget>((spec) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              spec,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'PKR ${item['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (item['originalPrice'] != null &&
                      item['originalPrice'] > item['price'])
                    Text(
                      'PKR ${item['originalPrice'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[500],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (item['discount'] > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item['discount']}% OFF',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _updateQuantity(
                        item['id'], item['product_id'], item['quantity'] - 1),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.remove, size: 16),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      item['quantity'].toString(),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _updateQuantity(
                        item['id'], item['product_id'], item['quantity'] + 1),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.add, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _updateQuantity(item['id'], item['product_id'], 0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete, color: Colors.red[600], size: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal', 'PKR ${subtotal.toStringAsFixed(0)}'),
          if (totalSavings > 0)
            _buildSummaryRow(
                'Savings', '-PKR ${totalSavings.toStringAsFixed(0)}',
                isDiscount: true),
          _buildSummaryRow('GST (18%)', 'PKR ${tax.toStringAsFixed(0)}'),
          _buildSummaryRow('Shipping',
              shipping == 0 ? 'FREE' : 'PKR ${shipping.toStringAsFixed(0)}',
              isShipping: true),
          const Divider(height: 24),
          _buildSummaryRow('Total', 'PKR ${total.toStringAsFixed(0)}',
              isTotal: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isPlacingOrder
                  ? null
                  : () {
                      _showCheckoutDialog();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isPlacingOrder
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Proceed to Checkout',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isTotal = false,
      bool isDiscount = false,
      bool isShipping = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFF2D3748),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isDiscount
                  ? Colors.green[600]
                  : isShipping && value == 'FREE'
                      ? Colors.green[600]
                      : isTotal
                          ? const Color(0xFF667eea)
                          : const Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Checkout', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '${cartItems.length} items',
              style: GoogleFonts.poppins(),
            ),
            Text(
              'Total: PKR ${total.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Proceed to payment gateway?',
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _placeOrder();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
            ),
            child: const Text('Place Order',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      isPlacingOrder = true;
    });

    try {
      // Create order
      final orderResponse = await Supabase.instance.client
          .from('orders')
          .insert({
            'user_id': user.id,
            'subtotal': subtotal,
            'tax_amount': tax,
            'shipping_amount': shipping,
            'total_amount': total,
            'status': 'pending',
            'payment_status': 'pending',
          })
          .select()
          .single();

      // Create order items
      final orderItems = cartItems
          .map((item) => {
                'order_id': orderResponse['id'],
                'product_id': item['product_id'],
                'product_name': item['name'],
                'unit_price': item['price'],
                'quantity': item['quantity'],
                'total_price': item['price'] * item['quantity'],
              })
          .toList();

      await Supabase.instance.client.from('order_items').insert(orderItems);

      // Clear cart
      await Supabase.instance.client
          .from('cart')
          .delete()
          .eq('user_id', user.id);

      setState(() {
        cartItems.clear();
        isPlacingOrder = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order placed successfully! Order #${orderResponse['order_number']}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // You can navigate to order confirmation screen here
    } catch (e) {
      setState(() {
        isPlacingOrder = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: ${e.toString()}',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
