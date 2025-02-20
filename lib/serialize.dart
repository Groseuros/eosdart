// ignore_for_file: unnecessary_null_comparison

import 'dart:typed_data';

import 'package:eos_dart/interfaces/rpc-interfaces.dart';
import 'package:eos_dart/numeric.dart';

/**
 * @module Serialize
 */
// copyright defined in eosjs/LICENSE.txt

import 'numeric.dart' as numeric;
import 'interfaces/rpc-interfaces.dart';
import 'dart:convert';

/// A field in an abi */
class Field {
  /// Field name */
  String? name;

  /// Type name in string form */
  String? typeName;

  /// Type of the field */
  Type? type;

  Field({this.name, this.type, this.typeName});
}

/// Options for serialize() and deserialize() */
class SerializerOptions {
  final bool bytesAsUint8List;
  const SerializerOptions(this.bytesAsUint8List);
}

/// State for serialize() and deserialize() */
class SerializerState {
  final SerializerOptions options;

  /// Have any binary extensions been skipped? */
  bool skippedBinaryExtension;

  SerializerState(
      {this.options = const SerializerOptions(false),
      this.skippedBinaryExtension = false});
}

/// A type in an abi */
class Type {
  /// Type name */
  String? name;

  /// Type name this is an alias of, if any */
  String? aliasOfName;

  /// Type this is an array of, if any */
  Type? arrayOf;

  /// Type this is an optional of, if any */
  Type? optionalOf;

  /// Marks binary extension fields */
  Type? extensionOf;

  /// Base name of this type, if this is a struct */
  String? baseName;

  /// Base of this type, if this is a struct */
  Type? base;

  /// Contained fields, if this is a struct */
  List<Field>? fields;

  //void serialize(SerialBuffer buffer, dynamic data, SerializerState state,bool allowExtensions);
  void Function(Type? self, SerialBuffer buffer, Object? data,
      {SerializerState? state, bool? allowExtensions})? serialize;

  /// Convert data in `buffer` from binary form */
  Object? Function(Type? self, SerialBuffer buffer,
      {SerializerState? state, bool? allowExtensions})? deserialize;

  Type(
      {this.name,
      this.aliasOfName,
      this.arrayOf,
      this.base,
      this.baseName,
      this.extensionOf,
      this.fields,
      this.optionalOf,
      this.serialize,
      this.deserialize});
}

/// Structural representation of a symbol */
class Symbol {
  /// Name of the symbol, not including precision */
  final String? name;

  /// Number of digits after the decimal point */
  final int? precision;

  Symbol({this.name, this.precision});
}

class Contract {
  final Map<String?, Type>? actions;
  final Map<String?, Type>? types;

  Contract({this.actions, this.types});
}

class Authorization {
  final String? actor;
  final String? permission;
  Authorization({this.actor, this.permission});
  factory Authorization.fromJson(Map json) {
    return Authorization(
      actor: json["actor"],
      permission: json["permission"],
    );
  }
  Object? operator [](String prop) {
    switch (prop) {
      case "actor":
        return actor;
      case "permission":
        return permission;
    }
    return "";
  }

  dynamic toJson() {
    return {"actor": actor, "permission": permission};
  }
}

/// Action with data in structured form */
class Action {
  final String? account;
  final String? name;
  final List<Authorization>? authorization;
  final dynamic data;
  Action({this.account, this.authorization, this.data, this.name});

  factory Action.fromJson(Map json) {
    return Action(
      account: json["account"],
      name: json["name"],
      data: json["data"],
      authorization: (json["authorization"] as List)
          .map((item) => Authorization.fromJson(item))
          .toList(),
    );
  }
}

/// Action with data in serialized hex form */
class SerializedAction {
  final String? account;
  final String? name;
  final List<Authorization>? authorization;
  final dynamic data;
  SerializedAction({this.account, this.authorization, this.data, this.name});
  Object? operator [](String prop) {
    switch (prop) {
      case "account":
        return account;
      case "name":
        return name;
      case "authorization":
        return authorization;
      case "data":
        return data;
    }
    return "";
  }

  dynamic toJson() {
    return {
      "account": account,
      "name": name,
      "authorization": authorization, //.map((item)=>json.en(item)).toList(),
      "data": data
    };
  }
}

/// Serialize and deserialize data */
class SerialBuffer {
  /// Amount of valid data in `array` */
  int? length;

  /// Data in serialized (binary) form */
  Uint8List? array;

  /// Current position while reading (deserializing) */
  int readPos = 0;

  /// @param __namedParameters
  ///    * `array`: `null` if serializing, or binary data to deserialize
  ///    * `textEncoder`: `TextEncoder` instance to use. Pass in `null` if running in a browser
  ///    * `textDecoder`: `TextDecider` instance to use. Pass in `null` if running in a browser

