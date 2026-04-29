import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:biznest_shop/core/biznest_core.dart';

class _ProfileOptionScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _ProfileOptionScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 54,
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: const Color(0xFF1D2B28),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: child,
    );
  }
}

class EditProfileDetailsScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialPhone;

  const EditProfileDetailsScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
  });

  @override
  State<EditProfileDetailsScreen> createState() =>
      _EditProfileDetailsScreenState();
}

class _EditProfileDetailsScreenState extends State<EditProfileDetailsScreen> {
  final _api = ApiService();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _emailCtrl = TextEditingController(text: widget.initialEmail);
    _phoneCtrl = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.updateMe({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update profile right now')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool enabled = true,
  }) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF0F3F1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileOptionScaffold(
      title: 'Edit Profile',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE6ECE8)),
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
                _field('Full Name', _nameCtrl),
                const SizedBox(height: 12),
                _field('Email', _emailCtrl, enabled: false),
                const SizedBox(height: 12),
                _field('Phone Number', _phoneCtrl),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1F8A65),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}

class DeliveryAddressesScreen extends StatefulWidget {
  const DeliveryAddressesScreen({super.key});

  @override
  State<DeliveryAddressesScreen> createState() =>
      _DeliveryAddressesScreenState();
}

class _DeliveryAddressesScreenState extends State<DeliveryAddressesScreen> {
  final _api = ApiService();
  List<dynamic> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await _api.getAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = res.data is List
            ? res.data
            : (res.data?['addresses'] ?? []);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddAddressSheet() async {
    final labelCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final pincodeCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add New Address',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _addressField('Label (Home, Office)', labelCtrl),
              const SizedBox(height: 8),
              _addressField('Street', streetCtrl),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _addressField('City', cityCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: _addressField('State', stateCtrl)),
                ],
              ),
              const SizedBox(height: 8),
              _addressField('Pincode', pincodeCtrl),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1F8A65),
                  ),
                  onPressed: () async {
                    if (streetCtrl.text.trim().isEmpty) return;
                    try {
                      await _api.addAddress({
                        'label': labelCtrl.text.trim().isEmpty
                            ? 'Home'
                            : labelCtrl.text.trim(),
                        'street': streetCtrl.text.trim(),
                        'city': cityCtrl.text.trim(),
                        'state': stateCtrl.text.trim(),
                        'pincode': pincodeCtrl.text.trim(),
                      });
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      _fetch();
                    } catch (_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to add address')),
                      );
                    }
                  },
                  child: const Text('Save Address'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteAddress(String id) async {
    try {
      await _api.deleteAddress(id);
      _fetch();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to delete address')));
    }
  }

  Widget _addressField(String hint, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDCE6E1)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileOptionScaffold(
      title: 'Delivery Addresses',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._addresses.map((raw) {
                  final a = Map<String, dynamic>.from(raw as Map);
                  final street = (a['street'] ?? '').toString();
                  final city = (a['city'] ?? '').toString();
                  final state = (a['state'] ?? '').toString();
                  final pincode = (a['pincode'] ?? '').toString();
                  final addressText = [
                    street,
                    city,
                    state,
                    pincode,
                  ].where((value) => value.trim().isNotEmpty).join(', ');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE6ECE8)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF1F8A65),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (a['label'] ?? 'Address').toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                addressText,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF5E6D68),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _deleteAddress((a['_id'] ?? '').toString()),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _showAddAddressSheet,
                  icon: const Icon(Icons.add),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1F8A65),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  label: const Text('Add New Address'),
                ),
              ],
            ),
    );
  }
}

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ProfileOptionScaffold(
      title: 'Payment Methods',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _methodTile(
            icon: Icons.payments_outlined,
            title: 'UPI',
            subtitle: 'Google Pay, PhonePe, Paytm',
          ),
          _methodTile(
            icon: Icons.credit_card_rounded,
            title: 'Cards',
            subtitle: 'Visa, Mastercard, RuPay',
          ),
          _methodTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallets',
            subtitle: 'Use wallet balances at checkout',
          ),
          _methodTile(
            icon: Icons.local_shipping_outlined,
            title: 'Cash on Delivery',
            subtitle: 'Default fallback payment option',
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add payment method coming soon')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1F8A65),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Payment Method'),
          ),
        ],
      ),
    );
  }

  Widget _methodTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1F8A65)),
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(color: const Color(0xFF5E6D68)),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class OrderHistorySummaryScreen extends StatelessWidget {
  const OrderHistorySummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ProfileOptionScaffold(
      title: 'Order History',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _actionCard(
            icon: Icons.list_alt_rounded,
            title: 'View all orders',
            subtitle: 'See your complete order timeline',
            onTap: () => context.go('/store/orders'),
          ),
          _actionCard(
            icon: Icons.local_shipping_outlined,
            title: 'Track active orders',
            subtitle: 'Follow status and delivery updates',
            onTap: () => context.go('/store/orders'),
          ),
          _actionCard(
            icon: Icons.replay_circle_filled_outlined,
            title: 'Reorder your favorites',
            subtitle: 'Quickly buy items again',
            onTap: () => context.go('/store/orders'),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF1F8A65)),
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(color: const Color(0xFF5E6D68)),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class NotificationsPreferencesScreen extends StatefulWidget {
  const NotificationsPreferencesScreen({super.key});

  @override
  State<NotificationsPreferencesScreen> createState() =>
      _NotificationsPreferencesScreenState();
}

class _NotificationsPreferencesScreenState
    extends State<NotificationsPreferencesScreen> {
  bool _orderUpdates = true;
  bool _offers = true;
  bool _walletUpdates = false;
  bool _supportReplies = true;

  @override
  Widget build(BuildContext context) {
    return _ProfileOptionScaffold(
      title: 'Notifications',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _switchTile(
            title: 'Order updates',
            subtitle: 'Order confirmation, packed, and delivered',
            value: _orderUpdates,
            onChanged: (v) => setState(() => _orderUpdates = v),
          ),
          _switchTile(
            title: 'Offers and discounts',
            subtitle: 'Price drops, deals, and seasonal sales',
            value: _offers,
            onChanged: (v) => setState(() => _offers = v),
          ),
          _switchTile(
            title: 'Wallet and payment alerts',
            subtitle: 'Payment confirmations and refund updates',
            value: _walletUpdates,
            onChanged: (v) => setState(() => _walletUpdates = v),
          ),
          _switchTile(
            title: 'Support ticket updates',
            subtitle: 'Replies from support team',
            value: _supportReplies,
            onChanged: (v) => setState(() => _supportReplies = v),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile.adaptive(
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(color: const Color(0xFF5E6D68)),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1F8A65),
      ),
    );
  }
}

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _api = ApiService();
  bool _loading = true;
  List<dynamic> _tickets = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await _api.getCustomerSupportTickets();
      if (!mounted) return;
      setState(() {
        _tickets = res.data is List ? res.data : (res.data?['tickets'] ?? []);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _createTicket() async {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Raise Support Ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectCtrl,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: messageCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (subjectCtrl.text.trim().isEmpty ||
                  messageCtrl.text.trim().isEmpty) {
                return;
              }
              try {
                await _api.createSupportTicket({
                  'subject': subjectCtrl.text.trim(),
                  'message': messageCtrl.text.trim(),
                  'issueType': 'general',
                });
                if (!mounted) return;
                Navigator.pop(ctx);
                _fetch();
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to create support ticket'),
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

  @override
  Widget build(BuildContext context) {
    return _ProfileOptionScaffold(
      title: 'Help & Support',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE6ECE8)),
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
                      Text(
                        'Need help?',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create a support ticket and our team will respond soon.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF5E6D68),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _createTicket,
                        icon: const Icon(Icons.support_agent),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1F8A65),
                        ),
                        label: const Text('Raise Ticket'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Recent tickets',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (_tickets.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE6ECE8)),
                    ),
                    child: Text(
                      'No tickets yet',
                      style: GoogleFonts.inter(color: const Color(0xFF5E6D68)),
                    ),
                  )
                else
                  ..._tickets.take(8).map((raw) {
                    final t = Map<String, dynamic>.from(raw as Map);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE6ECE8)),
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
                              Expanded(
                                child: Text(
                                  (t['subject'] ?? 'Support request')
                                      .toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE4F2EC),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  (t['status'] ?? 'open').toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF1F8A65),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (t['message'] ?? 'No message').toString(),
                            style: GoogleFonts.inter(
                              color: const Color(0xFF5E6D68),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class SettingsPreferencesScreen extends StatefulWidget {
  const SettingsPreferencesScreen({super.key});

  @override
  State<SettingsPreferencesScreen> createState() =>
      _SettingsPreferencesScreenState();
}

class _SettingsPreferencesScreenState extends State<SettingsPreferencesScreen> {
  String _language = 'English';
  bool _locationPermission = true;
  bool _cameraPermission = false;
  bool _faceId = false;

  @override
  Widget build(BuildContext context) {
    return _ProfileOptionScaffold(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE6ECE8)),
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
                Text(
                  'App language',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _language,
                  items: const ['English', 'Hindi', 'Gujarati']
                      .map(
                        (lang) =>
                            DropdownMenuItem(value: lang, child: Text(lang)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _language = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _permissionTile(
            title: 'Location access',
            subtitle: 'Use location for faster delivery estimates',
            value: _locationPermission,
            onChanged: (v) => setState(() => _locationPermission = v),
          ),
          _permissionTile(
            title: 'Camera access',
            subtitle: 'Upload photos to support or reviews',
            value: _cameraPermission,
            onChanged: (v) => setState(() => _cameraPermission = v),
          ),
          _permissionTile(
            title: 'Face ID / Fingerprint lock',
            subtitle: 'Secure app opening with biometrics',
            value: _faceId,
            onChanged: (v) => setState(() => _faceId = v),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Privacy Policy'),
                  content: const Text(
                    'We collect only essential order and account data to provide deliveries and support services.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('View Privacy Policy'),
          ),
        ],
      ),
    );
  }

  Widget _permissionTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile.adaptive(
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(color: const Color(0xFF5E6D68)),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1F8A65),
      ),
    );
  }
}

class LogoutConfirmationScreen extends StatelessWidget {
  const LogoutConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ProfileOptionScaffold(
      title: 'Logout',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE6ECE8)),
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
                  const Icon(
                    Icons.logout_rounded,
                    size: 46,
                    color: Color(0xFFE35257),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Are you sure you want to logout?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You can sign in again anytime using your account.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: const Color(0xFF5E6D68)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                  context.go('/login');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE35257),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Logout Now'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
