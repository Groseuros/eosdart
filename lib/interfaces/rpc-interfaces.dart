import 'dart:typed_data';

class AbiType {
  final String? newTypeName; //new_type_name
  final String? type;

  AbiType(this.newTypeName, this.type);
  factory AbiType.fromJson(Map json) {
    return AbiType(json["new_type_name"], json["type"]);
  }
}

class AbiStructField {
  final String? name;
  final String? type;

  AbiStructField(this.name, this.type);

  factory AbiStructField.fromJson(Map json) {
    return AbiStructField(json["name"], json["type"]);
  }
}

class AbiStruct {
  final String? name;
  final String? base;
  final List<AbiStructField>? fields;

  AbiStruct(this.name, this.base, this.fields);
  factory AbiStruct.fromJson(Map json) {
    return AbiStruct(
        json["name"],
        json["base"],
        (json["fields"] as List?)
            ?.map((item) => AbiStructField.fromJson(item))
            .toList());
  }
}

class AbiAction {
  final String? name;
  final String? type;
  final String? ricardianContract; //ricardian_contract
  AbiAction(this.name, this.type, this.ricardianContract);

  factory AbiAction.fromJson(Map json) {
    return AbiAction(json["name"], json["type"], json["ricardian_contract"]);
  }
}

class AbiTable {
  final String? name;
  final String? type;
  final String? indexType; //index_type
  final List<String> keyNames; //key_names
  final List<String> keyTypes; //key_types

  AbiTable(
      this.name, this.type, this.indexType, this.keyNames, this.keyTypes);

  factory AbiTable.fromJson(Map json) {
    return AbiTable(
        json["name"],
        json["type"],
        json["index_type"],
        (json["key_names"] as List).map((item) => item.toString()).toList(),
        (json["key_types"] as List).map((item) => item.toString()).toList());
  }
}

class AbiRicardianClauses {
  final String? id;
  final String? body;

  AbiRicardianClauses(this.id, this.body);

  factory AbiRicardianClauses.fromJson(Map json) {
    return AbiRicardianClauses(json["id"], json["body"]);
  }
}

class AbiErrorMessages {
  final String? errorCode;
  final String? errorMsg;

  AbiErrorMessages(this.errorCode, this.errorMsg);
  factory AbiErrorMessages.fromJson(Map json) {
    return AbiErrorMessages(json["error_code"], json["error_msg"]);
  }
}

class AbiExtensions {
  final int? tag;
  final String? value;

  AbiExtensions(this.tag, this.value);

  factory AbiExtensions.fromJson(Map json) {
    return AbiExtensions(json["tag"], json["value"]);
  }
}

class AbiVariants {
  final String? name;
  final List<String> types;

  AbiVariants(this.name, this.types);
  factory AbiVariants.fromJson(Map json) {
    return AbiVariants(json["name"],
        (json["types"] as List).map((item) => item.toString()).toList());
  }
}

/// Structured format for abis
class Abi {
  String? version;
  List<AbiType>? types;
  List<AbiStruct>? structs;
  List<AbiAction>? actions;
  List<AbiTable>? tables;
  List<AbiRicardianClauses>? ricardianClauses;
  List<AbiErrorMessages>? errorMessages;
  List<AbiExtensions>? abiExtensions;
  List<AbiVariants>? variants;
  Abi(
      {this.abiExtensions,
      this.actions,
      this.errorMessages,
      this.ricardianClauses,
      this.structs,
      this.tables,
      this.types,
      this.variants,
      this.version});
  factory Abi.fromJson(Map json) {
    return Abi(
        abiExtensions: (json["abi_extensions"] as List?)
            ?.map((item) => AbiExtensions.fromJson(item))
            .toList(),
        actions: (json["actions"] as List?)
            ?.map((item) => AbiAction.fromJson(item))
            .toList(),
        structs: (json["structs"] as List?)
            ?.map((item) => AbiStruct.fromJson(item))
            .toList(),
        tables: (json["tables"] as List?)
            ?.map((item) => AbiTable.fromJson(item))
            .toList(),
        types: (json["types"] as List?)
            ?.map((item) => AbiType.fromJson(item))
            .toList(),
        variants: (json["variants"] as List?)
            ?.map((item) => AbiVariants.fromJson(item))
            .toList(),
        errorMessages: (json["error_messages"] as List?)
            ?.map((item) => AbiErrorMessages.fromJson(item))
            .toList(),
        ricardianClauses: (json["ricardian_clauses"] as List?)
            ?.map((item) => AbiRicardianClauses.fromJson(item))
            .toList(),
        version: json["version"]);
  }
}

/// Return value of `/v1/chain/get_abi`
class GetAbiResult {
  final String? accountName; //account_name
  final Abi abi;

