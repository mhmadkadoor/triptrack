// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balances_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(savedSettlements)
final savedSettlementsProvider = SavedSettlementsFamily._();

final class SavedSettlementsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Settlement>>,
          List<Settlement>,
          Stream<List<Settlement>>
        >
    with $FutureModifier<List<Settlement>>, $StreamProvider<List<Settlement>> {
  SavedSettlementsProvider._({
    required SavedSettlementsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'savedSettlementsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$savedSettlementsHash();

  @override
  String toString() {
    return r'savedSettlementsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Settlement>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Settlement>> create(Ref ref) {
    final argument = this.argument as String;
    return savedSettlements(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SavedSettlementsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$savedSettlementsHash() => r'da9d5ee21dfadde0ceb7c47639c91e8c40b692f6';

final class SavedSettlementsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Settlement>>, String> {
  SavedSettlementsFamily._()
    : super(
        retry: null,
        name: r'savedSettlementsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SavedSettlementsProvider call(String tripId) =>
      SavedSettlementsProvider._(argument: tripId, from: this);

  @override
  String toString() => r'savedSettlementsProvider';
}

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
