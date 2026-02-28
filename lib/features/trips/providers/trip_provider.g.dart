// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tripRepository)
final tripRepositoryProvider = TripRepositoryProvider._();

final class TripRepositoryProvider
    extends $FunctionalProvider<TripRepository, TripRepository, TripRepository>
    with $Provider<TripRepository> {
  TripRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripRepositoryHash();

  @$internal
  @override
  $ProviderElement<TripRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TripRepository create(Ref ref) {
    return tripRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripRepository>(value),
    );
  }
}

String _$tripRepositoryHash() => r'6017fb2922b5b91687e8de329d706a17c8b8b23f';

@ProviderFor(userTrips)
final userTripsProvider = UserTripsProvider._();

final class UserTripsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Trip>>,
          List<Trip>,
          Stream<List<Trip>>
        >
    with $FutureModifier<List<Trip>>, $StreamProvider<List<Trip>> {
  UserTripsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userTripsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userTripsHash();

  @$internal
  @override
  $StreamProviderElement<List<Trip>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Trip>> create(Ref ref) {
    return userTrips(ref);
  }
}

String _$userTripsHash() => r'1af06659dd40061511f4f0fcb24697d3121ae621';

@ProviderFor(trip)
final tripProvider = TripFamily._();

final class TripProvider
    extends $FunctionalProvider<AsyncValue<Trip>, Trip, Stream<Trip>>
    with $FutureModifier<Trip>, $StreamProvider<Trip> {
  TripProvider._({
    required TripFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tripProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripHash();

  @override
  String toString() {
    return r'tripProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Trip> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Trip> create(Ref ref) {
    final argument = this.argument as String;
    return trip(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TripProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripHash() => r'4b236158809504ffc1f2f0f696a23d4dee868e08';

final class TripFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Trip>, String> {
  TripFamily._()
    : super(
        retry: null,
        name: r'tripProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TripProvider call(String id) => TripProvider._(argument: id, from: this);

  @override
  String toString() => r'tripProvider';
}

@ProviderFor(tripMembers)
final tripMembersProvider = TripMembersFamily._();

final class TripMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TripMember>>,
          List<TripMember>,
          Stream<List<TripMember>>
        >
    with $FutureModifier<List<TripMember>>, $StreamProvider<List<TripMember>> {
  TripMembersProvider._({
    required TripMembersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tripMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripMembersHash();

  @override
  String toString() {
    return r'tripMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TripMember>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TripMember>> create(Ref ref) {
    final argument = this.argument as String;
    return tripMembers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TripMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripMembersHash() => r'631d2a4ddf7f14aee991a98f1cf1c869b698a7c7';

final class TripMembersFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<TripMember>>, String> {
  TripMembersFamily._()
    : super(
        retry: null,
        name: r'tripMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TripMembersProvider call(String tripId) =>
      TripMembersProvider._(argument: tripId, from: this);

  @override
  String toString() => r'tripMembersProvider';
}
