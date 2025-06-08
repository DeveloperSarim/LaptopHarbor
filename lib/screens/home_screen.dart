import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

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
      setState(() {
        userName = user.email?.split('@')[0] ?? "User";
      });
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
      automaticallyImplyLeading: false, // Back button remove kiya
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

  // Custom Carousel Controller
  PageController _carouselController = PageController(viewportFraction: 0.85);
  int _currentCarouselPage = 0;
  Timer? _timer;

  static final List<Map<String, dynamic>> featuredLaptops = [
    {
      'id': 1,
      'name': 'Dell XPS 13 Plus',
      'brand': 'Dell',
      'price': 'PKR 4,99,999',
      'originalPrice': 'PKR 5,99,999',
      'image':
          'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400',
      'rating': 4.8,
      'discount': '17% OFF',
      'specs': ['Intel i7', '16GB RAM', '512GB SSD'],
      'inCart': false,
      'inWishlist': false,
    },
    {
      'id': 2,
      'name': 'MacBook Pro 16"',
      'brand': 'Apple',
      'price': 'PKR 7,49,999',
      'originalPrice': 'PKR 8,49,999',
      'image':
          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=400',
      'rating': 4.9,
      'discount': '12% OFF',
      'specs': ['M2 Pro', '32GB RAM', '1TB SSD'],
      'inCart': false,
      'inWishlist': false,
    },
    {
      'id': 3,
      'name': 'ASUS ROG Zephyrus G15',
      'brand': 'ASUS',
      'price': 'PKR 4,49,999',
      'originalPrice': 'PKR 4,99,999',
      'image':
          'https://images.unsplash.com/photo-1593642702821-c8da6771f0c6?w=400',
      'rating': 4.7,
      'discount': '10% OFF',
      'specs': ['AMD Ryzen 9', '32GB RAM', 'RTX 4070'],
      'inCart': false,
      'inWishlist': false,
    },
    {
      'id': 4,
      'name': 'HP Spectre x360',
      'brand': 'HP',
      'price': 'PKR 3,74,999',
      'originalPrice': 'PKR 4,24,999',
      'image':
          'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=400',
      'rating': 4.6,
      'discount': '12% OFF',
      'specs': ['Intel i7', '16GB RAM', '512GB SSD'],
      'inCart': false,
      'inWishlist': false,
    },
  ];

  static final List<String> categories = [
    'All',
    'Gaming',
    'Ultrabooks',
    'Business',
    '2-in-1',
    'Budget',
    'Workstation',
  ];

  static final List<Map<String, String>> brands = [
    {
      'name': 'Dell',
      'logo':
          'https://images.unsplash.com/photo-1593640408182-31c70c8268f5?w=100'
    },
    {
      'name': 'Apple',
      'logo':
          'https://images.unsplash.com/photo-1611532736597-de2d4265fba3?w=100'
    },
    {
      'name': 'HP',
      'logo': 'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=100'
    },
    {
      'name': 'ASUS',
      'logo':
          'https://images.unsplash.com/photo-1593640408182-31c70c8268f5?w=100'
    },
    {
      'name': 'Lenovo',
      'logo': 'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=100'
    },
  ];

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

    // Auto play carousel
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

  @override
  void dispose() {
    _cardController.dispose();
    _carouselController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _cardAnimation,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 24),
          _buildCustomCarousel(),
          const SizedBox(height: 32),
          _buildQuickActions(),
          const SizedBox(height: 32),
          _buildCategorySection(),
          const SizedBox(height: 32),
          _buildFeaturedProducts(),
          const SizedBox(height: 32),
          _buildBrandsSection(),
          const SizedBox(height: 32),
          _buildDealsSection(),
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
              return Container(
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
                                Row(
                                  children: [
                                    Text(
                                      laptop['price'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2D3748),
                                      ),
                                    ),
                                  ],
                                ),
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
                            ),
                          ),
                        ),
                      ],
                    ),
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
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Dots indicator
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
                () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Best Deals',
                Icons.local_offer,
                const Color(0xFF10B981),
                () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'New Arrivals',
                Icons.new_releases,
                const Color(0xFFF59E0B),
                () {},
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
                    categories[index],
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
              onPressed: () {},
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
    return Container(
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
                  onTap: () {
                    setState(() {
                      laptop['inWishlist'] = !laptop['inWishlist'];
                    });
                  },
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
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  Row(
                    children: [
                      Text(
                        laptop['price'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
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
                          onPressed: () {
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
                                backgroundColor: laptop['inCart']
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            );
                          },
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
                        imageUrl: brand['logo']!,
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
                      brand['name']!,
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

  Widget _buildDealsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF667eea),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Special Deals',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Up to 50% off on selected laptops',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF667eea),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    'Shop Now',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 60,
          ),
        ],
      ),
    );
  }
}

