import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:freshcart_flutter/features/sync/data/connectivity/connectivity_adapter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_adapter_provider.g.dart';

/// Supplies the [ConnectivityAdapter] wrapping the device's connectivity plugin.
@Riverpod(keepAlive: true)
ConnectivityAdapter connectivityAdapter(Ref ref) =>
    ConnectivityAdapter(connectivity: Connectivity());
