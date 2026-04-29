import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:biznest_shop/core/biznest_core.dart';
import '../cubit/cart_cubit.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _api = ApiService();
  List<dynamic> _addresses = [];
  String? _selectedAddressId;
  String _paymentMethod = 'cash';
  bool _loading = true;
  bool _placing = false;

  // New address form
  final _labelCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAddresses() async {
    try {
      final res = await _api.getAddresses();
      final addrs = res.data is List
          ? res.data
          : (res.data?['addresses'] ?? []);
      setState(() {
        _addresses = addrs;
        if (_addresses.isNotEmpty && _selectedAddressId == null) {
          _selectedAddressId = _addresses.first['_id'];
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addAddress() async {
    if (_streetCtrl.text.trim().isEmpty || _cityCtrl.text.trim().isEmpty) {
      return;
    }
    try {
      await _api.addAddress({
        'label': _labelCtrl.text.trim().isNotEmpty
            ? _labelCtrl.text.trim()
            : 'Home',
        'street': _streetCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
      });
      _labelCtrl.clear();
      _streetCtrl.clear();
      _cityCtrl.clear();
      _stateCtrl.clear();
      _pincodeCtrl.clear();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      _fetchAddresses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add address: $e')));
      }
    }
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartCubit>();
    final state = cart.state;
    if (state.items.isEmpty) return;
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    setState(() => _placing = true);
    try {
      // Group items by businessId
      final grouped = <String, List<CartItem>>{};
      for (final item in state.items) {
        final bizId = item.businessId ?? 'unknown';
        grouped.putIfAbsent(bizId, () => []).add(item);
      }

      for (final entry in grouped.entries) {
        await _api.createStoreOrder({
          'businessId': entry.key,
          'items': entry.value
              .map(
                (i) => {
                  'productId': i.productId,
                  'name': i.name,
                  'price': i.price,
                  'quantity': i.quantity,
                },
              )
              .toList(),
          'shippingAddress': _selectedAddressId,
          'paymentMethod': _paymentMethod,
        });
      }

      cart.clearCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        context.go('/store/orders');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  void _showAddAddressDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Address',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 16),
                _textField('Label (e.g. Home, Office)', _labelCtrl),
                const SizedBox(height: 10),
                _textField('Street Address', _streetCtrl),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _textField('City', _cityCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _textField('State', _stateCtrl)),
                  ],
                ),
                const SizedBox(height: 10),
                _textField(
                  'Pincode',
                  _pincodeCtrl,
                  keyboard: TextInputType.number,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _addAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(
    String hint,
    TextEditingController ctrl, {
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.gray200),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        context.pop();
                      } else {
                        context.go('/store/cart');
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
                  const SizedBox(width: 12),
                  Text(
                    'Checkout',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Delivery Address
              _sectionHeader('Delivery Address', Icons.location_on_outlined),
              const SizedBox(height: 12),
              if (_addresses.isEmpty)
                _noAddressCard()
              else
                ..._addresses.map(
                  (a) => _addressCard(Map<String, dynamic>.from(a as Map)),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _showAddAddressDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New Address'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary600,
                ),
              ),
              const SizedBox(height: 20),

              // Payment Method
              _sectionHeader('Payment Method', Icons.payment_outlined),
              const SizedBox(height: 12),
              _paymentOption(
                'cash',
                'Cash on Delivery',
                Icons.money,
                'Pay when you receive',
              ),
              _paymentOption(
                'upi',
                'UPI Payment',
                Icons.phone_android,
                'GPay, PhonePe, Paytm',
              ),
              _paymentOption(
                'card',
                'Card Payment',
                Icons.credit_card,
                'Credit/Debit Card',
              ),
              const SizedBox(height: 20),

              // Order Summary
              _sectionHeader('Order Summary', Icons.receipt_long_outlined),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
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
                  children: [
                    ...cartState.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.name} x${item.quantity}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.gray700,
                                ),
                              ),
                            ),
                            Text(
                              formatCurrency(item.total),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900,
                          ),
                        ),
                        Text(
                          formatCurrency(cartState.total),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Place Order Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _placing ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _placing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Place Order'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary600),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.gray900,
          ),
        ),
      ],
    );
  }

  Widget _addressCard(Map<String, dynamic> addr) {
    final id = addr['_id'] as String;
    final selected = _selectedAddressId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedAddressId = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary500 : AppColors.gray200,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.05 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary600 : AppColors.gray400,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    addr['label'] ?? 'Address',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                  Text(
                    '${addr['street'] ?? ''}, ${addr['city'] ?? ''}, ${addr['state'] ?? ''} ${addr['pincode'] ?? ''}'
                        .trim(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noAddressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Center(
        child: Text(
          'No saved addresses. Add one below.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.gray500),
        ),
      ),
    );
  }

  Widget _paymentOption(
    String value,
    String label,
    IconData icon,
    String desc,
  ) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary500 : AppColors.gray200,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.05 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.primary600 : AppColors.gray400,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary600 : AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}
