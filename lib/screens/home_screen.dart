import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Working Compare Screen
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> selectedLaptops = [];
  List<Map<String, dynamic>> availableLaptops = [];
  bool isComparing = false;
  bool isLoading = true;

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
    _loadLaptops();
    _loadCompareList();
  }

  Future<void> _loadLaptops() async {
    try {
      final response =
          await Supabase.instance.client.from('products').select('''
            *,
            brands!inner(name, logo_url),
            categories!inner(name),
            product_images!inner(image_url, is_primary)
          ''').eq('is_active', true).order('name').limit(20);

      setState(() {
        availableLaptops = response.map((product) {
          final images = product['product_images'] as List;
          final primaryImage = images.firstWhere(
            (img) => img['is_primary'] == true,
            orElse: () => images.isNotEmpty ? images.first : null,
          );

          return {
            'id': product['id'],
            'name': product['name'],
            'brand': product['brands']['name'],
            'price':
                'PKR ${product['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
            'image': primaryImage?['image_url'] ??
                'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400',
            'rating': 4.5,
            'processor': product['processor'] ?? 'Not specified',
            'ram': product['ram'] ?? 'Not specified',
            'storage': product['storage'] ?? 'Not specified',
            'display': product['display'] ?? 'Not specified',
            'graphics': product['graphics'] ?? 'Not specified',
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading laptops: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadCompareList() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response =
          await Supabase.instance.client.from('compare_list').select('''
            product_id,
            products!inner(
              *,
              brands!inner(name),
              product_images!inner(image_url, is_primary)
            )
          ''').eq('user_id', user.id);

      setState(() {
        selectedLaptops = response.map((item) {
          final product = item['products'];
          final images = product['product_images'] as List;
          final primaryImage = images.firstWhere(
            (img) => img['is_primary'] == true,
            orElse: () => images.isNotEmpty ? images.first : null,
          );

          return {
            'id': product['id'],
            'name': product['name'],
            'brand': product['brands']['name'],
            'price':
                'PKR ${product['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
            'image': primaryImage?['image_url'] ??
                'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400',
            'rating': 4.5,
            'processor': product['processor'] ?? 'Not specified',
            'ram': product['ram'] ?? 'Not specified',
            'storage': product['storage'] ?? 'Not specified',
            'display': product['display'] ?? 'Not specified',
            'graphics': product['graphics'] ?? 'Not specified',
          };
        }).toList();

        if (selectedLaptops.length >= 2) {
          isComparing = true;
        }
      });
    } catch (e) {
      print('Error loading compare list: $e');
    }
  }

  void _addToComparison(Map<String, dynamic> laptop) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to compare products',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedLaptops.length < 3 &&
        !selectedLaptops.any((l) => l['id'] == laptop['id'])) {
      try {
        await Supabase.instance.client.from('compare_list').insert({
          'user_id': user.id,
          'product_id': laptop['id'],
        });

        setState(() {
          selectedLaptops.add(laptop);
          if (selectedLaptops.length >= 2) {
            isComparing = true;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to comparison', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to comparison',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (selectedLaptops.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can compare maximum 3 laptops at a time',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
  }

  void _removeFromComparison(String laptopId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('compare_list')
          .delete()
          .eq('user_id', user.id)
          .eq('product_id', laptopId);

      setState(() {
        selectedLaptops.removeWhere((laptop) => laptop['id'] == laptopId);
        if (selectedLaptops.length < 2) {
          isComparing = false;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing from comparison',
              style: GoogleFonts.poppins()),
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
          _buildHeader(),
          Expanded(
            child: isComparing
                ? _buildComparisonView()
                : _buildLaptopSelectionView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
                  'Compare Laptops',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2D3748),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isComparing
                      ? 'Comparing ${selectedLaptops.length} laptops'
                      : 'Select laptops to compare (${selectedLaptops.length}/3)',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (selectedLaptops.isNotEmpty)
            TextButton(
              onPressed: () async {
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null) {
                  await Supabase.instance.client
                      .from('compare_list')
                      .delete()
                      .eq('user_id', user.id);
                }
                setState(() {
                  selectedLaptops.clear();
                  isComparing = false;
                });
              },
              child: Text(
                'Clear All',
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

  Widget _buildLaptopSelectionView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedLaptops.isNotEmpty) ...[
            _buildSelectedLaptopsPreview(),
            const SizedBox(height: 20),
          ],
          Text(
            'Available Laptops',
            style: GoogleFonts.poppins(
              color: const Color(0xFF2D3748),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: availableLaptops.length,
              itemBuilder: (context, index) {
                final laptop = availableLaptops[index];
                final isSelected =
                    selectedLaptops.any((l) => l['id'] == laptop['id']);
                return _buildLaptopCard(laptop, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedLaptopsPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF667eea).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF667eea).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected for Comparison',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2D3748),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (selectedLaptops.length >= 2)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isComparing = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Compare Now',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selectedLaptops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final laptop = selectedLaptops[index];
                return Container(
                  width: 160,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: laptop['image'],
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          laptop['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeFromComparison(laptop['id']),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.red),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaptopCard(Map<String, dynamic> laptop, bool isSelected) {
    return GestureDetector(
      onTap: () => isSelected
          ? _removeFromComparison(laptop['id'])
          : _addToComparison(laptop),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF667eea) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: laptop['image'],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withOpacity(0.3),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      laptop['brand'],
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF667eea),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      laptop['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      laptop['price'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Comparison Results',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2D3748),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isComparing = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Add More',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildComparisonTable(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    final specs = [
      {'label': 'Price', 'key': 'price'},
      {'label': 'Processor', 'key': 'processor'},
      {'label': 'RAM', 'key': 'ram'},
      {'label': 'Storage', 'key': 'storage'},
      {'label': 'Display', 'key': 'display'},
      {'label': 'Graphics', 'key': 'graphics'},
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    'Specs',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...selectedLaptops
                    .map((laptop) => Expanded(
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: laptop['image'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                laptop['name'],
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ],
            ),
          ),
          // Specs rows
          ...specs
              .map((spec) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            spec['label']!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ...selectedLaptops
                            .map((laptop) => Expanded(
                                  child: Text(
                                    laptop[spec['key']!] ?? 'N/A',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFF4A5568),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ))
                            .toList(),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }
}

// Working Cart Screen
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

  double get tax => subtotal * 0.18;
  double get shipping => subtotal > 50000 ? 0 : 500;
  double get total => subtotal + tax + shipping;

  void _updateQuantity(String cartId, int newQuantity) async {
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
              onPressed: () async {
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null) {
                  await Supabase.instance.client
                      .from('cart')
                      .delete()
                      .eq('user_id', user.id);
                  setState(() {
                    cartItems.clear();
                  });
                }
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
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cartItems.length,
            separatorBuilder: (_, __) => const Divider(height: 32),
            itemBuilder: (context, index) => _buildCartItem(cartItems[index]),
          ),
        ),
        _buildOrderSummary(),
      ],
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item['image'],
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                ),
                Text(
                  'PKR ${item['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF667eea),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _updateQuantity(item['id'], item['quantity'] - 1),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.remove, size: 16),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  item['quantity'].toString(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _updateQuantity(item['id'], item['quantity'] + 1),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal', 'PKR ${subtotal.toStringAsFixed(0)}'),
          _buildSummaryRow('GST (18%)', 'PKR ${tax.toStringAsFixed(0)}'),
          _buildSummaryRow('Shipping',
              shipping == 0 ? 'FREE' : 'PKR ${shipping.toStringAsFixed(0)}'),
          const Divider(),
          _buildSummaryRow('Total', 'PKR ${total.toStringAsFixed(0)}',
              isTotal: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isPlacingOrder ? null : _placeOrder,
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
                      'Place Order',
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

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
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
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? const Color(0xFF667eea) : null,
            ),
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
            'Order placed successfully!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isPlacingOrder = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Working Profile Screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  String userName = "Loading...";
  String userEmail = "Loading...";
  int totalOrders = 0;
  int wishlistItems = 0;
  int totalReviews = 0;
  bool isLoading = true;

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
    _loadUserData();
  }

  void _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final profileResponse = await Supabase.instance.client
            .from('profiles')
            .select('*')
            .eq('id', user.id)
            .maybeSingle();

        // Load stats
        final ordersResponse = await Supabase.instance.client
            .from('orders')
            .select('id')
            .eq('user_id', user.id);

        final wishlistResponse = await Supabase.instance.client
            .from('wishlist')
            .select('id')
            .eq('user_id', user.id);

        final reviewsResponse = await Supabase.instance.client
            .from('reviews')
            .select('id')
            .eq('user_id', user.id);

        setState(() {
          userEmail = user.email ?? "No email";
          userName = profileResponse?['full_name'] ??
              user.email?.split('@')[0] ??
              "User";
          totalOrders = ordersResponse.length;
          wishlistItems = wishlistResponse.length;
          totalReviews = reviewsResponse.length;
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          userEmail = user.email ?? "No email";
          userName = user.email?.split('@')[0] ?? "User";
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: isLoading
          ? const Center(
              child: SpinKitFadingCircle(
                color: Color(0xFF667eea),
                size: 50,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildStatsSection(),
                const SizedBox(height: 24),
                _buildMenuSection('Account Settings', [
                  {
                    'icon': Icons.person_outline,
                    'title': 'Personal Information',
                    'subtitle': 'Update your details',
                    'onTap': () => _showPersonalInfoDialog(),
                  },
                  {
                    'icon': Icons.location_on_outlined,
                    'title': 'Addresses',
                    'subtitle': 'Manage delivery addresses',
                    'onTap': () => _showFeatureDialog('Addresses'),
                  },
                  {
                    'icon': Icons.payment_outlined,
                    'title': 'Payment Methods',
                    'subtitle': 'Cards and payment options',
                    'onTap': () => _showFeatureDialog('Payment Methods'),
                  },
                ]),
                const SizedBox(height: 16),
                _buildMenuSection('Orders & Purchases', [
                  {
                    'icon': Icons.shopping_bag_outlined,
                    'title': 'My Orders',
                    'subtitle': 'Track your orders',
                    'onTap': () => _showOrdersDialog(),
                  },
                  {
                    'icon': Icons.favorite_border,
                    'title': 'Wishlist',
                    'subtitle': 'Your favorite items',
                    'onTap': () => _showWishlistDialog(),
                  },
                  {
                    'icon': Icons.star_border,
                    'title': 'Reviews',
                    'subtitle': 'Your reviews and ratings',
                    'onTap': () => _showReviewsDialog(),
                  },
                ]),
                const SizedBox(height: 16),
                _buildMenuSection('Support', [
                  {
                    'icon': Icons.help_outline,
                    'title': 'Help & Support',
                    'subtitle': 'Get help',
                    'onTap': () => _showSupportDialog(),
                  },
                  {
                    'icon': Icons.logout,
                    'title': 'Sign Out',
                    'subtitle': 'Sign out of your account',
                    'isDestructive': true,
                    'onTap': () => _showSignOutDialog(),
                  },
                ]),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Color(0xFF667eea),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          Text(
            userEmail,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
            child: _buildStatCard(
                'Orders', totalOrders.toString(), Icons.shopping_bag_outlined)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard(
                'Wishlist', wishlistItems.toString(), Icons.favorite_border)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard(
                'Reviews', totalReviews.toString(), Icons.star_border)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF667eea), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
          ),
          const Divider(height: 1),
          ...items.map((item) => _buildMenuItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    final isDestructive = item['isDestructive'] ?? false;
    return ListTile(
      onTap: item['onTap'],
      leading: Icon(
        item['icon'],
        color: isDestructive ? Colors.red[600] : const Color(0xFF667eea),
        size: 24,
      ),
      title: Text(
        item['title'],
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red[600] : const Color(0xFF2D3748),
        ),
      ),
      subtitle: Text(
        item['subtitle'],
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey[400],
        size: 16,
      ),
    );
  }

  void _showPersonalInfoDialog() {
    final nameController = TextEditingController(text: userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Personal Information', style: GoogleFonts.poppins()),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Full Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null) {
                try {
                  await Supabase.instance.client.from('profiles').upsert({
                    'id': user.id,
                    'full_name': nameController.text.trim(),
                  });
                  setState(() {
                    userName = nameController.text.trim();
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Profile updated!',
                          style: GoogleFonts.poppins()),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating profile',
                          style: GoogleFonts.poppins()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showFeatureDialog(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('$feature feature coming soon!', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF667eea),
      ),
    );
  }

  void _showOrdersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('My Orders ($totalOrders)', style: GoogleFonts.poppins()),
        content: Text(
          totalOrders > 0
              ? 'You have $totalOrders orders. Full order history feature coming soon!'
              : 'No orders yet. Start shopping to see your orders here!',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWishlistDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('My Wishlist ($wishlistItems)', style: GoogleFonts.poppins()),
        content: Text(
          wishlistItems > 0
              ? 'You have $wishlistItems items in wishlist. Full wishlist view coming soon!'
              : 'No items in wishlist yet. Add some products to your wishlist!',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showReviewsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('My Reviews ($totalReviews)', style: GoogleFonts.poppins()),
        content: Text(
          totalReviews > 0
              ? 'You have written $totalReviews reviews. Full reviews view coming soon!'
              : 'No reviews yet. Buy and review products to see them here!',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Help & Support', style: GoogleFonts.poppins()),
        content: Text(
          'Need help? Contact us at:\n\nEmail: support@laptopharbor.com\nPhone: +92 300 1234567\n\nWe\'re here to help!',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out', style: GoogleFonts.poppins()),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
            child:
                const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Product Detail Screen
class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool isInWishlist = false;
  bool isInCart = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details', style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: widget.product['image'],
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.product['brand'] ?? 'Brand',
              style: GoogleFonts.poppins(
                color: const Color(0xFF667eea),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.product['name'] ?? 'Product Name',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.product['price'] ?? 'Price',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF667eea),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.product['specs'] != null) ...[
              Text(
                'Specifications:',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.product['specs']
                  .map<Widget>((spec) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• $spec',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ))
                  .toList(),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added to cart!',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Add to Cart',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added to wishlist!',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF667eea)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Add to Wishlist',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF667eea),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  String userName = "User";

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    _slideController.forward();
    _fetchUserName();
  }

  void _fetchUserName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();

        setState(() {
          userName =
              profile?['full_name'] ?? user.email?.split('@')[0] ?? "User";
        });
      } catch (e) {
        setState(() {
          userName = user.email?.split('@')[0] ?? "User";
        });
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    const HomeTabContent(),
    const CompareScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: SlideTransition(
        position: _slideAnimation,
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 2,
      backgroundColor: Colors.white,
      shadowColor: Colors.black.withOpacity(0.1),
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.laptop_mac,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LaptopHarbor',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2D3748),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Hello, $userName!',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF2D3748)),
          onPressed: () => _showSearchDialog(),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Color(0xFF2D3748)),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF667eea),
        unselectedItemColor: Colors.grey[400],
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows_outlined),
            activeIcon: Icon(Icons.compare_arrows),
            label: 'Compare',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Search Laptops', style: GoogleFonts.poppins()),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Enter laptop model, brand...',
            hintStyle: GoogleFonts.poppins(),
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}

class HomeTabContent extends StatefulWidget {
  const HomeTabContent({super.key});

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  int _selectedCategory = 0;

  PageController _carouselController = PageController(viewportFraction: 0.85);
  int _currentCarouselPage = 0;
  Timer? _timer;

  List<Map<String, dynamic>> featuredLaptops = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> brands = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeInOut,
    );
    _cardController.forward();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load categories
      final categoriesResponse = await Supabase.instance.client
          .from('categories')
          .select()
          .eq('is_active', true);

      // Load brands
      final brandsResponse = await Supabase.instance.client
          .from('brands')
          .select()
          .eq('is_active', true);

      // Load featured products with brand and category info
      final productsResponse =
          await Supabase.instance.client.from('products').select('''
            *,
            brands!inner(name, logo_url),
            categories!inner(name),
            product_images!inner(image_url, is_primary)
          ''').eq('is_active', true).eq('is_featured', true).limit(10);

      setState(() {
        categories = [
          {'id': 'all', 'name': 'All'},
          ...categoriesResponse
        ];
        brands = brandsResponse;
        featuredLaptops = productsResponse.map((product) {
          final images = product['product_images'] as List;
          final primaryImage = images.firstWhere(
            (img) => img['is_primary'] == true,
            orElse: () => images.isNotEmpty ? images.first : null,
          );

          return {
            'id': product['id'],
            'name': product['name'],
            'brand': product['brands']['name'],
            'price':
                'PKR ${product['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
            'originalPrice': product['original_price'] != null
                ? 'PKR ${product['original_price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'
                : null,
            'image': primaryImage?['image_url'] ??
                'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400',
            'rating': 4.5, // You can add a rating field to your database
            'discount': product['original_price'] != null
                ? '${(((product['original_price'] - product['price']) / product['original_price']) * 100).round()}% OFF'
                : null,
            'specs': [
              product['processor'] ?? 'Intel Core',
              product['ram'] ?? '16GB RAM',
              product['storage'] ?? '512GB SSD'
            ].where((spec) => spec.isNotEmpty).toList(),
            'inCart': false,
            'inWishlist': false,
            'slug': product['slug'],
          };
        }).toList();
        isLoading = false;
      });

      // Auto-play carousel
      if (featuredLaptops.isNotEmpty) {
        _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
          if (_currentCarouselPage < featuredLaptops.length - 1) {
            _currentCarouselPage++;
          } else {
            _currentCarouselPage = 0;
          }
          if (_carouselController.hasClients) {
            _carouselController.animateToPage(
              _currentCarouselPage,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    _carouselController.dispose();
    _timer?.cancel();
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

    return FadeTransition(
      opacity: _cardAnimation,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 24),
          if (featuredLaptops.isNotEmpty) ...[
            _buildCustomCarousel(),
            const SizedBox(height: 32),
          ],
          _buildQuickActions(),
          const SizedBox(height: 32),
          if (categories.isNotEmpty) ...[
            _buildCategorySection(),
            const SizedBox(height: 32),
          ],
          if (featuredLaptops.isNotEmpty) ...[
            _buildFeaturedProducts(),
            const SizedBox(height: 32),
          ],
          if (brands.isNotEmpty) _buildBrandsSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                  'Find Your Perfect',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                Text(
                  'Laptop Today!',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF667eea),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore premium laptops with amazing deals',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.laptop_mac,
              color: Color(0xFF667eea),
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured Deals',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _carouselController,
            onPageChanged: (index) {
              setState(() {
                _currentCarouselPage = index;
              });
            },
            itemCount: featuredLaptops.length,
            itemBuilder: (context, index) {
              final laptop = featuredLaptops[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailScreen(product: laptop),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(16)),
                              child: CachedNetworkImage(
                                imageUrl: laptop['image'],
                                height: 200,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: SpinKitFadingCircle(
                                    color: Color(0xFF667eea),
                                    size: 30,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.laptop_mac,
                                      size: 50, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    laptop['brand'],
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF667eea),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    laptop['name'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2D3748),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    laptop['price'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2D3748),
                                    ),
                                  ),
                                  if (laptop['originalPrice'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      laptop['originalPrice'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (laptop['discount'] != null)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              laptop['discount'],
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: featuredLaptops.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () {
                _carouselController.animateToPage(
                  entry.key,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                width: _currentCarouselPage == entry.key ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentCarouselPage == entry.key
                      ? const Color(0xFF667eea)
                      : Colors.grey[300],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Compare Laptops',
                Icons.compare_arrows,
                const Color(0xFF667eea),
                () {
                  // Navigate to compare tab
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Best Deals',
                Icons.local_offer,
                const Color(0xFF10B981),
                () {
                  // Navigate to deals page
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'New Arrivals',
                Icons.new_releases,
                const Color(0xFFF59E0B),
                () {
                  // Navigate to new arrivals
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shop by Category',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final isSelected = index == _selectedCategory;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = index;
                  });
                  // You can implement category filtering here
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF667eea) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF667eea)
                          : Colors.grey[300]!,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF667eea).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    categories[index]['name'],
                    style: GoogleFonts.poppins(
                      color:
                          isSelected ? Colors.white : const Color(0xFF2D3748),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Products',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all products page
              },
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF667eea),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 340,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: featuredLaptops.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) =>
                _buildProductCard(featuredLaptops[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> laptop) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: laptop),
          ),
        );
      },
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: laptop['image'],
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SpinKitFadingCircle(
                        color: Color(0xFF667eea),
                        size: 30,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 160,
                      color: Colors.grey[300],
                      child: const Icon(Icons.laptop_mac,
                          size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _toggleWishlist(laptop),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        laptop['inWishlist']
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: laptop['inWishlist'] ? Colors.red : Colors.grey,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                if (laptop['discount'] != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        laptop['discount'],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      laptop['brand'],
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF667eea),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      laptop['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    RatingBar.builder(
                      initialRating: laptop['rating'],
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 14,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rating) {},
                    ),
                    const SizedBox(height: 8),
                    Text(
                      laptop['price'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    if (laptop['originalPrice'] != null)
                      Text(
                        laptop['originalPrice'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _addToCart(laptop),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: laptop['inCart']
                                  ? Colors.green
                                  : const Color(0xFF667eea),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  laptop['inCart']
                                      ? Icons.check
                                      : Icons.shopping_cart,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  laptop['inCart'] ? 'Added' : 'Add to Cart',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Brands',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: brands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final brand = brands[index];
              return Container(
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: brand['logo_url'] ??
                            'https://images.unsplash.com/photo-1593640408182-31c70c8268f5?w=100',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const SpinKitFadingCircle(
                          color: Color(0xFF667eea),
                          size: 20,
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey[300],
                          child: const Icon(Icons.business,
                              size: 20, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      brand['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _toggleWishlist(Map<String, dynamic> laptop) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      if (laptop['inWishlist']) {
        await Supabase.instance.client
            .from('wishlist')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', laptop['id']);
      } else {
        await Supabase.instance.client.from('wishlist').insert({
          'user_id': user.id,
          'product_id': laptop['id'],
        });
      }

      setState(() {
        laptop['inWishlist'] = !laptop['inWishlist'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            laptop['inWishlist']
                ? 'Added to wishlist!'
                : 'Removed from wishlist!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: laptop['inWishlist'] ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error updating wishlist', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addToCart(Map<String, dynamic> laptop) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      if (laptop['inCart']) {
        await Supabase.instance.client
            .from('cart')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', laptop['id']);
      } else {
        await Supabase.instance.client.from('cart').insert({
          'user_id': user.id,
          'product_id': laptop['id'],
          'quantity': 1,
        });
      }

      setState(() {
        laptop['inCart'] = !laptop['inCart'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            laptop['inCart']
                ? '${laptop['name']} added to cart!'
                : '${laptop['name']} removed from cart!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: laptop['inCart'] ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating cart', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
