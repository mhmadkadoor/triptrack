// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(aiService)
final aiServiceProvider = AiServiceProvider._();

final class AiServiceProvider
    extends $FunctionalProvider<AiService, AiService, AiService>
    with $Provider<AiService> {
  AiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiServiceHash();

  @$internal
  @override
  $ProviderElement<AiService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AiService create(Ref ref) {
    return aiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiService>(value),
    );
  }
}

String _$aiServiceHash() => r'6a2ba9f7761a3cc3d1eab0c9ea16e7b6550b2270';