  GetAbiResult(this.accountName, this.abi);

  factory GetAbiResult.fromJson(Map json) {
    return GetAbiResult(json["account_name"], Abi.fromJson(json["abi"]));
  }
}

/// Subset of `GetBlockResult` needed to calculate TAPoS fields in transactions
class BlockTaposInfo {
  final String? timestamp;
  final int? blockNum;
  final int? refBlockPrefix;

  BlockTaposInfo(this.timestamp, this.blockNum, this.refBlockPrefix);
}

/// Return value of `/v1/chain/get_block` */
class GetBlockResult extends BlockTaposInfo {
  final String? producer;
  final int? confirmed;
  final String? previous;
  final String? transactionMroot;
  final String? actionMroot;
  final int? scheduleVersion;
  final String? producerSignature;
  final String? id;

  GetBlockResult(
      {this.actionMroot,
      this.confirmed,
      this.id,
      this.previous,
      this.producer,
      this.producerSignature,
      this.scheduleVersion,
      this.transactionMroot,
      timestamp,
      blockNum,
      refBlockPrefix})
      : super(timestamp, blockNum, refBlockPrefix);

  factory GetBlockResult.fromJson(Map json) {
    print(json);
    return GetBlockResult(
        producer: json["producer"],
        confirmed: json["confirmed"],
        previous: json["previous"],
        transactionMroot: json["transaction_mroot"],
        actionMroot: json["action_mroot"],
        scheduleVersion: json["schedule_version"],
        producerSignature: json["producer_signature"],
        id: json["id"],
        timestamp: json["timestamp"],
        blockNum: json["block_num"],
        refBlockPrefix: json["ref_block_prefix"]);
  }
}

/// Return value of `/v1/chain/get_code`
class GetCodeResult {
  final String? accountName;
  final String? codeHash;
  final String? wast;
  final String? wasm;
  final Abi? abi;

  GetCodeResult(
      {this.abi, this.accountName, this.codeHash, this.wasm, this.wast});

  factory GetCodeResult.fromJson(Map json) {
    return GetCodeResult(
      accountName: json["account_name"],
      codeHash: json["code_hash"],
      wast: json["wast"],
      wasm: json["wasm"],
      abi: Abi.fromJson(json["abi"]),
    );
  }
}

/// Return value of `/v1/chain/get_info`
class GetInfoResult {
  final String? serverVersion;
  final String? chainId;
  final int? headBlockNum;
  final int? lastIrreversibleBlockNum;
  final String? lastIrreversibleBlockId;
  final String? headBlockId;
  final String? headBlockTime;
  final String? headBlockProducer;
  final int? virtualBlockCpuLimit;
  final int? virtualBlockNetLimit;
  final int? blockCpuLimit;
  final int? blockNetLimit;

  GetInfoResult(
      {this.blockCpuLimit,
      this.blockNetLimit,
      this.chainId,
      this.headBlockId,
      this.headBlockNum,
      this.headBlockProducer,
      this.headBlockTime,
      this.lastIrreversibleBlockId,
      this.lastIrreversibleBlockNum,
      this.serverVersion,
      this.virtualBlockCpuLimit,
      this.virtualBlockNetLimit});

  factory GetInfoResult.fromJson(Map json) {
    return GetInfoResult(
      blockCpuLimit: json["block_cpu_limit"],
      blockNetLimit: json["block_net_limit"],
      chainId: json["chain_id"],
      headBlockId: json["head_block_id"],
      headBlockNum: json["head_block_num"],
      headBlockProducer: json["head_block_producer"],
      headBlockTime: json["head_block_time"],
      lastIrreversibleBlockId: json["last_irreversible_block_id"],
      lastIrreversibleBlockNum: json["last_irreversible_block_num"],
      serverVersion: json["server_version"],
      virtualBlockCpuLimit: json["virtual_block_cpu_limit"],
      virtualBlockNetLimit: json["virtual_block_net_limit"],
    );
  }
}

/// Return value of `/v1/chain/get_raw_code_and_abi`
class GetRawCodeAndAbiResult {
  final String? accountName;
  final String? wasm;
  final String? abi;

  GetRawCodeAndAbiResult({this.abi, this.accountName, this.wasm});

  factory GetRawCodeAndAbiResult.fromJson(Map json) {
    return GetRawCodeAndAbiResult(
      abi: json["abi"],
      accountName: json["account_name"],
      wasm: json["wasm"],
    );
  }
}

/// Arguments for `push_transaction`
class PushTransactionArgs {
  final List<String>? signatures;
  final Uint8List? serializedTransaction;

  PushTransactionArgs({this.signatures, this.serializedTransaction});
}
