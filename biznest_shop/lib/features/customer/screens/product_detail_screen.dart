import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:biznest_shop/core/biznest_core.dart';
import '../cubit/cart_cubit.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _product;
  List<dynamic> _reviews = [];
  bool _loading = true;
  bool _isFavorite = false;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final prodRes = await _api.getStoreProduct(widget.productId);
      final reviewRes = await _api.getProductReviews(widget.productId);
      setState(() {
        // Ensure product is a Map
        if (prodRes.data is Map) {
          _product = Map<String, dynamic>.from(prodRes.data as Map);
        } else {
          _product = null;
        }
        // Reviews is a list
        _reviews = reviewRes.data is List ? reviewRes.data : [];
        _loading = false;
      });
      _checkFavorite();
    } catch (e) {
      if (kDebugMode) debugPrint('Product fetch error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkFavorite() async {
    try {
      final res = await _api.getFavorites();
      final favs = res.data is List ? res.data : (res.data?['favorites'] ?? []);
      setState(() {
        _isFavorite = (favs as List).any((f) {
          final prod = f['product'];
          final id = (prod is Map ? prod['_id'] : prod ?? f['_id'] ?? f)
              .toString();
          return id == widget.productId;
        });
      });
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await _api.removeFavorite(widget.productId);
      } else {
        await _api.addFavorite(widget.productId);
      }
      setState(() => _isFavorite = !_isFavorite);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_product == null) {
      return Center(
        child: Text(
          'Product not found',
          style: GoogleFonts.inter(color: AppColors.gray500),
        ),
      );
    }

    final p = _product!;
    final imageUrl = resolveProductImageUrl(p);
    final imageProvider = resolveImageProvider(imageUrl);
    final cart = context.read<CartCubit>();
    final inCart = cart.state.isInCart(widget.productId);
    // Get average rating from product
    final avgRating = (p['ratingAverage'] ?? 0.0) as num;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back
          IconButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                context.pop();
              } else {
                // fallback to store home if there's nothing to pop
                context.go('/store');
              }
            },
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 1.2,
              child: imageProvider != null
                  ? Image(
                      image: imageProvider,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _placeholder(),
                    )
                  : _placeholder(),
            ),
                      ),
          const SizedBox(height: 20),

          // Name + Favorite
          Row(
            children: [
              Expanded(
                child: Text(
                  p['name'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
              ),
              IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : AppColors.gray400,
                ),
              ),
            ],
          ),
          // Price
          Text(
            formatCurrency((p['sellingPrice'] ?? 0) as num),
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.primary600,
            ),
          ),
          const SizedBox(height: 10),

          // Category + Stock
          Wrap(
            spacing: 10,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p['category'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: (p['stock'] ?? 0) > 0
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (p['stock'] ?? 0) > 0
                      ? 'In Stock (${p['stock']})'
                      : 'Out of Stock',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: (p['stock'] ?? 0) > 0
                        ? const Color(0xFF166534)
                        : const Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Description
          if ((p['description'] ?? '').toString().isNotEmpty) ...[
            Text(
              'Description',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              p['description'],
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.gray600,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Quantity + Add to Cart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.gray100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Quantity
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        icon: const Icon(Icons.remove, size: 18),
                      ),
                      Text(
                        '$_quantity',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (p['stock'] ?? 0) <= 0
                        ? null
                        : () {
                            final businessId = p['businessId'] is Map
                                ? p['businessId']['_id']
                                : p['businessId'];
                            cart.addToCart(
                              p,
                              quantity: _quantity,
                              businessId: businessId,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${p['name']} added to cart'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                    icon: const Icon(Icons.shopping_cart, size: 18),
                    label: Text(
                      inCart
                          ? 'Update Cart'
                          : (cart.state.itemCount > 0
                                ? 'Add More Items'
                                : 'Add to Cart'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ReviewsratingCount
          Text(
            'Reviews (${_reviews.length})',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          if (_reviews.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < avgRating.round() ? Icons.star : Icons.star_border,
                    size: 18,
                    color: const Color(0xFFFBBF24),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${avgRating.toStringAsFixed(1)} avg',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),

          if (_reviews.isEmpty)
            Text(
              'No reviews yet',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.gray500),
            )
          else
            ..._reviews.map(
              (r) => _reviewCard(Map<String, dynamic>.from(r as Map)),
            ),
        ],
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary100,
                child: Text(
                  (r['customerName'] ?? '?').toString()[0].toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['customerName'] ?? 'Customer',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < (r['rating'] ?? 0)
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: const Color(0xFFFBBF24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatDate(r['createdAt'] ?? ''),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.gray400,
                ),
              ),
            ],
          ),
          if ((r['comment'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r['comment'],
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.gray600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.gray100,
      child: Center(
        child: Icon(Icons.image, size: 64, color: AppColors.gray300),
      ),
    );
  }
}
