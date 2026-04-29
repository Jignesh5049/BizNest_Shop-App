import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:biznest_shop/core/biznest_core.dart';
import '../cubit/cart_cubit.dart';
import '../widgets/customer_refresh_registry.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();
  List<dynamic> _products = [];
  List<dynamic> _businesses = [];
  List<String> _favoriteIds = [];
  bool _loading = true;
  bool _showBannerSearch = false;
  String _search = '';
  String _category = 'all';
  String? _sort;

  @override
  void initState() {
    super.initState();
    CustomerRefreshRegistry.register('/store', _fetchData);
    _fetchData();
    _fetchFavorites();
  }

  @override
  void dispose() {
    CustomerRefreshRegistry.unregister('/store', _fetchData);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final params = <String, dynamic>{};
      if (_category != 'all') params['category'] = _category;
      if (_search.isNotEmpty) params['search'] = _search;
      if (_sort != null && _sort!.isNotEmpty) {
        params['sort'] = _sort;
      }

      final prodRes = await _api.getAllStoreProducts(params: params);
      final bizRes = await _api.getStoreBusinesses();
      if (!mounted) return;
      setState(() {
        _products = prodRes.data is List
            ? prodRes.data
            : (prodRes.data?['products'] ?? []);
        _businesses = bizRes.data is List
            ? bizRes.data
            : (bizRes.data?['businesses'] ?? []);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchFavorites() async {
    try {
      final res = await _api.getFavorites();
      final favs = res.data is List ? res.data : (res.data?['favorites'] ?? []);
      if (!mounted) return;
      setState(() {
        _favoriteIds = (favs as List)
            .map(
              (f) =>
                  ((f['product'] ?? f['_id'] ?? f) is Map
                          ? f['product']['_id']
                          : f['product'] ?? f)
                      .toString(),
            )
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _toggleFavorite(String productId) async {
    try {
      if (_favoriteIds.contains(productId)) {
        await _api.removeFavorite(productId);
        if (!mounted) return;
        setState(() => _favoriteIds.remove(productId));
      } else {
        await _api.addFavorite(productId);
        if (!mounted) return;
        setState(() => _favoriteIds.add(productId));
      }
    } catch (_) {}
  }

  IconData _getCategoryIcon(String value) {
    return switch (value) {
      'all' => Icons.apps,
      'retail' => Icons.store,
      'food' => Icons.restaurant,
      'services' => Icons.miscellaneous_services,
      'handmade' => Icons.palette,
      'consulting' => Icons.business_center,
      'other' => Icons.more_horiz,
      _ => Icons.category,
    };
  }

  String _sortLabel(String? value) {
    return switch (value) {
      'newest' => 'Newest First',
      'price_low' => 'Price: Low to High',
      'price_high' => 'Price: High to Low',
      'name_asc' => 'Name: A to Z',
      _ => 'Sort',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary600, AppColors.primary800],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary800.withValues(alpha: 0.20),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Discover Local Businesses',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showBannerSearch = !_showBannerSearch;
                          if (!_showBannerSearch && _search.isNotEmpty) {
                            _search = '';
                            _searchCtrl.clear();
                            _fetchData();
                          }
                        });
                      },
                      icon: Icon(
                        _showBannerSearch ? Icons.close : Icons.search,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Shop from your favorite local stores',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.35,
                  ),
                ),
                if (_showBannerSearch) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) {
                      _search = v;
                      _fetchData();
                    },
                    style: GoogleFonts.inter(color: AppColors.gray900),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: GoogleFonts.inter(color: AppColors.gray400),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Featured Businesses
          if (_businesses.isNotEmpty) ...[
            _sectionHeader(
              title: 'Featured Businesses',
              actionLabel: 'View All',
              onActionTap: () => context.go('/store/businesses'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 102,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _businesses.length > 6 ? 6 : _businesses.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _businessCard(_businesses[i]),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Category Filters
          _sectionHeader(title: 'Categories'),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _categoryChip('All', 'all'),
                _categoryChip('Retail', 'retail'),
                _categoryChip('Other', 'other'),
                ...businessCategories.map(
                  (c) => c.value == 'retail' || c.value == 'other'
                      ? const SizedBox.shrink()
                      : _categoryChip(c.label, c.value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Products + Sort
          _sectionHeader(
            title: 'Products',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PopupMenuButton<String>(
                  onSelected: (v) {
                    setState(() {
                      _sort = v;
                    });
                    _fetchData();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'newest',
                      child: Text('Newest First'),
                    ),
                    const PopupMenuItem(
                      value: 'price_low',
                      child: Text('Price: Low to High'),
                    ),
                    const PopupMenuItem(
                      value: 'price_high',
                      child: Text('Price: High to Low'),
                    ),
                    const PopupMenuItem(
                      value: 'name_asc',
                      child: Text('Name: A to Z'),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _sort != null ? AppColors.primary50 : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _sort != null
                            ? AppColors.primary600
                            : AppColors.gray200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.swap_vert_rounded,
                          size: 16,
                          color:
                              _sort != null ? AppColors.primary600 : AppColors.gray600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _sortLabel(_sort),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _sort != null
                                ? AppColors.primary700
                                : AppColors.gray700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_sort != null) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _sort = null;
                      });
                      _fetchData();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: AppColors.gray600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_products.length} items available',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 10),

          if (_products.isEmpty)
            _emptyState(
              'No products found',
              'Try adjusting your search or filters',
            )
          else
            LayoutBuilder(
              builder: (ctx, constraints) {
                final cols = constraints.maxWidth > 700 ? 3 : 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _products
                      .map(
                        (p) => SizedBox(
                          width:
                              (constraints.maxWidth - 10 * (cols - 1)) / cols,
                          child: _productCard(
                            Map<String, dynamic>.from(p as Map),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    String? actionLabel,
    VoidCallback? onActionTap,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.gray900,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          trailing
        else if (actionLabel != null && onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(
              actionLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _categoryChip(String label, String value) {
    final active = _category == value;
    final icon = _getCategoryIcon(value);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _category = value;
          });
          _fetchData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.primary600 : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? AppColors.primary600 : AppColors.gray200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? Colors.white : AppColors.gray600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _businessCard(dynamic biz) {
    final b = Map<String, dynamic>.from(biz as Map);
    return GestureDetector(
      onTap: () => context.go('/store/business/${b['_id']}'),
      child: SizedBox(
        width: 88,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary100,
              child: Text(
                (b['name'] ?? '?')[0].toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              b['name'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> p) {
    final imageUrl = resolveProductImageUrl(p);
    final imageProvider = resolveImageProvider(imageUrl);
    final isFav = _favoriteIds.contains(p['_id']);

    return GestureDetector(
      onTap: () => context.go('/store/product/${p['_id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: imageProvider != null
                        ? Image(
                            image: imageProvider,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _placeholderImage(),
                          )
                        : _placeholderImage(),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _toggleFavorite(p['_id']),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isFav ? Colors.red : AppColors.gray400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['name'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency(p['sellingPrice'] ?? p['price'] ?? 0),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  BlocBuilder<CartCubit, CartState>(
                    builder: (context, cartState) {
                      final cart = context.read<CartCubit>();
                      final inCart = cartState.isInCart(p['_id']);

                      return SizedBox(
                        width: double.infinity,
                        child: inCart
                            ? Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 36,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppColors.primary600,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: IconButton(
                                              onPressed: () {
                                                final currentQty = cartState
                                                    .getQuantity(p['_id']);
                                                cart.updateQuantity(
                                                  p['_id'],
                                                  currentQty - 1,
                                                );
                                              },
                                              icon: Icon(
                                                Icons.remove,
                                                size: 16,
                                                color: AppColors.primary600,
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                          Text(
                                            '${cartState.getQuantity(p['_id'])}',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.gray900,
                                            ),
                                          ),
                                          Expanded(
                                            child: IconButton(
                                              onPressed: () {
                                                final currentQty = cartState
                                                    .getQuantity(p['_id']);
                                                cart.updateQuantity(
                                                  p['_id'],
                                                  currentQty + 1,
                                                );
                                              },
                                              icon: Icon(
                                                Icons.add,
                                                size: 16,
                                                color: AppColors.primary600,
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  final businessId = p['businessId'] is Map
                                      ? p['businessId']['_id']
                                      : p['businessId'];
                                  cart.addToCart(p, businessId: businessId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${p['name']} added to cart',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  textStyle: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: Text(
                                  cartState.itemCount > 0
                                      ? 'Add More Items'
                                      : 'Add to Cart',
                                ),
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: AppColors.gray100,
      child: Center(
        child: Icon(Icons.image, size: 40, color: AppColors.gray300),
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 56, color: AppColors.gray300),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}