  SerialBuffer(this.array) {
    // array = array || new Uint8List(1024);
    length = array != null ? array!.length : 0;
    // textEncoder = textEncoder || new TextEncoder();
    // textDecoder = textDecoder || new TextDecoder('utf-8', { fatal: true });
  }

  /// Resize `array` if needed to have at least `size` bytes free */
  void reserve(int size) {
    if (length! + size <= array!.length) {
      return;
    }
    var l = array!.length;
    while (length! + size > l) {
      l = (l * 1.5).ceil();
    }
    var newArray = Uint8List.fromList(array!);
    // newArray.addAll(array);
    array = newArray;
  }

  /// Is there data available to read? */
  bool haveReadData() {
    return readPos < length!;
  }

  /// Restart reading from the beginning */
  void restartRead() {
    readPos = 0;
  }

  /// Return data with excess storage trimmed away */
  Uint8List asUint8List() {
    return Uint8List.view(array!.buffer, array!.offsetInBytes, length);
  }

  /// Append bytes */
  void pushArray(List<int> v) {
    // reserve(v.length);
    // var t = Uint8List.view(array.buffer,0,array.length + v.length);
    // t.replaceRange(array.length, array.length + v.length - 1, v);
    // array = t;
    var t = array!.toList();
    t.addAll(v);
    array = Uint8List.fromList(t);
    length = length! + v.length;
  }

  /// Append bytes */
  void push(List<int> v) {
    pushArray(v);
  }

  /// Get a single byte */
  int get() {
    if (readPos < length!) {
      return array![readPos++];
    }
    throw 'Read past end of buffer';
  }

  /// Append bytes in `v`. Throws if `len` doesn't match `v.length` */
  void pushUint8ListChecked(Uint8List v, int len) {
    if (v.length != len) {
      throw 'Binary data has incorrect size';
    }
    pushArray(v);
  }

  /// Get `len` bytes */
  Uint8List getUint8List(int len) {
    if (readPos + len > length!) {
      throw 'Read past end of buffer';
    }
    var result =
        Uint8List.view(array!.buffer, array!.offsetInBytes + readPos, len);
    readPos += len;
    return result;
  }

  /// Append a `uint16` */
  void pushUint16(int v) {
    push([(v >> 0) & 0xff, (v >> 8) & 0xff]);
  }

  /// Get a `uint16` */
  int getUint16() {
    var v = 0;
    v |= get() << 0;
    v |= get() << 8;
    return v;
  }

  /// Append a `uint32` */
  void pushUint32(int v) {
    var t = [
      (v >> 0) & 0xff,
      (v >> 8) & 0xff,
      (v >> 16) & 0xff,
      (v >> 24) & 0xff
    ];
    print("uin32 as array");
    print(v);
    print(t);
    push(t);
  }

  /// Get a `uint32` */
  int getUint32() {
    var v = 0;
    v |= get() << 0;
    v |= get() << 8;
    v |= get() << 16;
    v |= get() << 24;
    return v >> 0;
  }

  /// Append a `uint64`. *Caution*: `number` only has 53 bits of precision */
  void pushNumberAsUint64(int v) {
    pushUint32(v >> 0);
    pushUint32(((v ~/ 0x10000) >> 0).floor());
  }

  /// Get a `uint64` as a `number`. *Caution*: `number` only has 53 bits of precision; some values will change.
  /// `numeric.binaryToDecimal(serialBuffer.getUint8List(8))` recommended instead

  int getUint64AsNumber() {
    var low = getUint32();
    var high = getUint32();
    return (high >> 0) * 0x10000 + (low >> 0);
  }

  /// Append a `varuint32` */
  void pushVaruint32(int v) {
    while (true) {
      if (v >> 7 != 0) {
        push([0x80 | (v & 0x7f)]);
        v = v >> 7;
      } else {
        push([v]);
        break;
      }
    }
  }

  /// Get a `varuint32` */
  int getVaruint32() {
    var v = 0;
    var bit = 0;
    while (true) {
      var b = get();
      v |= (b & 0x7f) << bit;
      bit += 7;
      if ((b & 0x80) == 0) {
        break;
      }
    }
    return v >> 0;
  }

  /// Append a `varint32` */
  void pushVarint32(int v) {
    pushVaruint32((v << 1) ^ (v >> 31));
  }

  /// Get a `varint32` */
  int getVarint32() {
    var v = getVaruint32();
    if ((v & 1) != 0) {
      return ((~v) >> 1) | 0x8000;
    } else {
      return v >> 1;
    }
  }

  // /** Append a `float32` */
  // void pushFloat32(double v) {
  //     pushArray(Uint8List.fromList(Float32List.fromList([v])));
  // }

