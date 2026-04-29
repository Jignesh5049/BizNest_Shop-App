import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:biznest_shop/core/biznest_core.dart';
import '../widgets/customer_refresh_registry.dart';

class AllBusinessesScreen extends StatefulWidget {
  const AllBusinessesScreen({super.key});

  @override
  State<AllBusinessesScreen> createState() => _AllBusinessesScreenState();
}

class _AllBusinessesScreenState extends State<AllBusinessesScreen> {
  final _api = ApiService();
  List<dynamic> _businesses = [];
  bool _loading = true;
  String _search = '';
  String _category = 'all';

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
  void initState() {
    super.initState();
    CustomerRefreshRegistry.register('/store/businesses', _fetch);
    _fetch();
  }

  @override
  void dispose() {
    CustomerRefreshRegistry.unregister('/store/businesses', _fetch);
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final params = <String, dynamic>{};
      if (_category != 'all') params['category'] = _category;
      if (_search.isNotEmpty) params['search'] = _search;

      final res = await _api.getStoreBusinesses(params: params);
      if (!mounted) return;
      setState(() {
        _businesses = res.data is List
            ? res.data
            : (res.data?['businesses'] ?? []);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + Title
          Row(
            children: [
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
              const SizedBox(width: 12),
              Text(
                'All Businesses',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search
          TextField(
            onChanged: (v) {
              _search = v;
              _fetch();
            },
            decoration: InputDecoration(
              hintText: 'Search businesses...',
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
          const SizedBox(height: 14),

          // Category Chips
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _categoryChip('All', 'all'),
                ...businessCategories.map(
                  (c) => _categoryChip(c.label, c.value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            '${_businesses.length} businesses',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 10),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_businesses.isEmpty)
            _emptyState()
          else
            ..._businesses.map(
              (b) => _bizCard(Map<String, dynamic>.from(b as Map)),
            ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, String value) {
    final active = _category == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _category = value;
          });
          _fetch();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary600 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? AppColors.primary600 : AppColors.gray200,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.gray600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bizCard(Map<String, dynamic> b) {
    final city = _businessCity(b);
    return GestureDetector(
      onTap: () => context.go('/store/business/${b['_id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
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
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary100,
              child: Text(
                (b['name'] ?? '?')[0].toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b['name'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    b['category'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray500,
                    ),
                  ),
                  if (city.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.gray400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          city,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.gray500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.store_outlined, size: 56, color: AppColors.gray300),
            const SizedBox(height: 12),
            Text(
              'No businesses found',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search or filters',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}
