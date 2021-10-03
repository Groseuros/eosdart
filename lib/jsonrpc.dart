import 'dart:convert';
import 'dart:typed_data';

import 'package:eos_dart/interfaces/api-interfaces.dart';

import './interfaces/rpc-interfaces.dart';
import './numeric.dart';
import 'package:http/http.dart' as http;
// import { GetAbiResult, GetBlockResult, GetCodeResult, GetInfoResult, GetRawCodeAndAbiResult, PushTransactionArgs } from "./eosjs-rpc-interfaces" // tslint:disable-line
// import { RpcError } from './eosjs-rpcerror';

String arrayToHex(Uint8List data) {
  var result = '';
  for (var x in data) {
    var str = ('00' + x.toRadixString(16));
    str = str.substring(str.length - 2, str.length);
    result += str;
  }
  return result;
}

/// Make RPC calls
class JsonRpc implements AuthorityProvider, AbiProvider {
  final String endpoint;
  // public fetchBuiltin: (input?: Request | string, init?: RequestInit) => Promise<Response>;

  /// @param args
  ///    * `fetch`:
  ///    * browsers: leave `null` or `undefined`
  ///    * node: provide an implementation
  JsonRpc(this.endpoint) {
    // if (args.fetch) {
    //     this.fetchBuiltin = args.fetch;
    // } else {
    //     this.fetchBuiltin = (global as any).fetch;
    // }
  }

  /// Post `body` to `endpoint + path`. Throws detailed error information in `RpcError` when available. */
  Future<dynamic> fetch(String path, dynamic body) async {
    try {
      var b = json.encode(body);
      var response = await http.post(Uri.parse(endpoint + path), body: b);
      return json.decode(response.body);
    } catch (e) {
      rethrow;
    }
  }

  Future<GetAbiResult> getAbi(String accountName) async {
    var t = await fetch('/v1/chain/get_abi', {"account_name": accountName});
    return GetAbiResult.fromJson(t);
  }

  /// Raw call to `/v1/chain/get_account`
  Future<dynamic> getAccount(String accountName) async {
    var t = await fetch('/v1/chain/get_account', {"account_name": accountName});
    return t;
  }

  /// Raw call to `/v1/chain/get_block_header_state`
  Future<dynamic> getBlockHeaderState(String blockNumOrId) async {
    var t = await fetch(
        '/v1/chain/get_block_header_state', {"block_num_or_id": blockNumOrId});
    return t;
  }

  /// Raw call to `/v1/chain/get_block`
  Future<GetBlockResult> getBlock(Object blockNumOrId) async {
    var t =
        await fetch('/v1/chain/get_block', {"block_num_or_id": blockNumOrId});
    return GetBlockResult.fromJson(t);
  }

  /// Raw call to `/v1/chain/get_code`
  Future<GetCodeResult> getCode(String accountName) async {
    var t = await fetch('/v1/chain/get_code', {"account_name": accountName});
    return GetCodeResult.fromJson(t);
  }

  /// Raw call to `/v1/chain/get_currency_balance`
  Future<dynamic> getCurrencyBalance(String code, String account,
      {String? symbol}) async {
    var t = await fetch('/v1/chain/get_currency_balance',
        {"code": code, "account": account, "symbol": symbol});
    return t;
  }

  /// Raw call to `/v1/chain/get_currency_stats`
  Future<dynamic> getCurrencyStats(String code, String symbol) async {
    var t =
        fetch('/v1/chain/get_currency_stats', {"code": code, "symbol": symbol});
    return t;
  }

  /// Raw call to `/v1/chain/get_info`
  Future<GetInfoResult> getInfo() async {
    var t = await fetch('/v1/chain/get_info', {});
    return GetInfoResult.fromJson(t);
  }

  /// Raw call to `/v1/chain/get_producer_schedule`
  Future<dynamic> getProducerSchedule() async {
    var t = fetch('/v1/chain/get_producer_schedule', {});
    return t;
  }

  /// Raw call to `/v1/chain/get_producers`
  Future<dynamic> getProducers(
      {bool json = true, String lowerBound = '', int limit = 50}) async {
    var t = fetch('/v1/chain/get_producers',
        {"json": json, "lower_bound": lowerBound, "limit": limit});
    return t;
  }

