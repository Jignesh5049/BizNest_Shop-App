import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:biznest_shop/core/biznest_core.dart';
import 'customer_profile_option_screens.dart';
import '../widgets/customer_refresh_registry.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});
  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _api = ApiService();
  String _name = 'Guest User';
  String _email = 'guest@example.com';
  String _phone = '';
  List<dynamic> _addresses = [];
  List<dynamic> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    CustomerRefreshRegistry.register('/store/profile', _fetch);
    _fetch();
  }

  @override
  void dispose() {
    CustomerRefreshRegistry.unregister('/store/profile', _fetch);
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _name = (authState.user['name'] ?? '').toString().trim();
        _email = (authState.user['email'] ?? '').toString().trim();
        _phone = (authState.user['phone'] ?? '').toString().trim();
      }
      final addrRes = await _api.getAddresses();
      _addresses = addrRes.data is List
          ? addrRes.data
          : (addrRes.data?['addresses'] ?? []);
      try {
        final ticketRes = await _api.getCustomerSupportTickets();
        _tickets = ticketRes.data is List
            ? ticketRes.data
            : (ticketRes.data?['tickets'] ?? []);
      } catch (_) {
        final ticketRes = await _api.getSupportTickets();
        _tickets = ticketRes.data is List
            ? ticketRes.data
            : (ticketRes.data?['tickets'] ?? []);
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openScreen(Widget child) async {
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => child));
    _fetch();
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFE4F0ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF218465), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E2426),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF62716E),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade500,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF243533),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final avatarLabel = _name.trim().isEmpty ? 'G' : _name.trim()[0];
    final displayName = _name.trim().isEmpty ? 'Guest User' : _name.trim();
    final displayEmail = _email.trim().isEmpty ? 'guest@example.com' : _email;
    final addressCount = _addresses.length;
    final ticketCount = _tickets.length;

    return Stack(
      children: [
        Positioned(
          left: -70,
          top: 360,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE2EBE5),
            ),
          ),
        ),
        Positioned(
          right: -90,
          top: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE4ECE6),
            ),
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E8A64), Color(0xFF2CAE7F)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.30),
                                Colors.white.withValues(alpha: 0.14),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              avatarLabel.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: GoogleFonts.inter(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                displayEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Verified account',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _sectionTitle('Account'),
              _optionTile(
                icon: Icons.person_outline_rounded,
                title: 'Edit Profile',
                subtitle: 'Update your personal details',
                onTap: () => _openScreen(
                  EditProfileDetailsScreen(
                    initialName: displayName,
                    initialEmail: displayEmail,
                    initialPhone: _phone,
                  ),
                ),
              ),
              _optionTile(
                icon: Icons.location_on_outlined,
                title: 'Delivery Addresses',
                subtitle: addressCount == 0
                    ? 'Manage your saved addresses'
                    : '$addressCount saved address(es)',
                onTap: () => _openScreen(const DeliveryAddressesScreen()),
              ),
              _optionTile(
                icon: Icons.credit_card_rounded,
                title: 'Payment Methods',
                subtitle: 'Cards, UPI, and wallets',
                onTap: () => _openScreen(const PaymentMethodsScreen()),
              ),
              const SizedBox(height: 3),
              _sectionTitle('Activity & Support'),
              _optionTile(
                icon: Icons.history_rounded,
                title: 'Order History',
                subtitle: 'Track all past orders',
                onTap: () => _openScreen(const OrderHistorySummaryScreen()),
              ),
              _optionTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Delivery and offer alerts',
                onTap: () =>
                    _openScreen(const NotificationsPreferencesScreen()),
              ),
              _optionTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                subtitle: ticketCount == 0
                    ? 'Contact support anytime'
                    : '$ticketCount open support ticket(s)',
                onTap: () => _openScreen(const HelpSupportScreen()),
              ),
              _optionTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'App preferences and permissions',
                onTap: () => _openScreen(const SettingsPreferencesScreen()),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _openScreen(const LogoutConfirmationScreen()),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE35257),
                    side: const BorderSide(
                      color: Color(0xFFE35257),
                      width: 1.2,
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
