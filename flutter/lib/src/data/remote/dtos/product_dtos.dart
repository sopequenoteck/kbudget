import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_dtos.freezed.dart';
part 'product_dtos.g.dart';

@freezed
class RestockRequest with _$RestockRequest {
  const factory RestockRequest({
    required int quantity,
  }) = _RestockRequest;

  factory RestockRequest.fromJson(Map<String, dynamic> json) =>
      _$RestockRequestFromJson(json);
}

@freezed
class ProductRequest with _$ProductRequest {
  const factory ProductRequest({
    required String nom,
    String? description,
    String? icone,
    String? imageUrl,
    required double prixAchat,
    required double prixVente,
    required int stock,
  }) = _ProductRequest;

  factory ProductRequest.fromJson(Map<String, dynamic> json) =>
      _$ProductRequestFromJson(json);
}

@freezed
class ProductUpdateRequest with _$ProductUpdateRequest {
  const factory ProductUpdateRequest({
    required String nom,
    String? description,
    String? icone,
    String? imageUrl,
    required double prixAchat,
    required double prixVente,
    required int stock,
    required bool actif,
  }) = _ProductUpdateRequest;

  factory ProductUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$ProductUpdateRequestFromJson(json);
}

@freezed
class ProductResponse with _$ProductResponse {
  const factory ProductResponse({
    required String id,
    required String nom,
    String? description,
    String? icone,
    String? imageUrl,
    required double prixAchat,
    required double prixVente,
    required int stock,
    required int totalVendu,
    required bool actif,
    String? createdAt,
    String? updatedAt,
  }) = _ProductResponse;

  factory ProductResponse.fromJson(Map<String, dynamic> json) =>
      _$ProductResponseFromJson(json);
}
