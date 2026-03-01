// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balances_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(netBalances)
final netBalancesProvider = NetBalancesFamily._();

final class NetBalancesProvider
    extends
        $FunctionalProvider<
          Map<String, double>,
          Map<String, double>,
          Map<String, double>
        >
    with $Provider<Map<String, double>> {
  NetBalancesProvider._({
    required NetBalancesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'netBalancesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$netBalancesHash();

  @override
  String toString() {
    return r'netBalancesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Map<String, double>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, double> create(Ref ref) {
    final argument = this.argument as String;
    return netBalances(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, double> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, double>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NetBalancesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$netBalancesHash() => r'cef4625489584630b8087f1ca122fb5fbf048187';

final class NetBalancesFamily extends $Family
    with $FunctionalFamilyOverride<Map<String, double>, String> {
  NetBalancesFamily._()
    : super(
        retry: null,
        name: r'netBalancesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  NetBalancesProvider call(String tripId) =>
      NetBalancesProvider._(argument: tripId, from: this);

  @override
  String toString() => r'netBalancesProvider';
}
