import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'package:biznest_shop/core/biznest_core.dart';
import 'features/customer/navigation/app_router.dart';
import 'features/customer/cubit/cart_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://timkzcxmicogoukjliat.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRpbWt6Y3htaWNvZ291a2psaWF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA3MDY4NDUsImV4cCI6MjA4NjI4Mjg0NX0.4S2h3SqisoDyG75x2j6Vug8N2dl7wJkVfpPLQnlY0Tc',
    ),
  );

  runApp(const BizNestShopApp());
}

class BizNestShopApp extends StatefulWidget {
  const BizNestShopApp({super.key});

  @override
  State<BizNestShopApp> createState() => _BizNestShopAppState();
}

class _BizNestShopAppState extends State<BizNestShopApp> {
  late final AuthBloc _authBloc;
  late final CartCubit _cartCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc()..add(AuthCheckRequested());
    _cartCubit = CartCubit();
    _router = createRouter(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    _cartCubit.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _cartCubit),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            final userId = state.user['_id']?.toString();
            _cartCubit.bindToUser(userId);
            return;
          }

          if (state is AuthUnauthenticated) {
            _cartCubit.bindToUser(null);
          }
        },
        child: MaterialApp.router(
          title: 'BizNest Shop',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: _router,
        ),
      ),
    );
  }
}