  // /** Get a `float32` */
  // double getFloat32() {
  //     return Float32List(getUint8List(4).slice().buffer)[0];
  // }

  // /** Append a `float64` */
  // void pushFloat64(int v) {
  //     pushArray(Uint8List.fromList(Float64List.fromList([v])));
  // }

  // /** Get a `float64` */
  // public getFloat64() {
  //     return new Float64Array(getUint8List(8).slice().buffer)[0];
  // }

  /// Append a `name` */
  void pushName(String s) {
    charToSymbol(int c) {
      if (c >= 'a'.codeUnitAt(0) && c <= 'z'.codeUnitAt(0)) {
        return (c - 'a'.codeUnitAt(0)) + 6;
      }
      if (c >= '1'.codeUnitAt(0) && c <= '5'.codeUnitAt(0)) {
        return (c - '1'.codeUnitAt(0)) + 1;
      }
      return 0;
    }

    var a = new Uint8List(8);
    var bit = 63;
    for (var i = 0; i < s.length; ++i) {
      var c = charToSymbol(s.codeUnitAt(i));
      if (bit < 5) {
        c = c << 1;
      }
      for (var j = 4; j >= 0; --j) {
        if (bit >= 0) {
          a[(bit / 8).floor()] |= ((c >> j) & 1) << (bit % 8);
          --bit;
        }
      }
    }
    pushArray(a);
  }

