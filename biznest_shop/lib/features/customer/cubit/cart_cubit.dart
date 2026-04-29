import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:biznest_shop/core/biznest_core.dart';

// ==================== CART ITEM MODEL ====================
class CartItem extends Equatable {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? image;
  final String? businessId;
  final String? businessName;

  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.image,
    this.businessId,
    this.businessName,
  });

  CartItem copyWith({int? quantity}) => CartItem(
    productId: productId,
    name: name,
    price: price,
    quantity: quantity ?? this.quantity,
    image: image,
    businessId: businessId,
    businessName: businessName,
  );

  double get total => price * quantity;

  @override
  List<Object?> get props => [
    productId,
    name,
    price,
    quantity,
    image,
    businessId,
    businessName,
  ];
}

// ==================== CART STATE ====================
class CartState extends Equatable {
  final List<CartItem> items;
  final List<CartItem> savedForLater;

  const CartState({this.items = const [], this.savedForLater = const []});

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
  double get total => items.fold(0.0, (sum, i) => sum + i.total);
  bool isInCart(String productId) => items.any((i) => i.productId == productId);
  int getQuantity(String productId) {
    final item = items.where((i) => i.productId == productId).firstOrNull;
    return item?.quantity ?? 0;
  }

  CartState copyWith({List<CartItem>? items, List<CartItem>? savedForLater}) =>
      CartState(
        items: items ?? this.items,
        savedForLater: savedForLater ?? this.savedForLater,
      );

  @override
  List<Object?> get props => [items, savedForLater];
}

// ==================== CART CUBIT ====================
class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  String? _activeUserId;
  final Map<String, CartState> _cartByUserId = {};

  void bindToUser(String? userId) {
    final normalizedUserId = userId?.trim();
    final nextUserId = (normalizedUserId == null || normalizedUserId.isEmpty)
        ? null
        : normalizedUserId;

    if (_activeUserId == nextUserId) return;

    if (_activeUserId != null) {
      _cartByUserId[_activeUserId!] = state;
    }

    _activeUserId = nextUserId;

    if (_activeUserId == null) {
      emit(const CartState());
      return;
    }

    emit(_cartByUserId[_activeUserId!] ?? const CartState());
  }

  void addToCart(
    Map<String, dynamic> product, {
    int quantity = 1,
    String? businessId,
    String? businessName,
  }) {
    final id = product['_id'] as String;
    final existing = state.items.where((i) => i.productId == id).firstOrNull;

    if (existing != null) {
      final updated = state.items.map((i) {
        if (i.productId == id) {
          return i.copyWith(quantity: i.quantity + quantity);
        }
        return i;
      }).toList();
      emit(state.copyWith(items: updated));
    } else {
      // Handle both sellingPrice and price field names, prefer sellingPrice for backend API
      final price = product['sellingPrice'] ?? product['price'] ?? 0;
      final image = resolveProductImageUrl(product);

      final item = CartItem(
        productId: id,
        name: product['name'] ?? '',
        price: (price).toDouble(),
        quantity: quantity,
        image: image,
        businessId: businessId ?? product['businessId'],
        businessName: businessName,
      );
      emit(state.copyWith(items: [...state.items, item]));
    }
  }

  void removeFromCart(String productId) {
    emit(
      state.copyWith(
        items: state.items.where((i) => i.productId != productId).toList(),
      ),
    );
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final updated = state.items.map((i) {
      if (i.productId == productId) return i.copyWith(quantity: quantity);
      return i;
    }).toList();
    emit(state.copyWith(items: updated));
  }

  void saveForLater(String productId) {
    final item = state.items.where((i) => i.productId == productId).firstOrNull;
    if (item == null) return;
    emit(
      state.copyWith(
        items: state.items.where((i) => i.productId != productId).toList(),
        savedForLater: [...state.savedForLater, item],
      ),
    );
  }

  void moveToCart(String productId) {
    final item = state.savedForLater
        .where((i) => i.productId == productId)
        .firstOrNull;
    if (item == null) return;
    emit(
      state.copyWith(
        savedForLater: state.savedForLater
            .where((i) => i.productId != productId)
            .toList(),
        items: [...state.items, item],
      ),
    );
  }

  void removeFromSaved(String productId) {
    emit(
      state.copyWith(
        savedForLater: state.savedForLater
            .where((i) => i.productId != productId)
            .toList(),
      ),
    );
  }

  void addItemsForReorder(List<dynamic> orderItems) {
    final newItems = <CartItem>[];
    for (final item in orderItems) {
      final id = (item['product']?['_id'] ?? item['productId'] ?? '')
          .toString();
      if (id.isEmpty) continue;
      final existing = state.items.where((i) => i.productId == id).firstOrNull;
      if (existing != null) continue;

      // Use sellingPrice from product or price from order item, with fallback
      final price =
          item['product']?['sellingPrice'] ??
          item['price'] ??
          item['product']?['price'] ??
          0;
      final image = resolveOrderItemImageUrl(
        Map<String, dynamic>.from(item as Map),
      );

      newItems.add(
        CartItem(
          productId: id,
          name: item['product']?['name'] ?? item['name'] ?? '',
          price: (price).toDouble(),
          quantity: item['quantity'] ?? 1,
          image: image,
          businessId: item['businessId'],
        ),
      );
    }
    if (newItems.isNotEmpty) {
      emit(state.copyWith(items: [...state.items, ...newItems]));
    }
  }

  void clearCart() {
    emit(state.copyWith(items: [], savedForLater: []));
  }
}
