import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:biznest_shop/core/biznest_core.dart';
import '../screens/customer_home_screen.dart';
import '../screens/customer_orders_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/customer_profile_screen.dart';
import '../cubit/cart_cubit.dart';
import 'customer_refresh_registry.dart';

class CustomerShell extends StatefulWidget {
  final Widget child;
  const CustomerShell({super.key, required this.child});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  static const List<String> _coreRoutes = [
    '/store',
    '/store/orders',
    '/store/favorites',
    '/store/profile',
  ];
  late final PageController _corePageController;
  bool _routeLoading = false;
  final List<Widget> _corePages = const [
    CustomerHomeScreen(),
    CustomerOrdersScreen(),
    FavoritesScreen(),
    CustomerProfileScreen(),
  ];

  bool _matchesRoute(String location, String route) {
    if (route == '/store') {
      return location == '/store';
    }
    return location == route || location.startsWith('$route/');
  }

  @override
  void initState() {
    super.initState();
    _corePageController = PageController(initialPage: 0);
  }

  @override
  void didUpdateWidget(covariant CustomerShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final routeChanged =
        oldWidget.child.runtimeType != widget.child.runtimeType ||
        oldWidget.child.key != widget.child.key;
    if (routeChanged) {
      _showRouteLoading();
    }
  }

  @override
  void dispose() {
    _corePageController.dispose();
    super.dispose();
  }

  int _coreIndexFromLocation(String location) {
    final index = _coreRoutes.indexWhere(
      (route) => _matchesRoute(location, route),
    );
    return index < 0 ? 0 : index;
  }

  bool _matchesAnyRoute(String location, List<String> routes) {
    return routes.any((route) => _matchesRoute(location, route));
  }

  void _syncCorePageIfNeeded(int coreIndex) {
    if (!_corePageController.hasClients) return;
    final currentPage = (_corePageController.page ?? coreIndex.toDouble())
        .round();
    if (currentPage == coreIndex) return;
    _corePageController.jumpToPage(coreIndex);
  }

  void _showRouteLoading() {
    if (_routeLoading || !mounted) return;
    setState(() => _routeLoading = true);
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) {
        setState(() => _routeLoading = false);
      }
    });
  }

  Widget _coreSwipePage(String location) {
    final coreIndex = _coreIndexFromLocation(location);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncCorePageIfNeeded(coreIndex);
    });

    return PageView.builder(
      controller: _corePageController,
      itemCount: _corePages.length,
      onPageChanged: (index) {
        final target = _coreRoutes[index];
        if (target != location) {
          context.go(target);
        }
      },
      itemBuilder: (context, index) {
        final route = _coreRoutes[index];
        return RefreshIndicator(
          onRefresh: () => CustomerRefreshRegistry.refreshFor(route),
          child: _corePages[index],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isCoreRoute = _matchesAnyRoute(location, _coreRoutes);
    final nonCoreBody = RefreshIndicator(
      onRefresh: () => CustomerRefreshRegistry.refreshFor(location),
      child: widget.child,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: SvgPicture.asset(
          'assets/images/logo.svg',
          height: 38,
          fit: BoxFit.contain,
        ),
        actions: [
          if (location != '/store/cart')
            // Cart icon with badge
            BlocBuilder<CartCubit, CartState>(
              builder: (context, cartState) {
                return Stack(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/store/cart'),
                      icon: Icon(
                        Icons.shopping_cart_outlined,
                        color: AppColors.gray600,
                      ),
                    ),
                    if (cartState.itemCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${cartState.itemCount}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          isCoreRoute ? _coreSwipePage(location) : nonCoreBody,
          if (_routeLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.75),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  context,
                  Icons.home_outlined,
                  Icons.home,
                  'Home',
                  '/store',
                  location,
                ),
                _navItem(
                  context,
                  Icons.shopping_bag_outlined,
                  Icons.shopping_bag,
                  'Orders',
                  '/store/orders',
                  location,
                ),
                _navItem(
                  context,
                  Icons.favorite_outline,
                  Icons.favorite,
                  'Favorites',
                  '/store/favorites',
                  location,
                ),
                _navItem(
                  context,
                  Icons.person_outline,
                  Icons.person,
                  'Profile',
                  '/store/profile',
                  location,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    IconData activeIcon,
    String label,
    String path,
    String current,
  ) {
    final isActive =
        current == path || (path != '/store' && current.startsWith(path));
    final isHome = path == '/store' && current == '/store';
    final active = isActive || isHome;

    return InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 22,
              color: active ? AppColors.primary600 : AppColors.gray400,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? AppColors.primary600 : AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
