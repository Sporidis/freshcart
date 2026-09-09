/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:serverpod/serverpod.dart' as _i1;

/// Which platform a registered device runs.
///
/// Kept because the delivery story differs per platform — notably that EU iOS
/// PWA installs cannot receive web push at all.
enum DevicePlatform implements _i1.SerializableModel {
  android,
  ios,
  web;

  static DevicePlatform fromJson(String name) {
    switch (name) {
      case 'android':
        return DevicePlatform.android;
      case 'ios':
        return DevicePlatform.ios;
      case 'web':
        return DevicePlatform.web;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "DevicePlatform"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