// Compare Screen Implementation
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  List<Map<String, dynamic>> selectedLaptops = [];

  static final List<Map<String, dynamic>> availableLaptops = [
    {
      'id': 1,
      'name': 'Dell XPS 13 Plus',
      'brand': 'Dell',
      'price': 'PKR 4,99,999',
      'image':
          'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400',
      'rating': 4.8,
      'processor': 'Intel Core i7-1260P',
      'ram': '16GB LPDDR5',
      'storage': '512GB SSD',
      'display': '13.4" 3.5K OLED',
      'graphics': 'Intel Iris Xe',
      'battery': '55Wh (up to 12 hours)',
      'weight': '1.26 kg',
    },
    {
      'id': 2,
      'name': 'MacBook Pro 16"',
      'brand': 'Apple',
      'price': 'PKR 7,49,999',
      'image':
          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=400',
      'rating': 4.9,
      'processor': 'Apple M2 Pro',
      'ram': '32GB Unified Memory',
      'storage': '1TB SSD',
      'display': '16.2" Liquid Retina XDR',
      'graphics': 'Integrated GPU',
      'battery': '100Wh (up to 22 hours)',
      'weight': '2.15 kg',
    },
    {
      'id': 3,
      'name': 'ASUS ROG Zephyrus G15',
      'brand': 'ASUS',
      'price': 'PKR 4,49,999',
      'image':
          'https://images.unsplash.com/photo-1593642702821-c8da6771f0c6?w=400',
      'rating': 4.7,
      'processor': 'AMD Ryzen 9 6900HS',
      'ram': '32GB DDR5',
      'storage': '1TB SSD',
      'display': '15.6" QHD 165Hz',
      'graphics': 'NVIDIA RTX 4070',
      'battery': '90Wh (up to 10 hours)',
      'weight': '1.99 kg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compare Laptops',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select laptops to compare side by side',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            if (selectedLaptops.isNotEmpty) ...[
              Container(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Selected for Comparison (${selectedLaptops.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedLaptops.clear();
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
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedLaptops.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final laptop = selectedLaptops[index];
                          return Container(
                            width: 200,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF667eea).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      const Color(0xFF667eea).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CachedNetworkImage(
                                    imageUrl: laptop['image'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.laptop_mac,
                                          size: 25),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.laptop_mac,
                                          size: 25),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
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
                                      Text(
                                        laptop['price'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: const Color(0xFF667eea),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedLaptops.removeWhere(
                                          (l) => l['id'] == laptop['id']);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                      size: 16,
                                    ),
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
              const SizedBox(height: 24),
            ],
            Text(
              'Available Laptops',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: availableLaptops.length,
                itemBuilder: (context, index) {
                  final laptop = availableLaptops[index];
                  final isSelected =
                      selectedLaptops.any((l) => l['id'] == laptop['id']);
                  return GestureDetector(
                    onTap: () {
                      if (isSelected) {
                        setState(() {
                          selectedLaptops
                              .removeWhere((l) => l['id'] == laptop['id']);
                        });
                      } else if (selectedLaptops.length < 3) {
                        setState(() {
                          selectedLaptops.add(laptop);
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'You can compare maximum 3 laptops at a time',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF667eea)
                              : Colors.transparent,
                          width: 2,
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
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                  child: CachedNetworkImage(
                                    imageUrl: laptop['image'],
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.laptop_mac,
                                          size: 40),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.laptop_mac,
                                          size: 40),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF667eea)
                                          .withOpacity(0.3),
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12)),
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
                                  const SizedBox(height: 4),
                                  RatingBar.builder(
                                    initialRating: laptop['rating'],
                                    minRating: 1,
                                    direction: Axis.horizontal,
                                    allowHalfRating: true,
                                    itemCount: 5,
                                    itemSize: 10,
                                    itemBuilder: (context, _) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    onRatingUpdate: (rating) {},
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Cart Screen Implementation
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [
    {
      'id': 1,
      'name': 'Dell XPS 13 Plus',
      'brand': 'Dell',
      'price': 499999,
      'originalPrice': 599999,
      'image':
          'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400',
      'quantity': 1,
    },
    {
      'id': 2,
      'name': 'ASUS ROG Zephyrus G15',
      'brand': 'ASUS',
      'price': 449999,
      'originalPrice': 499999,
      'image':
          'https://images.unsplash.com/photo-1593642702821-c8da6771f0c6?w=400',
      'quantity': 1,
    },
  ];

  double get subtotal {
    return cartItems.fold(
        0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  double get tax => subtotal * 0.17; // 17% GST
  double get shipping => subtotal > 100000 ? 0 : 1500;
  double get total => subtotal + tax + shipping;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: cartItems.isEmpty ? _buildEmptyCart() : _buildCartWithItems(),
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
              // Navigate back to home
            },
            child: Text(
              'Start Shopping',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartWithItems() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Shopping Cart',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          cartItems.clear();
                        });
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
                Text(
                  '${cartItems.length} items in your cart',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.separated(
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) =>
                        _buildCartItem(cartItems[index]),
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
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.laptop_mac, size: 40),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.laptop_mac, size: 40),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'PKR ${item['price']}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PKR ${item['originalPrice']}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                        decoration: TextDecoration.lineThrough,
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
                      onTap: () {
                        setState(() {
                          if (item['quantity'] > 1) {
                            item['quantity']--;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.remove, size: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        item['quantity'].toString(),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          item['quantity']++;
                        });
                      },
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
                onTap: () {
                  setState(() {
                    cartItems.removeWhere(
                        (cartItem) => cartItem['id'] == item['id']);
                  });
                },
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
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal', 'PKR ${subtotal.toStringAsFixed(0)}'),
          _buildSummaryRow('GST (17%)', 'PKR ${tax.toStringAsFixed(0)}'),
          _buildSummaryRow('Shipping',
              shipping == 0 ? 'FREE' : 'PKR ${shipping.toStringAsFixed(0)}'),
          const Divider(height: 24),
          _buildSummaryRow('Total', 'PKR ${total.toStringAsFixed(0)}',
              isTotal: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showCheckoutDialog();
              },
              child: Text(
                'Proceed to Checkout',
                style: GoogleFonts.poppins(
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
              color: const Color(0xFF2D3748),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color:
                  isTotal ? const Color(0xFF667eea) : const Color(0xFF2D3748),
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
        content: Text(
          'Proceed to payment gateway for PKR ${total.toStringAsFixed(0)}?',
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order placed successfully!',
                      style: GoogleFonts.poppins()),
                  backgroundColor: Colors.green,
                ),
              );
              setState(() {
                cartItems.clear();
              });
            },
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }
}

// Profile Screen Implementation with Supabase Backend
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "Loading...";
  String userEmail = "Loading...";
  int totalOrders = 0;
  int wishlistItems = 0;
  int totalReviews = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
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
    if (user == null) return;

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF667eea),
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
    // Navigate to personal info page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Personal Information page', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF667eea),
      ),
    );
  }

  void _navigateToAddresses() {
    // Navigate to addresses page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Addresses page', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF667eea),
      ),
    );
  }

  void _navigateToPayments() {
    // Navigate to payment methods page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Methods page', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF667eea),
      ),
    );
  }

  void _navigateToOrders() async {
    // Show orders page with real data
    _showOrdersBottomSheet();
  }

  void _navigateToWishlist() async {
    // Show wishlist page with real data
    _showWishlistBottomSheet();
  }

  void _navigateToReviews() async {
    // Show reviews page with real data
    _showReviewsBottomSheet();
  }

  void _navigateToSupport() {
    // Navigate to support page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Help & Support page', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF667eea),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Privacy Policy', style: GoogleFonts.poppins()),
        content: Text(
          'Your privacy is important to us. We collect and use your information to provide you with the best shopping experience.',
          style: GoogleFonts.poppins(),
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
                                        'Order #${order['id']}',
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
                                          order['status'] ?? 'pending',
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
                                    'Total: PKR ${order['total_amount'] ?? 0}',
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
      final wishlist = await Supabase.instance.client
          .from('wishlist')
          .select('*, products(*)')
          .eq('user_id', user.id);

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
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.laptop_mac,
                                        color: Colors.grey),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product?['name'] ?? 'Product',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'PKR ${product?['price'] ?? 0}',
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
      final reviews = await Supabase.instance.client
          .from('reviews')
          .select('*, products(*)')
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
                                        child: Text(
                                          product?['name'] ?? 'Product',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
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
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'processing':
        return Colors.blue;
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
