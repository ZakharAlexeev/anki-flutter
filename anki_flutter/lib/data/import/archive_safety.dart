import 'dart:typed_data';

class ImportException implements Exception {
  final String message;
  ImportException(this.message);

  @override
  String toString() => message;
}

/// Conservative limits for archives processed fully in memory.
///
/// They are deliberately explicit: rejecting an unusually large collection
/// with a useful message is safer than letting the OS kill the app midway
/// through an import and leaving the user unsure what was written.
const int maxApkgBytes = 256 * 1024 * 1024;
const int maxArchiveEntries = 100000;
const int maxArchiveExpandedBytes = 1024 * 1024 * 1024;
const int maxSingleArchiveEntryBytes = 512 * 1024 * 1024;
const int maxSingleMediaBytes = 128 * 1024 * 1024;
const int maxExpansionRatio = 200;

/// Reads the ZIP central directory before [archive] is allowed to inflate any
/// entries. This blocks ordinary ZIP bombs while the importer still uses the
/// in-memory API from package:archive.
void validateZipEnvelope(Uint8List bytes) {
  if (bytes.length > maxApkgBytes) {
    throw ImportException('Архив больше 256 МБ. Разделите коллекцию на несколько файлов.');
  }
  if (bytes.length < 22) throw ImportException('Файл не является корректным ZIP-архивом.');

  final data = ByteData.sublistView(bytes);
  const eocdSignature = 0x06054b50;
  const centralSignature = 0x02014b50;
  final searchStart = bytes.length - 22;
  final searchEnd = bytes.length > 65557 ? bytes.length - 65557 : 0;
  int? eocd;
  for (var i = searchStart; i >= searchEnd; i--) {
    if (data.getUint32(i, Endian.little) == eocdSignature) {
      eocd = i;
      break;
    }
  }
  if (eocd == null) throw ImportException('Не найден каталог ZIP-архива.');

  final entryCount = data.getUint16(eocd + 10, Endian.little);
  final directorySize = data.getUint32(eocd + 12, Endian.little);
  final directoryOffset = data.getUint32(eocd + 16, Endian.little);
  if (entryCount == 0xffff || directorySize == 0xffffffff || directoryOffset == 0xffffffff) {
    throw ImportException('ZIP64 пока не поддерживается. Разделите коллекцию на несколько файлов.');
  }
  if (entryCount > maxArchiveEntries) {
    throw ImportException('В архиве слишком много файлов.');
  }
  if (directoryOffset + directorySize > eocd) {
    throw ImportException('Повреждён центральный каталог ZIP-архива.');
  }

  var offset = directoryOffset;
  var expandedTotal = 0;
  var compressedTotal = 0;
  for (var i = 0; i < entryCount; i++) {
    if (offset + 46 > bytes.length || data.getUint32(offset, Endian.little) != centralSignature) {
      throw ImportException('Повреждена запись центрального каталога ZIP.');
    }
    final compressed = data.getUint32(offset + 20, Endian.little);
    final expanded = data.getUint32(offset + 24, Endian.little);
    if (compressed == 0xffffffff || expanded == 0xffffffff) {
      throw ImportException('ZIP64 пока не поддерживается. Разделите коллекцию на несколько файлов.');
    }
    if (expanded > maxSingleArchiveEntryBytes) {
      throw ImportException('Один из файлов в архиве превышает безопасный лимит 512 МБ.');
    }
    expandedTotal += expanded;
    compressedTotal += compressed;
    if (expandedTotal > maxArchiveExpandedBytes) {
      throw ImportException('После распаковки архив превышает безопасный лимит 1 ГБ.');
    }

    final fileNameLength = data.getUint16(offset + 28, Endian.little);
    final extraLength = data.getUint16(offset + 30, Endian.little);
    final commentLength = data.getUint16(offset + 32, Endian.little);
    offset += 46 + fileNameLength + extraLength + commentLength;
  }

  if (compressedTotal > 0 && expandedTotal > compressedTotal * maxExpansionRatio) {
    throw ImportException('Архив имеет небезопасно высокий коэффициент распаковки.');
  }
}

/// Returns the declared Zstandard frame content size, or null when the frame
/// omits it. Anki's modern collection frames declare their size; refusing an
/// unknown-size frame prevents an unbounded native allocation.
int? zstdDeclaredContentSize(Uint8List bytes) {
  if (bytes.length < 6 ||
      bytes[0] != 0x28 ||
      bytes[1] != 0xb5 ||
      bytes[2] != 0x2f ||
      bytes[3] != 0xfd) {
    return null;
  }
  final descriptor = bytes[4];
  if ((descriptor & 0x08) != 0) return null; // reserved bit
  final singleSegment = (descriptor & 0x20) != 0;
  final sizeFlag = descriptor >> 6;
  final dictionaryFlag = descriptor & 0x03;
  var offset = 5;
  if (!singleSegment) offset++; // window descriptor
  offset += switch (dictionaryFlag) { 0 => 0, 1 => 1, 2 => 2, _ => 4 };
  final fieldSize = switch (sizeFlag) { 0 => singleSegment ? 1 : 0, 1 => 2, 2 => 4, _ => 8 };
  if (fieldSize == 0 || offset + fieldSize > bytes.length) return null;

  final data = ByteData.sublistView(bytes, offset, offset + fieldSize);
  final value = switch (fieldSize) {
    1 => data.getUint8(0),
    2 => data.getUint16(0, Endian.little) + 256,
    4 => data.getUint32(0, Endian.little),
    _ => data.getUint64(0, Endian.little),
  };
  return value;
}