  /// Get a `name` */
  String getName() {
    var a = getUint8List(8);
    var result = '';
    for (var bit = 63; bit >= 0;) {
      var c = 0;
      for (var i = 0; i < 5; ++i) {
        if (bit >= 0) {
          c = (c << 1) | ((a[(bit / 8).floor()] >> (bit % 8)) & 1);
          --bit;
        }
      }
      if (c >= 6) {
        result += String.fromCharCode(c + 'a'.codeUnitAt(0) - 6);
      } else if (c >= 1) {
        result += String.fromCharCode(c + '1'.codeUnitAt(0) - 1);
      } else {
        result += '.';
      }
    }
    while (result.endsWith('.')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  /// Append length-prefixed binary data */
  void pushBytes(List<int> v) {
    pushVaruint32(v.length);
    pushArray(v);
  }

  /// Get length-prefixed binary data */
  Uint8List getBytes() {
    return getUint8List(getVaruint32());
  }

  /// Append a string */
  void pushString(String v) {
    pushBytes(utf8.encode(v));
  }

  /// Get a string */
  String getString() {
    return utf8.decode(getBytes());
  }

  /// Append a `symbol_code`. Unlike `symbol`, `symbol_code` doesn't include a precision. */
  void pushSymbolCode(String name) {
    Uint8List a = Uint8List.fromList(utf8.encode(name));
    while (a.length < 8) {
      a.add(0);
    }
    pushArray(a.sublist(0, 8));
  }

  /// Get a `symbol_code`. Unlike `symbol`, `symbol_code` doesn't include a precision. */
  dynamic getSymbolCode() {
    var a = getUint8List(8);
    int len;
    for (len = 0; len < a.length; ++len) {
      if (a[len] == 0) {
        break;
      }
    }
    var name = utf8.decode(Uint8List.view(a.buffer, a.offsetInBytes, len));
    return name;
  }

  /// Append a `symbol` */
  void pushSymbol(Symbol symbol) {
    var a = [symbol.precision! & 0xff];
    a.addAll(utf8.encode(symbol.name!));
    while (a.length < 8) {
      a.add(0);
    }
    pushArray(a.sublist(0, 8));
  }

  /// Get a `symbol` */
  Symbol getSymbol() {
    var precision = get();
    var a = getUint8List(7);
    int len;
    for (len = 0; len < a.length; ++len) {
      if (a[len] == 0) {
        break;
      }
    }
    var name = utf8.decode(new Uint8List.view(a.buffer, a.offsetInBytes, len));
    return Symbol(name: name, precision: precision);
  }

  /// Append an asset */
  void pushAsset(String s) {
    s = s.trim();
    var pos = 0;
    var amount = '';
    var precision = 0;
    if (s[pos] == '-') {
      amount += '-';
      ++pos;
    }
    var foundDigit = false;
    while (pos < s.length &&
        s.codeUnitAt(pos) >= '0'.codeUnitAt(0) &&
        s.codeUnitAt(pos) <= '9'.codeUnitAt(0)) {
      foundDigit = true;
      amount += s[pos];
      ++pos;
    }
    if (!foundDigit) {
      throw 'Asset must begin with a number';
    }
    if (s[pos] == '.') {
      ++pos;
      while (pos < s.length &&
          s.codeUnitAt(pos) >= '0'.codeUnitAt(0) &&
          s.codeUnitAt(pos) <= '9'.codeUnitAt(0)) {
        amount += s[pos];
        ++precision;
        ++pos;
      }
    }
    var name = s.substring(pos).trim();
    pushArray(numeric.signedDecimalToBinary(8, amount));
    pushSymbol(Symbol(name: name, precision: precision));
  }

  /// Get an asset */
  String getAsset() {
    var amount = getUint8List(8);
    var sym = getSymbol();
    var s =
        numeric.signedBinaryToDecimal(amount, minDigits: sym.precision! + 1);
    if (sym.precision != 0) {
      s = s.substring(0, s.length - sym.precision!) +
          '.' +
          s.substring(s.length - sym.precision!);
    }
    return s + ' ' + sym.name!;
  }

  /// Append a public key */
  void pushPublicKey(String s) {
    var key = numeric.stringToPublicKey(s);
    push([key.type.index]);
    pushArray(key.data);
  }

  /// Get a public key */
  String getPublicKey() {
    var type = get();
    var data = getUint8List(numeric.publicKeyDataSize);
    return numeric.publicKeyToString(IKey(type as KeyType, data));
  }

  /// Append a private key */
  void pushPrivateKey(String s) {
    var key = numeric.stringToPrivateKey(s);
    push([key.type.index]);
    pushArray(key.data);
  }

  /// Get a private key */
  String getPrivateKey() {
    var type = get();
    var data = getUint8List(numeric.privateKeyDataSize);
    return numeric.privateKeyToString(IKey(type as KeyType, data));
  }

  /// Append a signature */
  void pushSignature(String s) {
    var key = numeric.stringToSignature(s);
    push([key.type.index]);
    pushArray(key.data);
  }

  /// Get a signature */
  String getSignature() {
    var type = get();
    var data = getUint8List(numeric.signatureDataSize);
    return numeric.signatureToString(IKey(type as KeyType, data));
  }
} // SerialBuffer

/// Is this a supported ABI version? */
bool supportedAbiVersion(String version) {
  return version.startsWith('eosio::abi/1.');
}

DateTime checkDateParse(String date) {
  var result = DateTime.parse(date);
  // if (Number.isNaN(result)) {
  //     throw new Error('Invalid time format');
  // }
  return result;
}

/// Convert date in ISO format to `time_point` (miliseconds since epoch) */
int dateToTimePoint(String date) {
  return (checkDateParse(date + 'Z').millisecondsSinceEpoch * 1000).round();
}

/// Convert `time_point` (miliseconds since epoch) to date in ISO format */
String timePointToDate(int us) {
  var s = DateTime.fromMillisecondsSinceEpoch(us ~/ 1000).toIso8601String();
  return s.substring(0, s.length - 1);
}

/// Convert date in ISO format to `time_point_sec` (seconds since epoch) */
int dateToTimePointSec(String date) {
  var v = checkDateParse(date);
  // v = v.toUtc();
  print("time1 : ");
  print(v.toString());
  var t = (v.millisecondsSinceEpoch / 1000).round();
  return t;
}

/// Convert `time_point_sec` (seconds since epoch) to to date in ISO format */
String timePointSecToDate(int sec) {
  String s = DateTime.fromMillisecondsSinceEpoch(sec * 1000).toIso8601String();
  print("DATE : ");
  print(s);
  return s;
}

/// Convert date in ISO format to `block_timestamp_type` (half-seconds since a different epoch) */
int dateToBlockTimestamp(String date) {
  return ((checkDateParse(date + 'Z')
                  .subtract(Duration(milliseconds: 946684800000)))
              .millisecondsSinceEpoch /
          500)
      .round();
}

/// Convert `block_timestamp_type` (half-seconds since a different epoch) to to date in ISO format */
String blockTimestampToDate(int slot) {
  var s = (DateTime.fromMillisecondsSinceEpoch(slot * 500 + 946684800000))
      .toIso8601String();
  return s.substring(0, s.length - 1);
}

/// Convert `string` to `Symbol`. format: `precision,NAME`. */
Symbol stringToSymbol(String s) {
  RegExp exp = new RegExp(r"^([0-9]+),([A-Z]+)$");
  var m = exp.allMatches(s).toList();
  if (!exp.hasMatch(s)) {
    throw 'Invalid symbol';
  }
  return Symbol(name: m[2].toString(), precision: int.parse([1].toString()));
}

/// Convert `Symbol` to `string`. format: `precision,NAME`. */
Future<String> symbolToString(Symbol s) async {
  return s.precision.toString() + ',' + s.name!;
}

/// Convert binary data to hex */
String arrayToHex(Uint8List data) {
  var result = '';
  for (var x in data) {
    var str = ('00' + x.toRadixString(16));
    result += str.substring(str.length - 2, str.length);
  }
  return result.toUpperCase();
}

/// Convert hex to binary data */
Uint8List hexToUint8List(String hex) {
  if (!(hex is String)) {
    throw 'Expected string containing hex digits';
  }
  if (hex.length % 2 != 0) {
    throw 'Odd number of hex digits';
  }
  var l = hex.length ~/ 2;
  var result = new Uint8List(l);
  for (var i = 0; i < l; ++i) {
    var x = int.parse(hex.substring(i * 2, (2 * (i + 1))), radix: 16);
    if (x.isNaN) {
      throw 'Expected hex string';
    }
    result[i] = x;
  }
  return result;
}

SerialBuffer serializeUnknown(SerialBuffer buffer, dynamic data) {
  throw 'Don\'t know how to serialize ';
}

SerialBuffer deserializeUnknown(SerialBuffer buffer) {
  throw 'Don\'t know how to deserialize ';
}

void serializeStruct(Type? self, SerialBuffer buffer, Object? data,
    {SerializerState? state, allowExtensions = true}) {
  if (state == null) state = SerializerState();
  // try {
  if (self!.base != null) {
    self.base!.serialize!(self.base, buffer, data,
        state: state, allowExtensions: allowExtensions);
  }
  var dy = data as dynamic;
  for (var field in self.fields!) {
    if (dy[field.name] != null) {
      if (state.skippedBinaryExtension) {
        throw 'unexpected ' + self.name! + '.' + field.name!;
      }
      field.type!.serialize!(field.type, buffer, dy[field.name],
          state: state,
          allowExtensions: allowExtensions &&
              field == self.fields![self.fields!.length - 1]);
    } else {
      if (allowExtensions && field.type!.extensionOf != null) {
        state.skippedBinaryExtension = true;
      } else {
        throw 'missing ' +
            self.name! +
            '.' +
            field.name! +
            ' (type=' +
            field.type!.name! +
            ')';
      }
    }
  }
  // } catch (e) {
  //   throw e;
  // }
}

deserializeStruct(Type? self, SerialBuffer buffer,
    {SerializerState? state, allowExtensions = true}) {
  if (state == null) state = SerializerState();
  try {
    var result;
    if (self!.base != null) {
      result = self.base!.deserialize!(self.base, buffer,
          state: state, allowExtensions: allowExtensions);
    } else {
      result = {};
    }
    for (var field in self.fields!) {
      if (allowExtensions &&
          field.type!.extensionOf != null &&
          !buffer.haveReadData()) {
        state.skippedBinaryExtension = true;
      } else {
        result[field.name] = field.type!.deserialize!(field.type, buffer,
            state: state, allowExtensions: allowExtensions);
      }
    }
    return result;
  } catch (e) {
    throw e;
  }
}

serializeVariant(Type? self, SerialBuffer buffer, Object? data,
    {SerializerState? state, allowExtensions = true}) {
  if (state == null) state = SerializerState();
  if (!(data is List) || data.length != 2 || !(data[0] is String)) {
    throw 'expected variant: ["type", value]';
  }
  var a = ((data)[0]) as String;
  var b = ((data)[1]) as Object;
  var i = self!.fields!.indexWhere((field) => field.name == a);
  if (i < 0) {
    throw 'type "$b" is not valid for variant';
  }
  buffer.pushVaruint32(i);
  self.fields![i].type!.serialize!(self.fields![i].type, buffer, b,
      state: state, allowExtensions: allowExtensions);
}

deserializeVariant(Type? self, SerialBuffer buffer,
    {SerializerState? state, allowExtensions = true}) {
  if (state == null) state = SerializerState();
  var i = buffer.getVaruint32();
  if (i >= self!.fields!.length) {
    throw 'type index $i is not valid for variant';
  }
  var field = self.fields![i];
  return [
    field.name,
    field.type!.deserialize!(field.type, buffer,
        state: state, allowExtensions: allowExtensions)
  ];
}

serializeArray(Type? self, SerialBuffer buffer, Object? data,
    {SerializerState? state, allowExtensions = true}) {
  if (state == null) state = SerializerState();
  buffer.pushVaruint32((data as List).length);
  for (var item in data) {
    self!.arrayOf!.serialize!(self.arrayOf, buffer, item,
        state: state, allowExtensions: false);
  }
}

deserializeArray(Type? self, SerialBuffer buffer,
    {SerializerState? state, allowExtensions = true}) {
  if (state == null) state = SerializerState();
  var len = buffer.getVaruint32();
  var result = [];
  for (var i = 0; i < len; ++i) {
    result.add(self!.arrayOf!.deserialize!(self.arrayOf, buffer,
        state: state, allowExtensions: false));
  }
  return result;
}

serializeOptional(Type? self, SerialBuffer buffer, Object? data,
    {SerializerState? state, allowExtensions = true}) {
  if (state == null) state = SerializerState();
  if (data == null) {
    buffer.push([0]);
  } else {
    buffer.push([1]);
    self!.optionalOf!.serialize!(self.optionalOf, buffer, data,
        state: state, allowExtensions: allowExtensions);
  }
}

deserializeOptional(Type? self, SerialBuffer buffer,
    {SerializerState? state, allowExtensions = true}) {
  if (state == null) state = SerializerState();
  if (buffer.get() != 0) {
    return self!.optionalOf!.deserialize!(self.optionalOf, buffer,
        state: state, allowExtensions: allowExtensions);
  } else {
    return null;
  }
}

serializeExtension(Type? self, SerialBuffer buffer, Object? data,
    {SerializerState? state, allowExtensions = true}) {
  if (state == null) state = SerializerState();
  self!.extensionOf!.serialize!(self.extensionOf, buffer, data,
      state: state, allowExtensions: allowExtensions);
}

deserializeExtension(Type? self, SerialBuffer buffer,
    {SerializerState? state, allowExtensions = true}) {
  if (state == null) state = SerializerState();
  return self!.extensionOf!.deserialize!(self.extensionOf, buffer,
      state: state, allowExtensions: allowExtensions);
}

class CreateTypeArgs {
  String? name;
  String? aliasOfName;
  Type? arrayOf;
  Type? optionalOf;
  Type? extensionOf;
  String? baseName;
  Type? base;
  List<Field>? fields;
  void Function(SerialBuffer buffer, Object data,
      {SerializerState state, bool allowExtensions})? serialize;
  int Function(SerialBuffer buffer,
      {SerializerState state, bool allowExtensions})? deserialize;
}

Type createType(
    {String? name = '<missing name>',
    String? aliasOfName = "",
    Type? arrayOf,
    Type? optionalOf,
    void Function(Type? self, SerialBuffer buffer, Object? data,
            {SerializerState? state, bool? allowExtensions})?
        serialize,
    Object? Function(Type? self, SerialBuffer buffer,
            {SerializerState? state, bool? allowExtensions})?
        deserialize,
    String? baseName: "",
    List<Field>? fields: const [],
    Type? extensionOf}) {
  var t = Type(
      aliasOfName: aliasOfName,
      name: name,
      arrayOf: arrayOf,
      optionalOf: optionalOf,
      extensionOf: extensionOf,
      base: null,
      baseName: baseName,
      fields: fields,
      serialize: serialize,
      deserialize: deserialize);

  return t;
}

int checkRange(int orig, int converted) {
  if (orig.isNaN || converted.isNaN || (!(orig is int) && !(orig is String))) {
    throw 'Expected number';
  }
  if (orig != converted) {
    throw 'Number is out of range';
  }
  return orig;
}

/// Create the set of types built-in to the abi format */
Map<String, Type> createInitialTypes() {
  var result = {
    "bool": createType(
      name: 'bool',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.push([data != null ? 1 : 0]);
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return buffer.get();
      },
    ),
    "uint8": createType(
      name: 'uint8',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.push([checkRange(data as int, data & 0xff)]);
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return buffer.get();
      },
    ),
    "int8": createType(
      name: 'int8',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.push([checkRange((data as int), data << 24 >> 24)]);
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return buffer.get() << 24 >> 24;
      },
    ),
    "uint16": createType(
      name: 'uint16',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushUint16(checkRange(data as int, data & 0xffff));
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return buffer.getUint16();
      },
    ),
    "int16": createType(
      name: 'int16',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushUint16(checkRange(data as int, data << 16 >> 16));
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return buffer.getUint16() << 16 >> 16;
      },
    ),
    "uint32": createType(
      name: 'uint32',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushUint32(checkRange(data as int, data >> 0));
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return buffer.getUint32();
      },
    ),
    "uint64": createType(
      name: 'uint64',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushArray(numeric.decimalToBinary(8, '' + data.toString()));
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return numeric.binaryToDecimal(buffer.getUint8List(8));
      },
    ),
    "int64": createType(
      name: 'int64',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer
            .pushArray(numeric.signedDecimalToBinary(8, '' + data.toString()));
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return numeric.signedBinaryToDecimal(buffer.getUint8List(8));
      },
    ),
    "int32": createType(
      name: 'int32',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushUint32(checkRange(data as int, data | 0));
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return buffer.getUint32() | 0;
      },
    ),
    "varuint32": createType(
      name: 'varuint32',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushVaruint32(checkRange(data as int, data >> 0));
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return buffer.getVaruint32();
      },
    ),
    "varint32": createType(
      name: 'varint32',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushVarint32(checkRange(data as int, data == null ? 0 : data));
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return buffer.getVarint32();
      },
    ),
    "uint128": createType(
      name: 'uint128',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushArray(numeric.decimalToBinary(16, '' + (data as String)));
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return numeric.binaryToDecimal(buffer.getUint8List(16));
      },
    ),
    "int128": createType(
      name: 'int128',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushArray(
            numeric.signedDecimalToBinary(16, '' + (data as String)));
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return numeric.signedBinaryToDecimal(buffer.getUint8List(16));
      },
    ),
    // "float32": createType(
    //     name: 'float32',
    //     serialize:(Type self,SerialBuffer buffer ,Object data,{SerializerState state,bool allowExtensions}) {
    //       buffer.pushFloat32(data); },
    //     deserialize:(Type self,SerialBuffer buffer,{SerializerState state,bool allowExtensions}) {
    //       return buffer.getFloat32(); },
    // ),
    // "float64": createType(
    //     name: 'float64',
    //     serialize:(Type self,SerialBuffer buffer ,Object data,{SerializerState state,bool allowExtensions}) {
    //       buffer.pushFloat64(data); },
    //     deserialize:(Type self,SerialBuffer buffer,{SerializerState state,bool allowExtensions}) {
    //       return buffer.getFloat64(); },
    // ),
    "float128": createType(
      name: 'float128',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushUint8ListChecked(hexToUint8List(data as String), 16);
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return arrayToHex(buffer.getUint8List(16));
      },
    ),

    "bytes": createType(
      name: 'bytes',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        if (data is Uint8List || data is List) {
          buffer.pushBytes(data as List<int>);
        } else {
          buffer.pushBytes(hexToUint8List(data as String));
        }
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        if (state != null && state.options.bytesAsUint8List) {
          return buffer.getBytes();
        } else {
          return arrayToHex(buffer.getBytes());
        }
      },
    ),
    "string": createType(
      name: 'string',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushString(data as String);
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return buffer.getString();
      },
    ),
    "name": createType(
      name: 'name',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushName(data as String);
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return buffer.getName();
      },
    ),
    "time_point": createType(
      name: 'time_point',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushNumberAsUint64(dateToTimePoint(data as String));
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return timePointToDate(buffer.getUint64AsNumber());
      },
    ),
    "time_point_sec": createType(
      name: 'time_point_sec',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        var date = dateToTimePointSec(data as String);
        buffer.pushUint32(date);
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return timePointSecToDate(buffer.getUint32());
      },
    ),
    "block_timestamp_type": createType(
      name: 'block_timestamp_type',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushUint32(dateToBlockTimestamp(data as String));
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return blockTimestampToDate(buffer.getUint32());
      },
    ),
    "symbol_code": createType(
      name: 'symbol_code',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushSymbolCode(data as String);
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return buffer.getSymbolCode();
      },
    ),
    "symbol": createType(
      name: 'symbol',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushSymbol(stringToSymbol(data as String));
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return symbolToString(buffer.getSymbol());
      },
    ),
    "asset": createType(
      name: 'asset',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushAsset(data as String);
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return buffer.getAsset();
      },
    ),
    "checksum160": createType(
      name: 'checksum160',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushUint8ListChecked(hexToUint8List(data as String), 20);
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return arrayToHex(buffer.getUint8List(20));
      },
    ),
    "checksum256": createType(
      name: 'checksum256',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushUint8ListChecked(hexToUint8List(data as String), 32);
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return arrayToHex(buffer.getUint8List(32));
      },
    ),
    "checksum512": createType(
      name: 'checksum512',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushUint8ListChecked(hexToUint8List(data as String), 64);
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return arrayToHex(buffer.getUint8List(64));
      },
    ),
    "public_key": createType(
      name: 'public_key',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushPublicKey(data as String);
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return buffer.getPublicKey();
      },
    ),
    "private_key": createType(
      name: 'private_key',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushPrivateKey(data as String);
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return buffer.getPrivateKey();
      },
    ),
    "signature": createType(
      name: 'signature',
      serialize: (Type? self, SerialBuffer buffer, Object? data,
          {SerializerState? state, bool? allowExtensions}) {
        buffer.pushSignature(data as String);
      },
      deserialize: (Type? self, SerialBuffer buffer,
          {SerializerState? state, bool? allowExtensions}) {
        return buffer.getSignature();
      },
    ),
  };

  result['extended_asset'] = createType(
    name: 'extended_asset',
    baseName: '',
    fields: [
      Field(name: 'quantity', typeName: 'asset', type: result['asset']),
      Field(name: 'contract', typeName: 'name', type: result['name']),
    ],
    serialize: serializeStruct,
    deserialize: deserializeStruct,
  );

  return result;
} // createInitialTypes()

