class WarehouseProduct {
  final String id;
  final String sku;
  final String name;
  final String category;
  final String description;
  final String location;
  int quantity;
  final bool isDeleted;

  WarehouseProduct({
    required this.id,
    required this.sku,
    required this.name,
    this.category = '',
    this.description = '',
    this.location = '',
    this.quantity = 0,
    this.isDeleted = false,
  });

  factory WarehouseProduct.fromJson(Map<String, dynamic> json) {
    return WarehouseProduct(
      id: json['id']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      isDeleted: json['is_deleted'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'category': category,
      'description': description,
      'location': location,
      'quantity': quantity,
      'is_deleted': isDeleted,
    };
  }

  // Create a copy with updated fields
  WarehouseProduct copyWith({
    String? id,
    String? sku,
    String? name,
    String? category,
    String? description,
    String? location,
    int? quantity,
    bool? isDeleted,
  }) {
    return WarehouseProduct(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      location: location ?? this.location,
      quantity: quantity ?? this.quantity,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

class ProductReservation {
  final String id;
  final String productId;
  final String userId;
  final DateTime reservedAt;
  final DateTime? returnDate;
  final String productName;
  final String productSku;

  ProductReservation({
    required this.id,
    required this.productId,
    required this.userId,
    required this.reservedAt,
    this.returnDate,
    required this.productName,
    required this.productSku,
  });

  factory ProductReservation.fromJson(Map<String, dynamic> json) {
    return ProductReservation(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      reservedAt: DateTime.tryParse(json['reserved_at'] ?? '') ?? DateTime.now(),
      returnDate: json['return_date'] != null ? DateTime.tryParse(json['return_date']) : null,
      productName: json['product_name']?.toString() ?? '',
      productSku: json['product_sku']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'user_id': userId,
      'reserved_at': reservedAt.toIso8601String(),
      'return_date': returnDate?.toIso8601String(),
      'product_name': productName,
      'product_sku': productSku,
    };
  }

  bool get isReturned => returnDate != null;
}