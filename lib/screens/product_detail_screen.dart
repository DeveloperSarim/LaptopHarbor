import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool isInWishlist = false;
  bool isInCart = false;
  int quantity = 1;
  bool isLoading = true;
  Map<String, dynamic>? fullProduct;
  List<Map<String, dynamic>> reviews = [];
  List<Map<String, dynamic>> relatedProducts = [];

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

    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      // Load full product details
      final productResponse =
          await Supabase.instance.client.from('products').select('''
            *,
            brands!inner(name, logo_url),
            categories!inner(name),
            product_images(image_url, alt_text, is_primary, sort_order)
          ''').eq('id', widget.product['id']).single();

      // Check if user has this in wishlist and cart
      if (user != null) {
        final wishlistCheck = await Supabase.instance.client
            .from('wishlist')
            .select('id')
            .eq('user_id', user.id)
            .eq('product_id', widget.product['id'])
            .maybeSingle();

        final cartCheck = await Supabase.instance.client
            .from('cart')
            .select('quantity')
            .eq('user_id', user.id)
            .eq('product_id', widget.product['id'])
            .maybeSingle();

        isInWishlist = wishlistCheck != null;
        isInCart = cartCheck != null;
        if (cartCheck != null) {
          quantity = cartCheck['quantity'];
        }
      }

      // Load reviews
      final reviewsResponse = await Supabase.instance.client
          .from('reviews')
          .select('''
            *,
            profiles!inner(full_name)
          ''')
          .eq('product_id', widget.product['id'])
          .eq('is_approved', true)
          .order('created_at', ascending: false)
          .limit(5);

      // Load related products (same category)
      final relatedResponse = await Supabase.instance.client
          .from('products')
          .select('''
            *,
            brands!inner(name),
            product_images!inner(image_url, is_primary)
          ''')
          .eq('category_id', productResponse['category_id'])
          .neq('id', widget.product['id'])
          .eq('is_active', true)
          .limit(4);

      setState(() {
        fullProduct = productResponse;
        reviews = reviewsResponse;
        relatedProducts = relatedResponse.map((product) {
          final images = product['product_images'] as List;
          final primaryImage = images.firstWhere(
            (img) => img['is_primary'] == true,
            orElse: () => images.isNotEmpty ? images.first : null,
          );

          return {
            ...product,
            'image': primaryImage?['image_url'] ??
                'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400',
            'brand_name': product['brands']['name'],
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading product details: $e');
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
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: const Center(
          child: SpinKitFadingCircle(
            color: Color(0xFF667eea),
            size: 50,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildProductInfo(),
                  _buildSpecifications(),
                  if (reviews.isNotEmpty) _buildReviews(),
                  if (relatedProducts.isNotEmpty) _buildRelatedProducts(),
                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildSliverAppBar() {
    final images = fullProduct?['product_images'] as List? ?? [];
    final primaryImage = images.firstWhere(
      (img) => img['is_primary'] == true,
      orElse: () => images.isNotEmpty ? images.first : null,
    );

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              isInWishlist ? Icons.favorite : Icons.favorite_border,
              color: isInWishlist ? Colors.red : const Color(0xFF2D3748),
            ),
            onPressed: _toggleWishlist,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: primaryImage?['image_url'] ?? widget.product['image'],
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: SpinKitFadingCircle(
                  color: Color(0xFF667eea),
                  size: 50,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child:
                    const Icon(Icons.laptop_mac, size: 100, color: Colors.grey),
              ),
            ),
            if (fullProduct?['original_price'] != null)
              Positioned(
                top: 60,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(((fullProduct!['original_price'] - fullProduct!['price']) / fullProduct!['original_price']) * 100).round()}% OFF',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
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
            fullProduct?['brands']['name'] ?? widget.product['brand'],
            style: GoogleFonts.poppins(
              color: const Color(0xFF667eea),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fullProduct?['name'] ?? widget.product['name'],
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              RatingBar.builder(
                initialRating: _getAverageRating(),
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 20,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {},
              ),
              const SizedBox(width: 8),
              Text(
                '(${_getAverageRating()}) • ${reviews.length} reviews',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'PKR ${fullProduct?['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(width: 12),
              if (fullProduct?['original_price'] != null)
                Text(
                  'PKR ${fullProduct!['original_price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[500],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (fullProduct?['short_description'] != null) ...[
            Text(
              fullProduct!['short_description'],
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Text(
                'Quantity:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (quantity > 1) {
                          setState(() {
                            quantity--;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(Icons.remove, size: 20),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Text(
                        quantity.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (quantity < (fullProduct?['stock_quantity'] ?? 10)) {
                          setState(() {
                            quantity++;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(Icons.add, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Stock: ${fullProduct?['stock_quantity'] ?? 'Available'}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: (fullProduct?['stock_quantity'] ?? 10) > 0
                      ? Colors.green[600]
                      : Colors.red[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecifications() {
    final specs = [
      {'label': 'Processor', 'value': fullProduct?['processor']},
      {'label': 'RAM', 'value': fullProduct?['ram']},
      {'label': 'Storage', 'value': fullProduct?['storage']},
      {'label': 'Display', 'value': fullProduct?['display']},
      {'label': 'Graphics', 'value': fullProduct?['graphics']},
      {'label': 'Battery', 'value': fullProduct?['battery']},
      {'label': 'Weight', 'value': fullProduct?['weight']},
      {'label': 'Operating System', 'value': fullProduct?['operating_system']},
      {'label': 'Warranty', 'value': fullProduct?['warranty']},
      {'label': 'Ports', 'value': fullProduct?['ports']},
    ]
        .where((spec) =>
            spec['value'] != null && spec['value'].toString().isNotEmpty)
        .toList();

    if (specs.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            'Specifications',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          ...specs
              .map((spec) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            spec['label']!,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF667eea),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            spec['value']!,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF4A5568),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews (${reviews.length})',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              TextButton(
                onPressed: () => _showWriteReviewDialog(),
                child: Text(
                  'Write Review',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF667eea),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...reviews
              .take(3)
              .map((review) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF667eea),
                              child: Text(
                                (review['profiles']['full_name'] ?? 'U')[0]
                                    .toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review['profiles']['full_name'] ??
                                        'Anonymous',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  RatingBar.builder(
                                    initialRating: review['rating'].toDouble(),
                                    minRating: 1,
                                    direction: Axis.horizontal,
                                    allowHalfRating: false,
                                    itemCount: 5,
                                    itemSize: 16,
                                    itemBuilder: (context, _) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    onRatingUpdate: (rating) {},
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (review['title'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            review['title'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        if (review['comment'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            review['comment'],
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildRelatedProducts() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            'Related Products',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: relatedProducts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = relatedProducts[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          product: {
                            'id': product['id'],
                            'name': product['name'],
                            'brand': product['brand_name'],
                            'image': product['image'],
                            'price':
                                'PKR ${product['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          },
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: CachedNetworkImage(
                              imageUrl: product['image'],
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: SpinKitFadingCircle(
                                  color: Color(0xFF667eea),
                                  size: 20,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.laptop_mac, size: 30),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['brand_name'],
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF667eea),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  product['name'],
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
                                  'PKR ${product['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _addToCart,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF667eea)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isInCart ? Icons.check : Icons.shopping_cart_outlined,
                    color: const Color(0xFF667eea),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isInCart ? 'In Cart' : 'Add to Cart',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF667eea),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _buyNow(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Buy Now',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getAverageRating() {
    if (reviews.isEmpty) return 4.5;
    final sum = reviews.fold(0.0, (sum, review) => sum + review['rating']);
    return sum / reviews.length;
  }

  Future<void> _toggleWishlist() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to add to wishlist',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (isInWishlist) {
        await Supabase.instance.client
            .from('wishlist')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', widget.product['id']);
      } else {
        await Supabase.instance.client.from('wishlist').insert({
          'user_id': user.id,
          'product_id': widget.product['id'],
        });
      }

      setState(() {
        isInWishlist = !isInWishlist;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isInWishlist ? 'Added to wishlist!' : 'Removed from wishlist!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: isInWishlist ? Colors.green : Colors.red,
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

  Future<void> _addToCart() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Please login to add to cart', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (isInCart) {
        await Supabase.instance.client
            .from('cart')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', widget.product['id']);
        setState(() {
          isInCart = false;
        });
      } else {
        await Supabase.instance.client.from('cart').upsert({
          'user_id': user.id,
          'product_id': widget.product['id'],
          'quantity': quantity,
        });
        setState(() {
          isInCart = true;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isInCart ? 'Added to cart!' : 'Removed from cart!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: isInCart ? Colors.green : Colors.red,
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

  void _buyNow() {
    // Implement buy now functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buy Now', style: GoogleFonts.poppins()),
        content: Text(
          'Proceed to checkout with ${widget.product['name']}?',
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
              // Navigate to checkout
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _showWriteReviewDialog() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to write a review',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double rating = 5;
    final titleController = TextEditingController();
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Write a Review', style: GoogleFonts.poppins()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rating:',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              RatingBar.builder(
                initialRating: rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 30,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (newRating) {
                  rating = newRating;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Review Title (Optional)',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Your Review',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Supabase.instance.client.from('reviews').insert({
                  'user_id': user.id,
                  'product_id': widget.product['id'],
                  'rating': rating.toInt(),
                  'title': titleController.text.trim().isNotEmpty
                      ? titleController.text.trim()
                      : null,
                  'comment': commentController.text.trim().isNotEmpty
                      ? commentController.text.trim()
                      : null,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Review submitted successfully!',
                        style: GoogleFonts.poppins()),
                    backgroundColor: Colors.green,
                  ),
                );

                // Reload reviews
                _loadProductDetails();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error submitting review',
                        style: GoogleFonts.poppins()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