  /// Raw call to `/v1/chain/get_raw_code_and_abi` */
  Future<GetRawCodeAndAbiResult> getRawCodeAndAbi(String? accountName) async {
    var t = await fetch(
        '/v1/chain/get_raw_code_and_abi', {"account_name": accountName});
    return GetRawCodeAndAbiResult.fromJson(t);
  }

  /// calls `/v1/chain/get_raw_code_and_abi` and pulls out unneeded raw wasm code */
  Future<BinaryAbi> getRawAbi(String? accountName) async {
    var rawCodeAndAbi = await getRawCodeAndAbi(accountName);
    var abi = base64ToBinary(rawCodeAndAbi.abi!);
    return BinaryAbi(rawCodeAndAbi.accountName, abi);
  }

  /// Raw call to `/v1/chain/get_table_rows` */
  Future<dynamic> getTableRows({
    bool json = true,
    String? code,
    String? scope,
    String? table,
    String tableKey = '',
    String lowerBound = '',
    String upperBound = '',
    int indexPosition = 1,
    String keyType = '',
    int limit = 10,
  }) async {
    return fetch('/v1/chain/get_table_rows', {
      "json": json,
      "code": code,
      "scope": scope,
      "table": table,
      "table_key": tableKey,
      "lower_bound": lowerBound,
      "upper_bound": upperBound,
      "index_position": indexPosition,
      "key_type": keyType,
      "limit": limit,
    });
  }

  /// Raw call to `/v1/chain/get_table_by_scope`
  Future<dynamic> getTableByScope({
    String? code,
    String? table,
    String lowerBound = '',
    String upperBound = '',
    int limit = 10,
  }) async {
    return fetch('/v1/chain/get_table_by_scope', {
      code,
      table,
      lowerBound,
      upperBound,
      limit,
    });
  }

  /// Get subset of `availableKeys` needed to meet authorities in `transaction`. Implements `AuthorityProvider` */
  Future<List<String>> getRequiredKeys(AuthorityProviderArgs args) async {
    var t = await fetch('/v1/chain/get_required_keys', {
      "transaction": args.transaction,
      "available_keys": args.availableKeys,
    });
    var keys =
        (t["required_keys"] as List).map((item) => item.toString()).toList();
    return convertLegacyPublicKeys(keys);
  }

  /// Push a serialized transaction
  Future<dynamic> pushTransaction(PushTransactionArgs pushTransaction) async {
    var d = {
      "signatures": pushTransaction.signatures,
      "compression": 0,
      "packed_context_free_data": '',
      "packed_trx": arrayToHex(pushTransaction.serializedTransaction!),
    };
    print("");
    print("packed_trx");
    print(d["packed_trx"]);
    print(json.encode(d));
    var t = await fetch('/v1/chain/push_transaction', d);
    print(t);
    return t;
  }

  /// Raw call to `/v1/db_size/get`
  Future<dynamic> dbSizeGet() async => fetch('/v1/db_size/get', {});

  /// Raw call to `/v1/history/get_actions` */
  Future<dynamic> historyGetActions(String accountName,
      {int? pos, int? offset}) async {
    return fetch('/v1/history/get_actions',
        {"account_name": accountName, "pos": pos, "offset": offset});
  }

  /// Raw call to `/v1/history/get_transaction`
  Future<dynamic> historyGetTransaction(String id, {int? blockNumHint}) async {
    return fetch('/v1/history/get_transaction',
        {"id": id, "block_num_hint": blockNumHint});
  }

  /// Raw call to `/v1/history/get_key_accounts`
  Future<dynamic> historyGetKeyAccounts(String publicKey) async {
    return fetch('/v1/history/get_key_accounts', {"public_key": publicKey});
  }

  /// Raw call to `/v1/history/get_controlled_accounts` */
  Future<dynamic> historyGetControlledAccounts(
      String controllingAccount) async {
    return fetch('/v1/history/get_controlled_accounts',
        {"controlling_account": controllingAccount});
  }
} // JsonRpc
