import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:biznest_shop/core/biznest_core.dart';
import '../cubit/cart_cubit.dart';
import '../widgets/customer_refresh_registry.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  final _api = ApiService();
  List<dynamic> _orders = [];
  bool _loading = true;
  String _viewFilter = 'active';

  @override
  void initState() {
    super.initState();
    CustomerRefreshRegistry.register('/store/orders', _fetch);
    _fetch();
  }

  @override
  void dispose() {
    CustomerRefreshRegistry.unregister('/store/orders', _fetch);
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final res = await _api.getStoreOrders();
      if (!mounted) return;
      setState(() {
        _orders = res.data is List ? res.data : (res.data?['orders'] ?? []);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _activeOrders {
    return _orders.where((o) {
      final status = (o['status'] ?? '').toString().toLowerCase();
      return status != 'completed' && status != 'cancelled';
    }).toList();
  }

  List<dynamic> get _completedOrders {
    return _orders.where((o) {
      final status = (o['status'] ?? '').toString().toLowerCase();
      return status == 'completed';
    }).toList();
  }

  List<dynamic> get _cancelledOrders {
    return _orders.where((o) {
      final status = (o['status'] ?? '').toString().toLowerCase();
      return status == 'cancelled';
    }).toList();
  }

  void _reorder(Map<String, dynamic> order) {
    final items = order['items'] ?? [];
    if (items is List && items.isNotEmpty) {
      context.read<CartCubit>().addItemsForReorder(items);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Items added to cart for reorder')),
      );
      context.go('/store/cart');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final activeOrders = _activeOrders;
    final completedOrders = _completedOrders;
    final cancelledOrders = _cancelledOrders;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Orders',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          Text(
            '${_orders.length} orders',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 40,
            child: Row(
              children: [
                _filterChip('Active', 'active'),
                const SizedBox(width: 8),
                _filterChip('Completed', 'completed'),
                const SizedBox(width: 8),
                _filterChip('Cancelled', 'cancelled'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (_viewFilter == 'active') ...[
            _sectionHeader('Active Orders', activeOrders.length),
            const SizedBox(height: 10),
            if (activeOrders.isEmpty)
              _sectionEmptyState(
                'No active orders',
                'Your ongoing orders will appear here',
              )
            else
              ...activeOrders.map(
                (o) => _orderCard(Map<String, dynamic>.from(o as Map)),
              ),
          ] else if (_viewFilter == 'completed') ...[
            _sectionHeader('Completed Orders', completedOrders.length),
            const SizedBox(height: 10),
            if (completedOrders.isEmpty)
              _sectionEmptyState(
                'No completed orders',
                'Completed orders will appear here',
              )
            else
              ...completedOrders.map(
                (o) => _orderCard(Map<String, dynamic>.from(o as Map)),
              ),
          ] else ...[
            _sectionHeader('Cancelled Orders', cancelledOrders.length),
            const SizedBox(height: 10),
            if (cancelledOrders.isEmpty)
              _sectionEmptyState(
                'No cancelled orders',
                'Cancelled orders will appear here',
              )
            else
              ...cancelledOrders.map(
                (o) => _orderCard(Map<String, dynamic>.from(o as Map)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _viewFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewFilter = value),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary600 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.primary600 : AppColors.gray200,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppColors.gray600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _orderCard(Map<String, dynamic> o) {
    final status = (o['status'] ?? 'pending').toString();
    final statusColors = getStatusColor(status);
    final items = o['items'] as List? ?? [];
    final total = (o['totalAmount'] ?? o['total'] ?? 0).toDouble();

    return GestureDetector(
      onTap: () => context.go('/store/orders/${o['_id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.shopping_bag,
                    size: 20,
                    color: AppColors.primary600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${(o['orderNumber'] ?? o['_id'] ?? '').toString().substring(0, 8)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                      Text(
                        formatDate(o['createdAt'] ?? ''),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColors.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status.replaceFirstMapped(
                      RegExp(r'^\w'),
                      (m) => m[0]!.toUpperCase(),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColors.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Show item images and details
            if (items.isNotEmpty) ...[
              SizedBox(
                height: 64,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length > 4 ? 4 : items.length,
                  itemBuilder: (context, index) {
                    if (index == 3 && items.length > 4) {
                      return Container(
                        width: 64,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '+${items.length - 3}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                      );
                    }
                    final item = items[index];
                    final imageUrl = resolveOrderItemImageUrl(
                      Map<String, dynamic>.from(item as Map),
                    );
                    final imageProvider = resolveImageProvider(imageUrl);
                    return Container(
                      width: 64,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: imageProvider != null
                            ? Image(
                                image: imageProvider,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.inventory_2,
                                      color: AppColors.gray400,
                                      size: 24,
                                    ),
                              )
                            : Icon(
                                Icons.inventory_2,
                                color: AppColors.gray400,
                                size: 24,
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Text(
                  formatCurrency(total),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary600,
                  ),
                ),
                Text(
                  ' · ${items.length} items',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.gray500,
                  ),
                ),
                const Spacer(),
                if (status == 'completed')
                  TextButton.icon(
                    onPressed: () => _reorder(o),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reorder'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary600,
                      textStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  Widget _sectionEmptyState(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: [
          Icon(Icons.shopping_bag_outlined, size: 40, color: AppColors.gray300),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}
