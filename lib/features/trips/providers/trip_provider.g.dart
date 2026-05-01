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

@ProviderFor(shoppingItems)
final shoppingItemsProvider = ShoppingItemsFamily._();

final class ShoppingItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ShoppingItem>>,
          List<ShoppingItem>,
          Stream<List<ShoppingItem>>
        >
    with
        $FutureModifier<List<ShoppingItem>>,
        $StreamProvider<List<ShoppingItem>> {
  ShoppingItemsProvider._({
    required ShoppingItemsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'shoppingItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shoppingItemsHash();

  @override
  String toString() {
    return r'shoppingItemsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ShoppingItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ShoppingItem>> create(Ref ref) {
    final argument = this.argument as String;
    return shoppingItems(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ShoppingItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shoppingItemsHash() => r'0413268eba8134c77263e31d417fb965bfc2cee4';

final class ShoppingItemsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ShoppingItem>>, String> {
  ShoppingItemsFamily._()
    : super(
        retry: null,
        name: r'shoppingItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ShoppingItemsProvider call(String tripId) =>
      ShoppingItemsProvider._(argument: tripId, from: this);

  @override
  String toString() => r'shoppingItemsProvider';
}

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

String _$userTripsHash() => r'ab82c0d32ae44bb91dd9c8d0d92236e8de9d4592';

@ProviderFor(joinTrip)
final joinTripProvider = JoinTripFamily._();

final class JoinTripProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  JoinTripProvider._({
    required JoinTripFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'joinTripProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$joinTripHash();

  @override
  String toString() {
    return r'joinTripProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return joinTrip(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is JoinTripProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$joinTripHash() => r'bcb6275f2f91953d46f7172294eb879a3abb54d9';

final class JoinTripFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  JoinTripFamily._()
    : super(
        retry: null,
        name: r'joinTripProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  JoinTripProvider call(String inviteCode) =>
      JoinTripProvider._(argument: inviteCode, from: this);

  @override
  String toString() => r'joinTripProvider';
}

@ProviderFor(leaveTrip)
final leaveTripProvider = LeaveTripFamily._();

final class LeaveTripProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  LeaveTripProvider._({
    required LeaveTripFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'leaveTripProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$leaveTripHash();

  @override
  String toString() {
    return r'leaveTripProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return leaveTrip(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LeaveTripProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$leaveTripHash() => r'1f14c5734361e84cca2860af7d0c25bcbd8dc744';

final class LeaveTripFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  LeaveTripFamily._()
    : super(
        retry: null,
        name: r'leaveTripProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LeaveTripProvider call(String tripId) =>
      LeaveTripProvider._(argument: tripId, from: this);

  @override
  String toString() => r'leaveTripProvider';
}

@ProviderFor(createExpense)
final createExpenseProvider = CreateExpenseFamily._();

final class CreateExpenseProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  CreateExpenseProvider._({
    required CreateExpenseFamily super.from,
    required ({
      String tripId,
      String description,
      double amount,
      List<String> participantUserIds,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'createExpenseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$createExpenseHash();

  @override
  String toString() {
    return r'createExpenseProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String tripId,
              String description,
              double amount,
              List<String> participantUserIds,
            });
    return createExpense(
      ref,
      tripId: argument.tripId,
      description: argument.description,
      amount: argument.amount,
      participantUserIds: argument.participantUserIds,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CreateExpenseProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$createExpenseHash() => r'0bad5038b40dca8cdb5eea73ad8885247b3bb6e4';

final class CreateExpenseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<void>,
          ({
            String tripId,
            String description,
            double amount,
            List<String> participantUserIds,
          })
        > {
  CreateExpenseFamily._()
    : super(
        retry: null,
        name: r'createExpenseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CreateExpenseProvider call({
    required String tripId,
    required String description,
    required double amount,
    required List<String> participantUserIds,
  }) => CreateExpenseProvider._(
    argument: (
      tripId: tripId,
      description: description,
      amount: amount,
      participantUserIds: participantUserIds,
    ),
    from: this,
  );

  @override
  String toString() => r'createExpenseProvider';
}

@ProviderFor(updateExpenseAction)
final updateExpenseActionProvider = UpdateExpenseActionFamily._();

final class UpdateExpenseActionProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  UpdateExpenseActionProvider._({
    required UpdateExpenseActionFamily super.from,
    required (String, Expense) super.argument,
  }) : super(
         retry: null,
         name: r'updateExpenseActionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$updateExpenseActionHash();

  @override
  String toString() {
    return r'updateExpenseActionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as (String, Expense);
    return updateExpenseAction(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is UpdateExpenseActionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$updateExpenseActionHash() =>
    r'0a671e7b418fe6e71e6822da8efb5d5535728e17';

final class UpdateExpenseActionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, (String, Expense)> {
  UpdateExpenseActionFamily._()
    : super(
        retry: null,
        name: r'updateExpenseActionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UpdateExpenseActionProvider call(String tripId, Expense expense) =>
      UpdateExpenseActionProvider._(argument: (tripId, expense), from: this);

  @override
  String toString() => r'updateExpenseActionProvider';
}

@ProviderFor(deleteExpenseAction)
final deleteExpenseActionProvider = DeleteExpenseActionFamily._();

final class DeleteExpenseActionProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  DeleteExpenseActionProvider._({
    required DeleteExpenseActionFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'deleteExpenseActionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$deleteExpenseActionHash();

  @override
  String toString() {
    return r'deleteExpenseActionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as (String, String);
    return deleteExpenseAction(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is DeleteExpenseActionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$deleteExpenseActionHash() =>
    r'd854e62080a86c256beea86d5bc2faa184d3eef6';

final class DeleteExpenseActionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, (String, String)> {
  DeleteExpenseActionFamily._()
    : super(
        retry: null,
        name: r'deleteExpenseActionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DeleteExpenseActionProvider call(String tripId, String expenseId) =>
      DeleteExpenseActionProvider._(argument: (tripId, expenseId), from: this);

  @override
  String toString() => r'deleteExpenseActionProvider';
}

@ProviderFor(toggleExpenseLockAction)
final toggleExpenseLockActionProvider = ToggleExpenseLockActionFamily._();

final class ToggleExpenseLockActionProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  ToggleExpenseLockActionProvider._({
    required ToggleExpenseLockActionFamily super.from,
    required (String, bool) super.argument,
  }) : super(
         retry: null,
         name: r'toggleExpenseLockActionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$toggleExpenseLockActionHash();

  @override
  String toString() {
    return r'toggleExpenseLockActionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as (String, bool);
    return toggleExpenseLockAction(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ToggleExpenseLockActionProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$toggleExpenseLockActionHash() =>
    r'97d1032f726c752f381bf4032c64c88053d5a6cd';

final class ToggleExpenseLockActionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, (String, bool)> {
  ToggleExpenseLockActionFamily._()
    : super(
        retry: null,
        name: r'toggleExpenseLockActionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ToggleExpenseLockActionProvider call(String tripId, bool isLocked) =>
      ToggleExpenseLockActionProvider._(
        argument: (tripId, isLocked),
        from: this,
      );

  @override
  String toString() => r'toggleExpenseLockActionProvider';
}

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

@ProviderFor(expenses)
final expensesProvider = ExpensesFamily._();

final class ExpensesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Expense>>,
          List<Expense>,
          Stream<List<Expense>>
        >
    with $FutureModifier<List<Expense>>, $StreamProvider<List<Expense>> {
  ExpensesProvider._({
    required ExpensesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'expensesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$expensesHash();

  @override
  String toString() {
    return r'expensesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Expense>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Expense>> create(Ref ref) {
    final argument = this.argument as String;
    return expenses(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ExpensesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$expensesHash() => r'3de42a1090d47fcb44fda7538369e4f6b41ad217';

final class ExpensesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Expense>>, String> {
  ExpensesFamily._()
    : super(
        retry: null,
        name: r'expensesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ExpensesProvider call(String tripId) =>
      ExpensesProvider._(argument: tripId, from: this);

  @override
  String toString() => r'expensesProvider';
}
