import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

enum SourceLogoState { loaded, loading, failed }

/// Replaces online logos with a deterministic PNG, pending request or failure.
/// Tests never contact providers or depend on their current branding.
Future<void> withSourceLogos(
  SourceLogoState state,
  Future<void> Function() body,
) async {
  PaintingBinding.instance.imageCache.clear();
  PaintingBinding.instance.imageCache.clearLiveImages();
  final previous = debugNetworkImageHttpClientProvider;
  debugNetworkImageHttpClientProvider = () => _LogoClient(state);
  try {
    await body();
  } finally {
    debugNetworkImageHttpClientProvider = previous;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}

class _LogoClient extends Fake implements HttpClient {
  _LogoClient(this.state);

  final SourceLogoState state;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    switch (state) {
      case SourceLogoState.loaded:
        return _LogoRequest();
      case SourceLogoState.loading:
        return Completer<HttpClientRequest>().future;
      case SourceLogoState.failed:
        throw const SocketException('Logo unavailable in test');
    }
  }
}

class _LogoRequest extends Fake implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _LogoResponse();
}

class _LogoResponse extends Fake implements HttpClientResponse {
  // A synthetic 32 × 32 logo fixture, not a downloaded provider image.
  static final _bytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAMklEQVR4nO3OwQkAMAgAMWfojG7h8HYKpYUc3D8R0oudrJ4YAAAAAAAAAAAA4B+AtNkFsS2p7t+dx1IAAAAASUVORK5CYII=',
  );

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(_bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}
