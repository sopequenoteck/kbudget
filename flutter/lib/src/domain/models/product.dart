import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String nom,
    String? description,
    String? icone,
    String? imageUrl,
    required double prixAchat,
    required double prixVente,
    required int stock,
    @Default(0) int totalVendu,
    @Default(true) bool actif,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
