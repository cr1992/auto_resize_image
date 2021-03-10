import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

///created by Ray on 2021.3.10
///根据[scale]或者[maxBytes]来缩放图片，以减少内存占用
///如果[scale]不为空则按[scale]比例来缩放图片宽高
///否则按[maxBytes]最大值处理。默认500KB
class AutoResizeImage extends ImageProvider<_SizeAwareCacheKey> {
  const AutoResizeImage(
    this.imageProvider, {
    this.scale,
    this.maxBytes = 500 << 10,
  }) : assert(scale != null || maxBytes != null);

  /// The [ImageProvider] that this class wraps.
  final ImageProvider imageProvider;

  final int maxBytes;

  final double scale;

  @override
  ImageStreamCompleter load(_SizeAwareCacheKey key, DecoderCallback decode) {
    final DecoderCallback decodeResize = (Uint8List bytes,
        {int cacheWidth, int cacheHeight, bool allowUpscaling}) {
      assert(
          cacheWidth == null && cacheHeight == null && allowUpscaling == null,
          'ResizeImage cannot be composed with another ImageProvider that applies '
          'cacheWidth, cacheHeight, or allowUpscaling.');
      return instantiateImageCodec(
        bytes,
        scale: scale,
        maxBytes: maxBytes,
      );
    };
    final ImageStreamCompleter completer =
        imageProvider.load(key.providerCacheKey, decodeResize);
    if (!kReleaseMode) {
      completer.debugLabel =
          '${completer.debugLabel} - Resized(scale: ${key.scale} maxBytes${key.maxBytes})';
    }
    return completer;
  }

  @override
  Future<_SizeAwareCacheKey> obtainKey(ImageConfiguration configuration) {
    Completer<_SizeAwareCacheKey> completer;
    // If the imageProvider.obtainKey future is synchronous, then we will be able to fill in result with
    // a value before completer is initialized below.
    SynchronousFuture<_SizeAwareCacheKey> result;
    imageProvider.obtainKey(configuration).then((Object key) {
      if (completer == null) {
        // This future has completed synchronously (completer was never assigned),
        // so we can directly create the synchronous result to return.
        result = SynchronousFuture<_SizeAwareCacheKey>(
            _SizeAwareCacheKey(key, scale, maxBytes));
      } else {
        // This future did not synchronously complete.
        completer.complete(_SizeAwareCacheKey(key, scale, maxBytes));
      }
    });
    if (result != null) {
      return result;
    }
    // If the code reaches here, it means the imageProvider.obtainKey was not
    // completed sync, so we initialize the completer for completion later.
    completer = Completer<_SizeAwareCacheKey>();
    return completer.future;
  }

  Future<Codec> instantiateImageCodec(
    Uint8List list, {
    double scale,
    int maxBytes,
  }) async {
    final ImmutableBuffer buffer = await ImmutableBuffer.fromUint8List(list);
    final ImageDescriptor descriptor = await ImageDescriptor.encoded(buffer);
    int targetWidth = descriptor.width, targetHeight = descriptor.height;
    if (scale != null) {
      targetWidth ~/= scale;
      targetHeight ~/= scale;
    } else {
      while (targetWidth * targetHeight * 4 > maxBytes) {
        targetWidth >>= 1;
        targetHeight >>= 1;
      }
    }
    if (kDebugMode) {
      print('origin size: ${descriptor.width}*${descriptor.height} '
          'scaled size: $targetWidth*$targetHeight'
          ' scale : ${descriptor.width ~/ targetWidth}');
    }
    return descriptor.instantiateCodec(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
  }
}

@immutable
class _SizeAwareCacheKey {
  const _SizeAwareCacheKey(
    this.providerCacheKey,
    this.scale,
    this.maxBytes,
  );

  final Object providerCacheKey;

  final int maxBytes;

  final double scale;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is _SizeAwareCacheKey &&
        other.providerCacheKey == providerCacheKey &&
        other.maxBytes == maxBytes &&
        other.scale == scale;
  }

  @override
  int get hashCode => hashValues(providerCacheKey, maxBytes, scale);
}
