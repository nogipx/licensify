// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

abstract interface class LicenseMapper {
  static LicenseDto toDto(License license) => LicenseDto(
    id: license.id,
    appId: license.appId,
    expirationDate: license.expirationDate,
    createdAt: license.createdAt,
    signature: license.signature,
    type: license.type.name,
    features: license.features,
    metadata: license.metadata,
  );

  static License toDomain(LicenseDto dto) => License(
    id: dto.id,
    appId: dto.appId,
    expirationDate: dto.expirationDate,
    createdAt: dto.createdAt,
    signature: dto.signature,
    type: LicenseType(dto.type),
    features: dto.features,
    metadata: dto.metadata,
  );
}