/// Get type from `types` */
Type getType(Map<String?, Type> types, String? name) {
  var type = types[name];
  if (type != null && type.aliasOfName!.isNotEmpty) {
    return getType(types, type.aliasOfName);
  }
  if (type != null) {
    return type;
  }
  if (name!.endsWith('[]')) {
    return createType(
      name: name,
      arrayOf: getType(types, name.substring(0, name.length - 2)),
      serialize: serializeArray,
      deserialize: deserializeArray,
    );
  }
  if (name.endsWith('?')) {
    return createType(
      name: name,
      optionalOf: getType(types, name.substring(0, name.length - 1)),
      serialize: serializeOptional,
      deserialize: deserializeOptional,
    );
  }
  if (name.endsWith("\$")) {
    return createType(
      name: name,
      extensionOf: getType(types, name.substring(0, name.length - 1)),
      serialize: serializeExtension,
      deserialize: deserializeExtension,
    );
  }
  throw 'Unknown type: ' + name;
}

/// Get types from abi
/// @param initialTypes Set of types to build on.
///     In most cases, it's best to fill this from a fresh call to `getTypesFromAbi()`.

Map<String?, Type> getTypesFromAbi(Map<String, Type> initialTypes, Abi abi) {
  var types = Map.from(initialTypes).cast<String?, Type>();
  if (abi.types != null) {
    for (var item in abi.types!) {
      types[item.newTypeName] =
          createType(name: item.newTypeName, aliasOfName: item.type);
    }
  }
  if (abi.structs != null) {
    for (var str in abi.structs!) {
      types[str.name] = createType(
          name: str.name,
          baseName: str.base,
          fields: str.fields
              ?.map((item) =>
                  Field(name: item.name, typeName: item.type, type: null))
              .toList(),
          serialize: serializeStruct,
          deserialize: deserializeStruct);
    }
  }
  if (abi.variants != null) {
    for (var v in abi.variants!) {
      types[v.name] = createType(
        name: v.name,
        fields: v.types
            .map((s) => Field(name: s, typeName: s, type: null))
            .toList(),
        serialize: serializeVariant,
        deserialize: deserializeVariant,
      );
    }
  }
  types.forEach((name, type) {
    if (type.baseName!.isNotEmpty) {
      type.base = getType(types, type.baseName);
    }
    for (var field in type.fields!) {
      field.type = getType(types, field.typeName);
    }
  });
  return types;
} // getTypesFromAbi

