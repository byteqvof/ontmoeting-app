import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class ProfileAvatarFile extends Equatable {
  const ProfileAvatarFile({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  @override
  List<Object?> get props => [bytes, fileName, mimeType];
}
