// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_dtos.freezed.dart';
part 'category_dtos.g.dart';

@freezed
class CategoryRequest with _$CategoryRequest {
  const factory CategoryRequest({
    required String nom,
    required String icone,
    required String couleur,
  }) = _CategoryRequest;

  factory CategoryRequest.fromJson(Map<String, dynamic> json) =>
      _$CategoryRequestFromJson(json);
}

@freezed
class CategoryResponse with _$CategoryResponse {
  const factory CategoryResponse({
    required String id,
    required String nom,
    required String icone,
    required String couleur,
    required bool isSystem,
    String? updatedAt,
  }) = _CategoryResponse;

  factory CategoryResponse.fromJson(Map<String, dynamic> json) =>
      _$CategoryResponseFromJson(json);
}
