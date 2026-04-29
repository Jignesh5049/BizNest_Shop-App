import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:biznest_shop/core/biznest_core.dart';
import '../cubit/cart_cubit.dart';

class BusinessStoreScreen extends StatefulWidget {
  final String businessId;
  const BusinessStoreScreen({super.key, required this.businessId});

  @override
  State<BusinessStoreScreen> createState() => _BusinessStoreScreenState();
}

class _BusinessStoreScreenState extends State<BusinessStoreScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _business;
  List<dynamic> _products = [];
  List<String> _favoriteIds = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchFavorites();
  }

  Future<void> _fetchData() async {
    try {
      final bizRes = await _api.getStoreBusiness(widget.businessId);
      final data = bizRes.data is Map
          ? Map<String, dynamic>.from(bizRes.data as Map)
          : null;
      setState(() {
        _business = data?['business'] ?? data;
        _products = data?['products'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchFavorites() async {
    try {
      final res = await _api.getFavorites();
      final favs = res.data is List ? res.data : (res.data?['favorites'] ?? []);
      setState(() {
        _favoriteIds = (favs as List).map((f) {
          final prod = f['product'];
          return (prod is Map ? prod['_id'] : prod ?? f['_id'] ?? f).toString();
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _toggleFavorite(String productId) async {
    try {
      if (_favoriteIds.contains(productId)) {
        await _api.removeFavorite(productId);
        setState(() => _favoriteIds.remove(productId));
      } else {
        await _api.addFavorite(productId);
        setState(() => _favoriteIds.add(productId));
      }
    } catch (_) {}
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _products;
    final q = _search.toLowerCase();
    return _products
        .where((p) => (p['name'] ?? '').toString().toLowerCase().contains(q))
        .toList();
  }

  String _businessPhone(Map<String, dynamic> business) {
    final contact = business['contact'];
    if (contact is Map) {
      final phone = contact['phone'];
      if (phone != null && phone.toString().trim().isNotEmpty) {
        return phone.toString();
      }
    }
    if (contact is String && contact.trim().isNotEmpty) return contact;

    final phone = business['phone'];
    if (phone != null && phone.toString().trim().isNotEmpty) {
      return phone.toString();
    }
    return '';
  }

  String _businessCity(Map<String, dynamic> business) {
    final address = business['address'];
    if (address is Map) {
      final city = address['city'];
      if (city != null && city.toString().trim().isNotEmpty) {
        return city.toString();
      }
      final area = address['area'];
      if (area != null && area.toString().trim().isNotEmpty) {
        return area.toString();
      }
    }
    if (address is String && address.trim().isNotEmpty) return address;

    final city = business['city'];
    if (city != null && city.toString().trim().isNotEmpty) {
      return city.toString();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_business == null) {
      return Center(
        child: Text(
          'Business not found',
          style: GoogleFonts.inter(color: AppColors.gray500),
        ),
      );
    }

    final biz = _business!;
    final phone = _businessPhone(biz);
    final city = _businessCity(biz);
    final filtered = _filtered;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          IconButton(
            onPressed: () => context.go('/store'),
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Business Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary600, AppColors.primary800],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary800.withValues(alpha: 0.20),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    (biz['name'] ?? '?')[0].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  biz['name'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if ((biz['description'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    biz['description'],
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (phone.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            phone,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                          ),
                        ],
                      ),
                    if (city.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            city,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Search
          TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Search products in this store...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.gray200),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            '${filtered.length} Products',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 10),

          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: AppColors.gray300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No products found',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (ctx, constraints) {
                final cols = constraints.maxWidth > 700 ? 3 : 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: filtered
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
                                Container(
                                  color: AppColors.gray100,
                                  child: Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 40,
                                      color: AppColors.gray300,
                                    ),
                                  ),
                                ),
                          )
                        : Container(
                            color: AppColors.gray100,
                            child: Center(
                              child: Icon(
                                Icons.image,
                                size: 40,
                                color: AppColors.gray300,
                              ),
                            ),
                          ),
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
                                  cart.addToCart(
                                    p,
                                    businessId: widget.businessId,
                                    businessName: _business?['name'],
                                  );
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
}