/// TAPoS: Return transaction fields which reference `refBlock` and expire `expireSeconds` after `refBlock.timestamp` */
dynamic transactionHeader(BlockTaposInfo refBlock, int expireSeconds) {
  print("REFBLOCK TIMESTAMP:");
  print(refBlock.timestamp);
  var t = {
    "expiration": timePointSecToDate(
        dateToTimePointSec(refBlock.timestamp!) + expireSeconds),
    "ref_block_num": refBlock.blockNum! & 0xffff,
    "ref_block_prefix": refBlock.refBlockPrefix,
  };
  print("Header");
  print(t);
  return t;
}

/// Convert action data to serialized form (hex) */
String serializeActionData(
    Contract contract, String? account, String? name, Object? data) {
  var action = contract.actions![name];
  if (action == null) {
    throw "Unknown action $name in contract $account";
  }
  var buffer = new SerialBuffer(Uint8List(0));
  action.serialize!(action, buffer, data);
  return arrayToHex(buffer.asUint8List());
}

/// Return action in serialized form */
SerializedAction serializeAction(Contract contract, String? account,
    String? name, List<Authorization>? authorization, dynamic data) {
  var sr = SerializedAction(
    account: account,
    name: name,
    authorization: authorization,
    data: serializeActionData(contract, account, name, data),
  );
  return sr;
}

/// Deserialize action data. If `data` is a `string`, then it's assumed to be in hex. */
Object? deserializeActionData(
    Contract contract, String account, String name, Object data) {
  var action = contract.actions![name];
  if (data is String) {
    data = hexToUint8List(data);
  }
  if (action == null) {
    throw "Unknown action $name in contract $account";
  }
  var buffer = SerialBuffer(Uint8List.fromList(data as List<int>));
  return action.deserialize!(action, buffer);
}

/// Deserialize action. If `data` is a `string`, then it's assumed to be in hex. */
Action deserializeAction(Contract contract, String? account, String? name,
    List<Authorization>? authorization, Object? data) {
  return Action(
    account: account,
    name: name,
    authorization: authorization,
    data: serializeActionData(contract, account, name, data),
  );
}
