import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String? userPhone;
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
    _loadUserStats();
  }

  void _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // Check if profile exists in profiles table
        final profileResponse = await Supabase.instance.client
            .from('profiles')
            .select('*')
            .eq('id', user.id)
            .maybeSingle();

        setState(() {
          userEmail = user.email ?? "No email";
          userName = profileResponse?['full_name'] ??
              user.email?.split('@')[0] ??
              "User";
          userPhone = profileResponse?['phone'];
        });
      } catch (e) {
        setState(() {
          userEmail = user.email ?? "No email";
          userName = user.email?.split('@')[0] ?? "User";
        });
      }
    }
  }

  void _loadUserStats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Fetch orders count
      final ordersResponse = await Supabase.instance.client
          .from('orders')
          .select('id')
          .eq('user_id', user.id);

      // Fetch wishlist count
      final wishlistResponse = await Supabase.instance.client
          .from('wishlist')
          .select('id')
          .eq('user_id', user.id);

      // Fetch reviews count
      final reviewsResponse = await Supabase.instance.client
          .from('reviews')
          .select('id')
          .eq('user_id', user.id);

      setState(() {
        totalOrders = ordersResponse.length;
        wishlistItems = wishlistResponse.length;
        totalReviews = reviewsResponse.length;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
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
                    'onTap': () => _navigateToPersonalInfo(),
                  },
                  {
                    'icon': Icons.location_on_outlined,
                    'title': 'Addresses',
                    'subtitle': 'Manage delivery addresses',
                    'onTap': () => _navigateToAddresses(),
                  },
                  {
                    'icon': Icons.payment_outlined,
                    'title': 'Payment Methods',
                    'subtitle': 'Cards and payment options',
                    'onTap': () => _navigateToPayments(),
                  },
                ]),
                const SizedBox(height: 16),
                _buildMenuSection('Orders & Purchases', [
                  {
                    'icon': Icons.shopping_bag_outlined,
                    'title': 'My Orders',
                    'subtitle': 'Track your orders',
                    'onTap': () => _navigateToOrders(),
                  },
                  {
                    'icon': Icons.favorite_border,
                    'title': 'Wishlist',
                    'subtitle': 'Your favorite items',
                    'onTap': () => _navigateToWishlist(),
                  },
                  {
                    'icon': Icons.star_border,
                    'title': 'Reviews',
                    'subtitle': 'Your reviews and ratings',
                    'onTap': () => _navigateToReviews(),
                  },
                ]),
                const SizedBox(height: 16),
                _buildMenuSection('Support', [
                  {
                    'icon': Icons.help_outline,
                    'title': 'Help & Support',
                    'subtitle': 'Get help',
                    'onTap': () => _navigateToSupport(),
                  },
                  {
                    'icon': Icons.privacy_tip_outlined,
                    'title': 'Privacy Policy',
                    'subtitle': 'Read our privacy policy',
                    'onTap': () => _showPrivacyPolicy(),
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
          if (userPhone != null) ...[
            const SizedBox(height: 4),
            Text(
              userPhone!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
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

  // Navigation methods
  void _navigateToPersonalInfo() {
    _showPersonalInfoDialog();
  }

  void _navigateToAddresses() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Addresses feature coming soon!',
            style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF667eea),
      ),
    );
  }

  void _navigateToPayments() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Methods feature coming soon!',
            style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF667eea),
      ),
    );
  }

  void _navigateToOrders() async {
    _showOrdersBottomSheet();
  }

  void _navigateToWishlist() async {
    _showWishlistBottomSheet();
  }

  void _navigateToReviews() async {
    _showReviewsBottomSheet();
  }

  void _navigateToSupport() {
    _showSupportDialog();
  }

  void _showPersonalInfoDialog() {
    final nameController = TextEditingController(text: userName);
    final phoneController = TextEditingController(text: userPhone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Personal Information', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null) {
                  await Supabase.instance.client.from('profiles').upsert({
                    'id': user.id,
                    'full_name': nameController.text.trim(),
                    'phone': phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                  });

                  setState(() {
                    userName = nameController.text.trim();
                    userPhone = phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim();
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Profile updated successfully!',
                          style: GoogleFonts.poppins()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating profile',
                        style: GoogleFonts.poppins()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Privacy Policy', style: GoogleFonts.poppins()),
        content: SingleChildScrollView(
          child: Text(
            '''LaptopHarbor Privacy Policy

Your privacy is important to us. We collect and use your information to provide you with the best shopping experience.

Information We Collect:
• Personal information (name, email, phone)
• Order and payment information
• Device and usage information

How We Use Information:
• Process orders and payments
• Improve our services
• Send important updates

Data Security:
We implement appropriate security measures to protect your personal information.

Contact Us:
If you have questions about this privacy policy, please contact our support team.''',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Contact Support', style: GoogleFonts.poppins()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Message',
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
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null) {
                  await Supabase.instance.client
                      .from('support_messages')
                      .insert({
                    'user_id': user.id,
                    'name': userName,
                    'email': userEmail,
                    'subject': subjectController.text.trim(),
                    'message': messageController.text.trim(),
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Support request submitted successfully!',
                          style: GoogleFonts.poppins()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error submitting request',
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

  void _showOrdersBottomSheet() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final orders = await Supabase.instance.client
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'My Orders (${orders.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: orders.isEmpty
                      ? Center(
                          child: Text(
                            'No orders yet',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Order #${order['order_number'] ?? order['id'].toString().substring(0, 8)}',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              _getStatusColor(order['status'])
                                                  .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          (order['status'] ?? 'pending')
                                              .toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: _getStatusColor(
                                                order['status']),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Total: PKR ${order['total_amount']?.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF667eea),
                                    ),
                                  ),
                                  Text(
                                    'Items: ${order['order_items']?.length ?? 0}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Date: ${DateTime.parse(order['created_at']).toLocal().toString().split(' ')[0]}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading orders: ${e.toString()}',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showWishlistBottomSheet() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final wishlist =
          await Supabase.instance.client.from('wishlist').select('''
            *,
            products!inner(
              *,
              brands!inner(name),
              product_images!inner(image_url, is_primary)
            )
          ''').eq('user_id', user.id);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'My Wishlist (${wishlist.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: wishlist.isEmpty
                      ? Center(
                          child: Text(
                            'No items in wishlist',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: wishlist.length,
                          itemBuilder: (context, index) {
                            final item = wishlist[index];
                            final product = item['products'];
                            final images = product['product_images'] as List;
                            final primaryImage = images.firstWhere(
                              (img) => img['is_primary'] == true,
                              orElse: () =>
                                  images.isNotEmpty ? images.first : null,
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: primaryImage?['image_url'] ??
                                          'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.laptop_mac,
                                            color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['brands']['name'],
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF667eea),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          product['name'],
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'PKR ${product['price']?.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF667eea),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      try {
                                        await Supabase.instance.client
                                            .from('wishlist')
                                            .delete()
                                            .eq('id', item['id']);

                                        Navigator.pop(context);
                                        _showWishlistBottomSheet(); // Refresh
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('Error removing item',
                                                style: GoogleFonts.poppins()),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading wishlist: ${e.toString()}',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReviewsBottomSheet() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final reviews = await Supabase.instance.client.from('reviews').select('''
            *,
            products!inner(
              name,
              brands!inner(name)
            )
          ''').eq('user_id', user.id).order('created_at', ascending: false);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'My Reviews (${reviews.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: reviews.isEmpty
                      ? Center(
                          child: Text(
                            'No reviews yet',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: reviews.length,
                          itemBuilder: (context, index) {
                            final review = reviews[index];
                            final product = review['products'];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['brands']['name'],
                                              style: GoogleFonts.poppins(
                                                color: const Color(0xFF667eea),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              product['name'],
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(
                                            5,
                                            (i) => Icon(
                                                  i < (review['rating'] ?? 0)
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  color: Colors.amber,
                                                  size: 16,
                                                )),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (review['title'] != null) ...[
                                    Text(
                                      review['title'],
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  if (review['comment'] != null)
                                    Text(
                                      review['comment'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading reviews: ${e.toString()}',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'processing':
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.poppins(),
        ),
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
