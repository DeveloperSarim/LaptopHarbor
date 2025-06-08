import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class EnhancedCompareScreen extends StatefulWidget {
  const EnhancedCompareScreen({super.key});

  @override
  State<EnhancedCompareScreen> createState() => _EnhancedCompareScreenState();
}

class _EnhancedCompareScreenState extends State<EnhancedCompareScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> selectedLaptops = [];
  bool isComparing = false;

  static final List<Map<String, dynamic>> availableLaptops = [
    {
      'id': 1,
      'name': 'Dell XPS 13 Plus',
      'brand': 'Dell',
      'price': '₹1,99,999',
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
      'os': 'Windows 11',
      'warranty': '1 Year',
      'ports': 'USB-C x2, 3.5mm Audio',
      'pros': ['Premium Build', 'Excellent Display', 'Fast Performance'],
      'cons': ['Limited Ports', 'Expensive', 'No USB-A'],
    },
    {
      'id': 2,
      'name': 'MacBook Pro 16"',
      'brand': 'Apple',
      'price': '₹2,99,999',
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
      'os': 'macOS Ventura',
      'warranty': '1 Year',
      'ports': 'Thunderbolt 4 x3, HDMI, SD Card',
      'pros': ['Exceptional Battery', 'Powerful Performance', 'Great Display'],
      'cons': ['Very Expensive', 'Heavy', 'No Touch Screen'],
    },
    {
      'id': 3,
      'name': 'ASUS ROG Zephyrus G15',
      'brand': 'ASUS',
      'price': '₹1,79,999',
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
      'os': 'Windows 11',
      'warranty': '2 Years',
      'ports': 'USB-C x2, USB-A x2, HDMI',
      'pros': ['Gaming Performance', 'Good Cooling', 'High Refresh Rate'],
      'cons': ['Average Battery', 'Gaming Focused', 'Can Get Hot'],
    },
    {
      'id': 4,
      'name': 'HP Spectre x360',
      'brand': 'HP',
      'price': '₹1,49,999',
      'image':
          'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=400',
      'rating': 4.6,
      'processor': 'Intel Core i7-1255U',
      'ram': '16GB LPDDR4x',
      'storage': '512GB SSD',
      'display': '13.5" 3K2K OLED Touch',
      'graphics': 'Intel Iris Xe',
      'battery': '66Wh (up to 17 hours)',
      'weight': '1.36 kg',
      'os': 'Windows 11',
      'warranty': '1 Year',
      'ports': 'USB-C x2, USB-A x1, MicroSD',
      'pros': ['2-in-1 Design', 'Touch Screen', 'Good Battery'],
      'cons': ['Average Performance', 'Reflective Screen', 'Limited Gaming'],
    },
    {
      'id': 5,
      'name': 'Lenovo ThinkPad X1 Carbon',
      'brand': 'Lenovo',
      'price': '₹1,89,999',
      'image':
          'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=400',
      'rating': 4.5,
      'processor': 'Intel Core i7-1260P',
      'ram': '16GB LPDDR5',
      'storage': '512GB SSD',
      'display': '14" 2.8K OLED',
      'graphics': 'Intel Iris Xe',
      'battery': '57Wh (up to 15 hours)',
      'weight': '1.12 kg',
      'os': 'Windows 11 Pro',
      'warranty': '3 Years',
      'ports': 'USB-C x2, USB-A x2, HDMI',
      'pros': ['Business Features', 'Lightweight', 'Great Keyboard'],
      'cons': ['Business Focused', 'Expensive', 'Limited Gaming'],
    },
  ];

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
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _addToComparison(Map<String, dynamic> laptop) {
    if (selectedLaptops.length < 3 &&
        !selectedLaptops.any((l) => l['id'] == laptop['id'])) {
      setState(() {
        selectedLaptops.add(laptop);
        if (selectedLaptops.length >= 2) {
          isComparing = true;
        }
      });
    }
  }

  void _removeFromComparison(int laptopId) {
    setState(() {
      selectedLaptops.removeWhere((laptop) => laptop['id'] == laptopId);
      if (selectedLaptops.length < 2) {
        isComparing = false;
      }
    });
  }

  void _clearComparison() {
    setState(() {
      selectedLaptops.clear();
      isComparing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFF093FB),
            ],
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: isComparing
                      ? _buildComparisonView()
                      : _buildLaptopSelectionView(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compare Laptops',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isComparing
                      ? 'Comparing ${selectedLaptops.length} laptops'
                      : 'Select laptops to compare (${selectedLaptops.length}/3)',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (selectedLaptops.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.clear_all, color: Colors.white),
                onPressed: _clearComparison,
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
              color: Colors.white,
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
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                  color: Colors.white,
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
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF667eea),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Compare Now',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selectedLaptops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final laptop = selectedLaptops[index];
                return Container(
                  width: 180,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: laptop['image'],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const SpinKitFadingCircle(
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              laptop['name'],
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              laptop['price'],
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeFromComparison(laptop['id']),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 12,
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
    );
  }

  Widget _buildLaptopCard(Map<String, dynamic> laptop, bool isSelected) {
    return GestureDetector(
      onTap: () => isSelected
          ? _removeFromComparison(laptop['id'])
          : _addToComparison(laptop),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF667eea) : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: CachedNetworkImage(
                          imageUrl: laptop['image'],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const SpinKitFadingCircle(
                            color: Color(0xFF667eea),
                            size: 30,
                          ),
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
                            fontSize: 14,
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
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
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
                  color: Colors.white,
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
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Add More',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _buildComparisonTable(),
              ),
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
      {'label': 'Battery', 'key': 'battery'},
      {'label': 'Weight', 'key': 'weight'},
      {'label': 'OS', 'key': 'os'},
      {'label': 'Warranty', 'key': 'warranty'},
      {'label': 'Ports', 'key': 'ports'},
    ];

    return Column(
      children: [
        // Header with laptop images and names
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF667eea).withOpacity(0.1),
                Colors.transparent
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  'Specifications',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
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
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const SpinKitFadingCircle(
                                  color: Color(0xFF667eea),
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              laptop['name'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D3748),
                              ),
                              textAlign: TextAlign.center,
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
                              itemSize: 12,
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              onRatingUpdate: (rating) {},
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ],
          ),
        ),
        const Divider(height: 1),
        // Specs comparison
        ...specs
            .map((spec) => _buildComparisonRow(
                  spec['label']!,
                  selectedLaptops
                      .map((laptop) => laptop[spec['key']!].toString())
                      .toList(),
                ))
            .toList(),
        // Pros and Cons
        _buildProsConsSection(),
      ],
    );
  }

  Widget _buildComparisonRow(String label, List<String> values) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            label == 'Price' ? const Color(0xFF667eea).withOpacity(0.05) : null,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
          ),
          ...values
              .map((value) => Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF4A5568),
                        fontWeight: label == 'Price'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildProsConsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pros & Cons',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 120),
              ...selectedLaptops
                  .map((laptop) => Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pros:',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[600],
                              ),
                            ),
                            ...laptop['pros']
                                .map<Widget>((pro) => Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle,
                                              color: Colors.green[600],
                                              size: 12),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              pro,
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: const Color(0xFF4A5568),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            const SizedBox(height: 8),
                            Text(
                              'Cons:',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[600],
                              ),
                            ),
                            ...laptop['cons']
                                .map<Widget>((con) => Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        children: [
                                          Icon(Icons.cancel,
                                              color: Colors.red[600], size: 12),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              con,
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
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
                      ))
                  .toList(),
            ],
          ),
        ],
      ),
    );
  }
}
