import 'dart:convert';
import 'dart:typed_data';

import 'package:anki_flutter/data/import/proto_reader.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-rolled protobuf encoder, used only to build fixture bytes for the
/// tests below - mirrors the wire format proto_reader.dart decodes (see
/// Anki's `proto/anki/*.proto` sources for the real message shapes this
/// stands in for).
class _Writer {
  final _bytes = BytesBuilder();

  void _varint(int value) {
    var v = value;
    while (true) {
      if (v < 0x80) {
        _bytes.addByte(v);
        break;
      }
      _bytes.addByte((v & 0x7F) | 0x80);
      v >>= 7;
    }
  }

  void varintField(int fieldNumber, int value) {
    _varint((fieldNumber << 3) | 0);
    _varint(value);
  }

  void float32Field(int fieldNumber, double value) {
    _varint((fieldNumber << 3) | 5);
    final bd = ByteData(4)..setFloat32(0, value, Endian.little);
    _bytes.add(bd.buffer.asUint8List());
  }

  void stringField(int fieldNumber, String value) {
    final encoded = utf8.encode(value);
    _varint((fieldNumber << 3) | 2);
    _varint(encoded.length);
    _bytes.add(encoded);
  }

  void packedFloatsField(int fieldNumber, List<double> values) {
    _varint((fieldNumber << 3) | 2);
    _varint(values.length * 4);
    for (final v in values) {
      final bd = ByteData(4)..setFloat32(0, v, Endian.little);
      _bytes.add(bd.buffer.asUint8List());
    }
  }

  void messageField(int fieldNumber, Uint8List submessage) {
    _varint((fieldNumber << 3) | 2);
    _varint(submessage.length);
    _bytes.add(submessage);
  }

  Uint8List toBytes() => _bytes.toBytes();
}

void main() {
  test('reads varint, float32, string and packed-float fields by field number', () {
    final writer = _Writer()
      ..varintField(9, 20)
      ..float32Field(11, 2.5)
      ..stringField(3, 'Basic')
      ..packedFloatsField(1, [1.0, 10.0, 30.0]);

    final msg = ProtoMessage.parse(writer.toBytes());

    expect(msg.getInt(9), 20);
    expect(msg.getFloat32(11), closeTo(2.5, 0.0001));
    expect(msg.getString(3), 'Basic');
    expect(msg.getPackedFloats(1), [1.0, 10.0, 30.0]);
    expect(msg.has(9), isTrue);
    expect(msg.has(99), isFalse);
  });

  test('missing fields fall back to null/empty rather than throwing', () {
    final msg = ProtoMessage.parse(Uint8List(0));
    expect(msg.getInt(1), isNull);
    expect(msg.getFloat32(1), isNull);
    expect(msg.getString(1), '');
    expect(msg.getPackedFloats(1), isEmpty);
    expect(msg.getMessage(1), isNull);
  });

  test('reads a nested/embedded message, matching Deck.KindContainer -> Normal.config_id', () {
    final normal = _Writer()..varintField(1, 42); // Normal.config_id = 42
    final container = _Writer()..messageField(1, normal.toBytes()); // oneof kind = normal

    final kind = ProtoMessage.parse(container.toBytes());
    expect(kind.has(1), isTrue);
    expect(kind.has(2), isFalse); // not the "filtered" branch
    expect(kind.getMessage(1)!.getInt(1), 42);
  });

  test('later occurrences of a field win (proto3 last-one-wins semantics)', () {
    final writer = _Writer()
      ..varintField(5, 1)
      ..varintField(5, 2);
    expect(ProtoMessage.parse(writer.toBytes()).getInt(5), 2);
  });
}
