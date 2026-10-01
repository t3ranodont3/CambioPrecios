class Product {
  final String id; // maybe DCI or code
  final String name;
  final String brand;
  // additional fields as necessary

  Product({required this.id, required this.name, required this.brand});

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        brand: map['brand'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'brand': brand,
      };
}
