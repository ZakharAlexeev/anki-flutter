import 'dart:convert';
import 'dart:typed_data';

/// A minimal, schema-less reader for Protocol Buffers (proto3) wire format.
///
/// Anki's newer collection format (schema v18+) stores notetype/deck/
/// deck-config definitions as serialized protobuf messages in `blob`
/// columns instead of the old JSON columns on `col`. Pulling in the full
/// `protobuf` package + codegen toolchain (protoc) just to read a handful
/// of scalar fields out of small config blobs is disproportionate, so this
/// walks the wire format directly: enough to read varints, fixed32
/// (float), and length-delimited fields (strings/bytes/packed-repeated/
/// sub-messages) by field number - see Anki's `proto/anki/*.proto` sources
/// (ankitects/anki on GitHub) for the field numbers used at each call site.
class ProtoMessage {
  ProtoMessage(this._fields);

  factory ProtoMessage.parse(Uint8List bytes) {
    final fields = <int, List<_RawField>>{};
    var pos = 0;

    int readVarint() {
      var result = 0;
      var shift = 0;
      while (true) {
        final b = bytes[pos++];
        result |= (b & 0x7F) << shift;
        if (b & 0x80 == 0) break;
        shift += 7;
      }
      return result;
    }

    while (pos < bytes.length) {
      final tag = readVarint();
      final fieldNumber = tag >> 3;
      final wireType = tag & 0x7;
      switch (wireType) {
        case 0: // varint
          fields.putIfAbsent(fieldNumber, () => []).add(_RawField.varint(readVarint()));
          break;
        case 1: // fixed64
          fields.putIfAbsent(fieldNumber, () => []).add(_RawField.bytes(bytes.sublist(pos, pos + 8)));
          pos += 8;
          break;
        case 2: // length-delimited
          final len = readVarint();
          fields.putIfAbsent(fieldNumber, () => []).add(_RawField.bytes(bytes.sublist(pos, pos + len)));
          pos += len;
          break;
        case 5: // fixed32
          fields.putIfAbsent(fieldNumber, () => []).add(_RawField.bytes(bytes.sublist(pos, pos + 4)));
          pos += 4;
          break;
        default:
          throw FormatException('Unsupported protobuf wire type $wireType (field $fieldNumber)');
      }
    }
    return ProtoMessage(fields);
  }

  final Map<int, List<_RawField>> _fields;

  bool has(int fieldNumber) => _fields.containsKey(fieldNumber);

  /// The last occurrence of an int/bool/enum-typed field (proto3 semantics:
  /// later occurrences override earlier ones).
  int? getInt(int fieldNumber) => _fields[fieldNumber]?.last.varint;

  bool getBool(int fieldNumber, {bool orElse = false}) => (getInt(fieldNumber) ?? (orElse ? 1 : 0)) != 0;

  String getString(int fieldNumber, {String orElse = ''}) {
    final raw = _fields[fieldNumber]?.last.bytes;
    return raw == null ? orElse : utf8.decode(raw);
  }

  /// A nested/embedded message field.
  ProtoMessage? getMessage(int fieldNumber) {
    final raw = _fields[fieldNumber]?.last.bytes;
    return raw == null ? null : ProtoMessage.parse(raw);
  }

  /// A single (non-repeated) `float` field (wire type 5 / fixed32).
  double? getFloat32(int fieldNumber) {
    final raw = _fields[fieldNumber]?.last.bytes;
    return raw == null ? null : ByteData.sublistView(raw).getFloat32(0, Endian.little);
  }

  /// `repeated float` fields are packed by default in proto3: one
  /// length-delimited field containing consecutive little-endian float32s.
  List<double> getPackedFloats(int fieldNumber) {
    final raw = _fields[fieldNumber]?.last.bytes;
    if (raw == null) return const [];
    final view = ByteData.sublistView(raw);
    return [for (var i = 0; i + 4 <= raw.length; i += 4) view.getFloat32(i, Endian.little)];
  }
}

class _RawField {
  _RawField.varint(this.varint) : bytes = null;
  _RawField.bytes(this.bytes) : varint = null;

  final int? varint;
  final Uint8List? bytes;
}
