// This is a generated file - do not edit.
//
// Generated from trading/v1/trading_service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'trading_service.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'trading_service.pbenum.dart';

class UpdateSettingsRequest extends $pb.GeneratedMessage {
  factory UpdateSettingsRequest({
    Settings? settings,
  }) {
    final result = create();
    if (settings != null) result.settings = settings;
    return result;
  }

  UpdateSettingsRequest._();

  factory UpdateSettingsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateSettingsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateSettingsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOM<Settings>(1, _omitFieldNames ? '' : 'settings',
        subBuilder: Settings.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSettingsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSettingsRequest copyWith(
          void Function(UpdateSettingsRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateSettingsRequest))
          as UpdateSettingsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateSettingsRequest create() => UpdateSettingsRequest._();
  @$core.override
  UpdateSettingsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateSettingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateSettingsRequest>(create);
  static UpdateSettingsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  Settings get settings => $_getN(0);
  @$pb.TagNumber(1)
  set settings(Settings value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearSettings() => $_clearField(1);
  @$pb.TagNumber(1)
  Settings ensureSettings() => $_ensure(0);
}

class SettingsResponse extends $pb.GeneratedMessage {
  factory SettingsResponse({
    Settings? settings,
    $core.Iterable<$core.String>? warnings,
  }) {
    final result = create();
    if (settings != null) result.settings = settings;
    if (warnings != null) result.warnings.addAll(warnings);
    return result;
  }

  SettingsResponse._();

  factory SettingsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SettingsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SettingsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOM<Settings>(1, _omitFieldNames ? '' : 'settings',
        subBuilder: Settings.create)
    ..pPS(2, _omitFieldNames ? '' : 'warnings')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SettingsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SettingsResponse copyWith(void Function(SettingsResponse) updates) =>
      super.copyWith((message) => updates(message as SettingsResponse))
          as SettingsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SettingsResponse create() => SettingsResponse._();
  @$core.override
  SettingsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SettingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SettingsResponse>(create);
  static SettingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Settings get settings => $_getN(0);
  @$pb.TagNumber(1)
  set settings(Settings value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearSettings() => $_clearField(1);
  @$pb.TagNumber(1)
  Settings ensureSettings() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get warnings => $_getList(1);
}

class Settings extends $pb.GeneratedMessage {
  factory Settings({
    $core.double? tradeAmount,
    $core.double? profitTargetPercentage,
    $core.double? stopLossPercentage,
    $core.double? dcaDecrementPercentage,
    $core.int? maxOpenTrades,
    $core.bool? isTestMode,
    $core.bool? buyOnStart,
    $core.int? initialWarmupTicks,
    $core.String? initialWarmupSecondsStr,
    $core.String? initialSignalThresholdPctStr,
    $core.String? dcaCooldownSecondsStr,
    $core.String? dustRetryCooldownSecondsStr,
    $core.String? maxTradeAmountCapStr,
    $core.String? maxBuyOveragePctStr,
    $core.bool? strictBudget,
    $core.bool? buyOnStartRespectWarmup,
    $core.String? buyCooldownSecondsStr,
    $core.bool? dcaCompareAgainstAverage,
    $core.int? maxCycles,
    $core.String? tradeAmountStr,
    $core.String? profitTargetPercentageStr,
    $core.String? stopLossPercentageStr,
    $core.String? dcaDecrementPercentageStr,
    $core.bool? enableFeeAwareTrading,
    $core.String? fixedQuantityStr,
  }) {
    final result = create();
    if (tradeAmount != null) result.tradeAmount = tradeAmount;
    if (profitTargetPercentage != null)
      result.profitTargetPercentage = profitTargetPercentage;
    if (stopLossPercentage != null)
      result.stopLossPercentage = stopLossPercentage;
    if (dcaDecrementPercentage != null)
      result.dcaDecrementPercentage = dcaDecrementPercentage;
    if (maxOpenTrades != null) result.maxOpenTrades = maxOpenTrades;
    if (isTestMode != null) result.isTestMode = isTestMode;
    if (buyOnStart != null) result.buyOnStart = buyOnStart;
    if (initialWarmupTicks != null)
      result.initialWarmupTicks = initialWarmupTicks;
    if (initialWarmupSecondsStr != null)
      result.initialWarmupSecondsStr = initialWarmupSecondsStr;
    if (initialSignalThresholdPctStr != null)
      result.initialSignalThresholdPctStr = initialSignalThresholdPctStr;
    if (dcaCooldownSecondsStr != null)
      result.dcaCooldownSecondsStr = dcaCooldownSecondsStr;
    if (dustRetryCooldownSecondsStr != null)
      result.dustRetryCooldownSecondsStr = dustRetryCooldownSecondsStr;
    if (maxTradeAmountCapStr != null)
      result.maxTradeAmountCapStr = maxTradeAmountCapStr;
    if (maxBuyOveragePctStr != null)
      result.maxBuyOveragePctStr = maxBuyOveragePctStr;
    if (strictBudget != null) result.strictBudget = strictBudget;
    if (buyOnStartRespectWarmup != null)
      result.buyOnStartRespectWarmup = buyOnStartRespectWarmup;
    if (buyCooldownSecondsStr != null)
      result.buyCooldownSecondsStr = buyCooldownSecondsStr;
    if (dcaCompareAgainstAverage != null)
      result.dcaCompareAgainstAverage = dcaCompareAgainstAverage;
    if (maxCycles != null) result.maxCycles = maxCycles;
    if (tradeAmountStr != null) result.tradeAmountStr = tradeAmountStr;
    if (profitTargetPercentageStr != null)
      result.profitTargetPercentageStr = profitTargetPercentageStr;
    if (stopLossPercentageStr != null)
      result.stopLossPercentageStr = stopLossPercentageStr;
    if (dcaDecrementPercentageStr != null)
      result.dcaDecrementPercentageStr = dcaDecrementPercentageStr;
    if (enableFeeAwareTrading != null)
      result.enableFeeAwareTrading = enableFeeAwareTrading;
    if (fixedQuantityStr != null) result.fixedQuantityStr = fixedQuantityStr;
    return result;
  }

  Settings._();

  factory Settings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Settings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Settings',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'tradeAmount', protoName: 'tradeAmount')
    ..aD(2, _omitFieldNames ? '' : 'profitTargetPercentage',
        protoName: 'profitTargetPercentage')
    ..aD(3, _omitFieldNames ? '' : 'stopLossPercentage',
        protoName: 'stopLossPercentage')
    ..aD(4, _omitFieldNames ? '' : 'dcaDecrementPercentage',
        protoName: 'dcaDecrementPercentage')
    ..aI(5, _omitFieldNames ? '' : 'maxOpenTrades', protoName: 'maxOpenTrades')
    ..aOB(6, _omitFieldNames ? '' : 'isTestMode', protoName: 'isTestMode')
    ..aOB(7, _omitFieldNames ? '' : 'buyOnStart', protoName: 'buyOnStart')
    ..aI(8, _omitFieldNames ? '' : 'initialWarmupTicks',
        protoName: 'initialWarmupTicks')
    ..aOS(9, _omitFieldNames ? '' : 'initialWarmupSecondsStr',
        protoName: 'initialWarmupSecondsStr')
    ..aOS(10, _omitFieldNames ? '' : 'initialSignalThresholdPctStr',
        protoName: 'initialSignalThresholdPctStr')
    ..aOS(11, _omitFieldNames ? '' : 'dcaCooldownSecondsStr',
        protoName: 'dcaCooldownSecondsStr')
    ..aOS(12, _omitFieldNames ? '' : 'dustRetryCooldownSecondsStr',
        protoName: 'dustRetryCooldownSecondsStr')
    ..aOS(13, _omitFieldNames ? '' : 'maxTradeAmountCapStr',
        protoName: 'maxTradeAmountCapStr')
    ..aOS(14, _omitFieldNames ? '' : 'maxBuyOveragePctStr',
        protoName: 'maxBuyOveragePctStr')
    ..aOB(15, _omitFieldNames ? '' : 'strictBudget', protoName: 'strictBudget')
    ..aOB(16, _omitFieldNames ? '' : 'buyOnStartRespectWarmup',
        protoName: 'buyOnStartRespectWarmup')
    ..aOS(17, _omitFieldNames ? '' : 'buyCooldownSecondsStr',
        protoName: 'buyCooldownSecondsStr')
    ..aOB(18, _omitFieldNames ? '' : 'dcaCompareAgainstAverage',
        protoName: 'dcaCompareAgainstAverage')
    ..aI(20, _omitFieldNames ? '' : 'maxCycles', protoName: 'maxCycles')
    ..aOS(21, _omitFieldNames ? '' : 'tradeAmountStr',
        protoName: 'tradeAmountStr')
    ..aOS(22, _omitFieldNames ? '' : 'profitTargetPercentageStr',
        protoName: 'profitTargetPercentageStr')
    ..aOS(23, _omitFieldNames ? '' : 'stopLossPercentageStr',
        protoName: 'stopLossPercentageStr')
    ..aOS(24, _omitFieldNames ? '' : 'dcaDecrementPercentageStr',
        protoName: 'dcaDecrementPercentageStr')
    ..aOB(25, _omitFieldNames ? '' : 'enableFeeAwareTrading',
        protoName: 'enableFeeAwareTrading')
    ..aOS(26, _omitFieldNames ? '' : 'fixedQuantityStr',
        protoName: 'fixedQuantityStr')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Settings clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Settings copyWith(void Function(Settings) updates) =>
      super.copyWith((message) => updates(message as Settings)) as Settings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Settings create() => Settings._();
  @$core.override
  Settings createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Settings getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Settings>(create);
  static Settings? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get tradeAmount => $_getN(0);
  @$pb.TagNumber(1)
  set tradeAmount($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTradeAmount() => $_has(0);
  @$pb.TagNumber(1)
  void clearTradeAmount() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get profitTargetPercentage => $_getN(1);
  @$pb.TagNumber(2)
  set profitTargetPercentage($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProfitTargetPercentage() => $_has(1);
  @$pb.TagNumber(2)
  void clearProfitTargetPercentage() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get stopLossPercentage => $_getN(2);
  @$pb.TagNumber(3)
  set stopLossPercentage($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStopLossPercentage() => $_has(2);
  @$pb.TagNumber(3)
  void clearStopLossPercentage() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get dcaDecrementPercentage => $_getN(3);
  @$pb.TagNumber(4)
  set dcaDecrementPercentage($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDcaDecrementPercentage() => $_has(3);
  @$pb.TagNumber(4)
  void clearDcaDecrementPercentage() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get maxOpenTrades => $_getIZ(4);
  @$pb.TagNumber(5)
  set maxOpenTrades($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMaxOpenTrades() => $_has(4);
  @$pb.TagNumber(5)
  void clearMaxOpenTrades() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get isTestMode => $_getBF(5);
  @$pb.TagNumber(6)
  set isTestMode($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIsTestMode() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsTestMode() => $_clearField(6);

  /// --- Nuove impostazioni avvio strategia ---
  @$pb.TagNumber(7)
  $core.bool get buyOnStart => $_getBF(6);
  @$pb.TagNumber(7)
  set buyOnStart($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBuyOnStart() => $_has(6);
  @$pb.TagNumber(7)
  void clearBuyOnStart() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get initialWarmupTicks => $_getIZ(7);
  @$pb.TagNumber(8)
  set initialWarmupTicks($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasInitialWarmupTicks() => $_has(7);
  @$pb.TagNumber(8)
  void clearInitialWarmupTicks() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get initialWarmupSecondsStr => $_getSZ(8);
  @$pb.TagNumber(9)
  set initialWarmupSecondsStr($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasInitialWarmupSecondsStr() => $_has(8);
  @$pb.TagNumber(9)
  void clearInitialWarmupSecondsStr() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get initialSignalThresholdPctStr => $_getSZ(9);
  @$pb.TagNumber(10)
  set initialSignalThresholdPctStr($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasInitialSignalThresholdPctStr() => $_has(9);
  @$pb.TagNumber(10)
  void clearInitialSignalThresholdPctStr() => $_clearField(10);

  /// --- Nuovi parametri di robustezza/controllo rischio ---
  @$pb.TagNumber(11)
  $core.String get dcaCooldownSecondsStr => $_getSZ(10);
  @$pb.TagNumber(11)
  set dcaCooldownSecondsStr($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasDcaCooldownSecondsStr() => $_has(10);
  @$pb.TagNumber(11)
  void clearDcaCooldownSecondsStr() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get dustRetryCooldownSecondsStr => $_getSZ(11);
  @$pb.TagNumber(12)
  set dustRetryCooldownSecondsStr($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasDustRetryCooldownSecondsStr() => $_has(11);
  @$pb.TagNumber(12)
  void clearDustRetryCooldownSecondsStr() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get maxTradeAmountCapStr => $_getSZ(12);
  @$pb.TagNumber(13)
  set maxTradeAmountCapStr($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasMaxTradeAmountCapStr() => $_has(12);
  @$pb.TagNumber(13)
  void clearMaxTradeAmountCapStr() => $_clearField(13);

  /// --- Estensioni ---
  @$pb.TagNumber(14)
  $core.String get maxBuyOveragePctStr => $_getSZ(13);
  @$pb.TagNumber(14)
  set maxBuyOveragePctStr($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasMaxBuyOveragePctStr() => $_has(13);
  @$pb.TagNumber(14)
  void clearMaxBuyOveragePctStr() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.bool get strictBudget => $_getBF(14);
  @$pb.TagNumber(15)
  set strictBudget($core.bool value) => $_setBool(14, value);
  @$pb.TagNumber(15)
  $core.bool hasStrictBudget() => $_has(14);
  @$pb.TagNumber(15)
  void clearStrictBudget() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.bool get buyOnStartRespectWarmup => $_getBF(15);
  @$pb.TagNumber(16)
  set buyOnStartRespectWarmup($core.bool value) => $_setBool(15, value);
  @$pb.TagNumber(16)
  $core.bool hasBuyOnStartRespectWarmup() => $_has(15);
  @$pb.TagNumber(16)
  void clearBuyOnStartRespectWarmup() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.String get buyCooldownSecondsStr => $_getSZ(16);
  @$pb.TagNumber(17)
  set buyCooldownSecondsStr($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasBuyCooldownSecondsStr() => $_has(16);
  @$pb.TagNumber(17)
  void clearBuyCooldownSecondsStr() => $_clearField(17);

  /// --- Nuovi parametri strategia ---
  @$pb.TagNumber(18)
  $core.bool get dcaCompareAgainstAverage => $_getBF(17);
  @$pb.TagNumber(18)
  set dcaCompareAgainstAverage($core.bool value) => $_setBool(17, value);
  @$pb.TagNumber(18)
  $core.bool hasDcaCompareAgainstAverage() => $_has(17);
  @$pb.TagNumber(18)
  void clearDcaCompareAgainstAverage() => $_clearField(18);

  /// --- Esecuzione (nuovo) ---
  @$pb.TagNumber(20)
  $core.int get maxCycles => $_getIZ(18);
  @$pb.TagNumber(20)
  set maxCycles($core.int value) => $_setSignedInt32(18, value);
  @$pb.TagNumber(20)
  $core.bool hasMaxCycles() => $_has(18);
  @$pb.TagNumber(20)
  void clearMaxCycles() => $_clearField(20);

  /// Nuovi campi string per importi/percentuali principali
  @$pb.TagNumber(21)
  $core.String get tradeAmountStr => $_getSZ(19);
  @$pb.TagNumber(21)
  set tradeAmountStr($core.String value) => $_setString(19, value);
  @$pb.TagNumber(21)
  $core.bool hasTradeAmountStr() => $_has(19);
  @$pb.TagNumber(21)
  void clearTradeAmountStr() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.String get profitTargetPercentageStr => $_getSZ(20);
  @$pb.TagNumber(22)
  set profitTargetPercentageStr($core.String value) => $_setString(20, value);
  @$pb.TagNumber(22)
  $core.bool hasProfitTargetPercentageStr() => $_has(20);
  @$pb.TagNumber(22)
  void clearProfitTargetPercentageStr() => $_clearField(22);

  @$pb.TagNumber(23)
  $core.String get stopLossPercentageStr => $_getSZ(21);
  @$pb.TagNumber(23)
  set stopLossPercentageStr($core.String value) => $_setString(21, value);
  @$pb.TagNumber(23)
  $core.bool hasStopLossPercentageStr() => $_has(21);
  @$pb.TagNumber(23)
  void clearStopLossPercentageStr() => $_clearField(23);

  @$pb.TagNumber(24)
  $core.String get dcaDecrementPercentageStr => $_getSZ(22);
  @$pb.TagNumber(24)
  set dcaDecrementPercentageStr($core.String value) => $_setString(22, value);
  @$pb.TagNumber(24)
  $core.bool hasDcaDecrementPercentageStr() => $_has(22);
  @$pb.TagNumber(24)
  void clearDcaDecrementPercentageStr() => $_clearField(24);

  /// --- Trading con Fee Consapevoli ---
  @$pb.TagNumber(25)
  $core.bool get enableFeeAwareTrading => $_getBF(23);
  @$pb.TagNumber(25)
  set enableFeeAwareTrading($core.bool value) => $_setBool(23, value);
  @$pb.TagNumber(25)
  $core.bool hasEnableFeeAwareTrading() => $_has(23);
  @$pb.TagNumber(25)
  void clearEnableFeeAwareTrading() => $_clearField(25);

  @$pb.TagNumber(26)
  $core.String get fixedQuantityStr => $_getSZ(24);
  @$pb.TagNumber(26)
  set fixedQuantityStr($core.String value) => $_setString(24, value);
  @$pb.TagNumber(26)
  $core.bool hasFixedQuantityStr() => $_has(24);
  @$pb.TagNumber(26)
  void clearFixedQuantityStr() => $_clearField(26);
}

class StartStrategyRequest extends $pb.GeneratedMessage {
  factory StartStrategyRequest({
    $core.String? symbol,
  }) {
    final result = create();
    if (symbol != null) result.symbol = symbol;
    return result;
  }

  StartStrategyRequest._();

  factory StartStrategyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartStrategyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartStrategyRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'symbol')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartStrategyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartStrategyRequest copyWith(void Function(StartStrategyRequest) updates) =>
      super.copyWith((message) => updates(message as StartStrategyRequest))
          as StartStrategyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartStrategyRequest create() => StartStrategyRequest._();
  @$core.override
  StartStrategyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartStrategyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartStrategyRequest>(create);
  static StartStrategyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get symbol => $_getSZ(0);
  @$pb.TagNumber(1)
  set symbol($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSymbol() => $_has(0);
  @$pb.TagNumber(1)
  void clearSymbol() => $_clearField(1);
}

class StopStrategyRequest extends $pb.GeneratedMessage {
  factory StopStrategyRequest({
    $core.String? symbol,
  }) {
    final result = create();
    if (symbol != null) result.symbol = symbol;
    return result;
  }

  StopStrategyRequest._();

  factory StopStrategyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StopStrategyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StopStrategyRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'symbol')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopStrategyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopStrategyRequest copyWith(void Function(StopStrategyRequest) updates) =>
      super.copyWith((message) => updates(message as StopStrategyRequest))
          as StopStrategyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StopStrategyRequest create() => StopStrategyRequest._();
  @$core.override
  StopStrategyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StopStrategyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StopStrategyRequest>(create);
  static StopStrategyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get symbol => $_getSZ(0);
  @$pb.TagNumber(1)
  set symbol($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSymbol() => $_has(0);
  @$pb.TagNumber(1)
  void clearSymbol() => $_clearField(1);
}

class PauseTradingRequest extends $pb.GeneratedMessage {
  factory PauseTradingRequest({
    $core.String? symbol,
  }) {
    final result = create();
    if (symbol != null) result.symbol = symbol;
    return result;
  }

  PauseTradingRequest._();

  factory PauseTradingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PauseTradingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PauseTradingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'symbol')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PauseTradingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PauseTradingRequest copyWith(void Function(PauseTradingRequest) updates) =>
      super.copyWith((message) => updates(message as PauseTradingRequest))
          as PauseTradingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PauseTradingRequest create() => PauseTradingRequest._();
  @$core.override
  PauseTradingRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PauseTradingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PauseTradingRequest>(create);
  static PauseTradingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get symbol => $_getSZ(0);
  @$pb.TagNumber(1)
  set symbol($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSymbol() => $_has(0);
  @$pb.TagNumber(1)
  void clearSymbol() => $_clearField(1);
}

class ResumeTradingRequest extends $pb.GeneratedMessage {
  factory ResumeTradingRequest({
    $core.String? symbol,
  }) {
    final result = create();
    if (symbol != null) result.symbol = symbol;
    return result;
  }

  ResumeTradingRequest._();

  factory ResumeTradingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResumeTradingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResumeTradingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'symbol')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResumeTradingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResumeTradingRequest copyWith(void Function(ResumeTradingRequest) updates) =>
      super.copyWith((message) => updates(message as ResumeTradingRequest))
          as ResumeTradingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResumeTradingRequest create() => ResumeTradingRequest._();
  @$core.override
  ResumeTradingRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResumeTradingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResumeTradingRequest>(create);
  static ResumeTradingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get symbol => $_getSZ(0);
  @$pb.TagNumber(1)
  set symbol($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSymbol() => $_has(0);
  @$pb.TagNumber(1)
  void clearSymbol() => $_clearField(1);
}

class StrategyResponse extends $pb.GeneratedMessage {
  factory StrategyResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  StrategyResponse._();

  factory StrategyResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StrategyResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StrategyResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StrategyResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StrategyResponse copyWith(void Function(StrategyResponse) updates) =>
      super.copyWith((message) => updates(message as StrategyResponse))
          as StrategyResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StrategyResponse create() => StrategyResponse._();
  @$core.override
  StrategyResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StrategyResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StrategyResponse>(create);
  static StrategyResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class GetStrategyStateRequest extends $pb.GeneratedMessage {
  factory GetStrategyStateRequest({
    $core.String? symbol,
  }) {
    final result = create();
    if (symbol != null) result.symbol = symbol;
    return result;
  }

  GetStrategyStateRequest._();

  factory GetStrategyStateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetStrategyStateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStrategyStateRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'symbol')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStrategyStateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStrategyStateRequest copyWith(
          void Function(GetStrategyStateRequest) updates) =>
      super.copyWith((message) => updates(message as GetStrategyStateRequest))
          as GetStrategyStateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetStrategyStateRequest create() => GetStrategyStateRequest._();
  @$core.override
  GetStrategyStateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetStrategyStateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetStrategyStateRequest>(create);
  static GetStrategyStateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get symbol => $_getSZ(0);
  @$pb.TagNumber(1)
  set symbol($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSymbol() => $_has(0);
  @$pb.TagNumber(1)
  void clearSymbol() => $_clearField(1);
}

class StrategyStateResponse extends $pb.GeneratedMessage {
  factory StrategyStateResponse({
    $core.String? symbol,
    StrategyStatus? status,
    $core.int? openTradesCount,
    $core.double? averagePrice,
    $core.double? totalQuantity,
    $core.double? lastBuyPrice,
    $core.int? currentRoundId,
    $core.double? cumulativeProfit,
    $core.int? successfulRounds,
    $core.int? failedRounds,
    $core.String? warningMessage,
    $core.Iterable<$core.String>? warnings,
    $core.String? averagePriceStr,
    $core.String? totalQuantityStr,
    $core.String? lastBuyPriceStr,
    $core.String? cumulativeProfitStr,
  }) {
    final result = create();
    if (symbol != null) result.symbol = symbol;
    if (status != null) result.status = status;
    if (openTradesCount != null) result.openTradesCount = openTradesCount;
    if (averagePrice != null) result.averagePrice = averagePrice;
    if (totalQuantity != null) result.totalQuantity = totalQuantity;
    if (lastBuyPrice != null) result.lastBuyPrice = lastBuyPrice;
    if (currentRoundId != null) result.currentRoundId = currentRoundId;
    if (cumulativeProfit != null) result.cumulativeProfit = cumulativeProfit;
    if (successfulRounds != null) result.successfulRounds = successfulRounds;
    if (failedRounds != null) result.failedRounds = failedRounds;
    if (warningMessage != null) result.warningMessage = warningMessage;
    if (warnings != null) result.warnings.addAll(warnings);
    if (averagePriceStr != null) result.averagePriceStr = averagePriceStr;
    if (totalQuantityStr != null) result.totalQuantityStr = totalQuantityStr;
    if (lastBuyPriceStr != null) result.lastBuyPriceStr = lastBuyPriceStr;
    if (cumulativeProfitStr != null)
      result.cumulativeProfitStr = cumulativeProfitStr;
    return result;
  }

  StrategyStateResponse._();

  factory StrategyStateResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StrategyStateResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StrategyStateResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'symbol')
    ..aE<StrategyStatus>(2, _omitFieldNames ? '' : 'status',
        enumValues: StrategyStatus.values)
    ..aI(3, _omitFieldNames ? '' : 'openTradesCount',
        protoName: 'openTradesCount')
    ..aD(4, _omitFieldNames ? '' : 'averagePrice', protoName: 'averagePrice')
    ..aD(5, _omitFieldNames ? '' : 'totalQuantity', protoName: 'totalQuantity')
    ..aD(6, _omitFieldNames ? '' : 'lastBuyPrice', protoName: 'lastBuyPrice')
    ..aI(7, _omitFieldNames ? '' : 'currentRoundId',
        protoName: 'currentRoundId')
    ..aD(8, _omitFieldNames ? '' : 'cumulativeProfit',
        protoName: 'cumulativeProfit')
    ..aI(9, _omitFieldNames ? '' : 'successfulRounds',
        protoName: 'successfulRounds')
    ..aI(10, _omitFieldNames ? '' : 'failedRounds', protoName: 'failedRounds')
    ..aOS(11, _omitFieldNames ? '' : 'warningMessage',
        protoName: 'warningMessage')
    ..pPS(12, _omitFieldNames ? '' : 'warnings')
    ..aOS(13, _omitFieldNames ? '' : 'averagePriceStr',
        protoName: 'averagePriceStr')
    ..aOS(14, _omitFieldNames ? '' : 'totalQuantityStr',
        protoName: 'totalQuantityStr')
    ..aOS(15, _omitFieldNames ? '' : 'lastBuyPriceStr',
        protoName: 'lastBuyPriceStr')
    ..aOS(16, _omitFieldNames ? '' : 'cumulativeProfitStr',
        protoName: 'cumulativeProfitStr')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StrategyStateResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StrategyStateResponse copyWith(
          void Function(StrategyStateResponse) updates) =>
      super.copyWith((message) => updates(message as StrategyStateResponse))
          as StrategyStateResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StrategyStateResponse create() => StrategyStateResponse._();
  @$core.override
  StrategyStateResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StrategyStateResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StrategyStateResponse>(create);
  static StrategyStateResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get symbol => $_getSZ(0);
  @$pb.TagNumber(1)
  set symbol($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSymbol() => $_has(0);
  @$pb.TagNumber(1)
  void clearSymbol() => $_clearField(1);

  @$pb.TagNumber(2)
  StrategyStatus get status => $_getN(1);
  @$pb.TagNumber(2)
  set status(StrategyStatus value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get openTradesCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set openTradesCount($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOpenTradesCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearOpenTradesCount() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get averagePrice => $_getN(3);
  @$pb.TagNumber(4)
  set averagePrice($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAveragePrice() => $_has(3);
  @$pb.TagNumber(4)
  void clearAveragePrice() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get totalQuantity => $_getN(4);
  @$pb.TagNumber(5)
  set totalQuantity($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTotalQuantity() => $_has(4);
  @$pb.TagNumber(5)
  void clearTotalQuantity() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get lastBuyPrice => $_getN(5);
  @$pb.TagNumber(6)
  set lastBuyPrice($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLastBuyPrice() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastBuyPrice() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get currentRoundId => $_getIZ(6);
  @$pb.TagNumber(7)
  set currentRoundId($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCurrentRoundId() => $_has(6);
  @$pb.TagNumber(7)
  void clearCurrentRoundId() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get cumulativeProfit => $_getN(7);
  @$pb.TagNumber(8)
  set cumulativeProfit($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCumulativeProfit() => $_has(7);
  @$pb.TagNumber(8)
  void clearCumulativeProfit() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get successfulRounds => $_getIZ(8);
  @$pb.TagNumber(9)
  set successfulRounds($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasSuccessfulRounds() => $_has(8);
  @$pb.TagNumber(9)
  void clearSuccessfulRounds() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get failedRounds => $_getIZ(9);
  @$pb.TagNumber(10)
  set failedRounds($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasFailedRounds() => $_has(9);
  @$pb.TagNumber(10)
  void clearFailedRounds() => $_clearField(10);

  /// Campo opzionale per comunicare warning operativi non fatali (es. dust SELL)
  @$pb.TagNumber(11)
  $core.String get warningMessage => $_getSZ(10);
  @$pb.TagNumber(11)
  set warningMessage($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasWarningMessage() => $_has(10);
  @$pb.TagNumber(11)
  void clearWarningMessage() => $_clearField(11);

  /// Warnings strutturati (es. RECOVERING;, SETTINGS_CLAMP, BUY_OVERAGE_APPLIED)
  @$pb.TagNumber(12)
  $pb.PbList<$core.String> get warnings => $_getList(11);

  /// Nuovi campi string per piena precisione
  @$pb.TagNumber(13)
  $core.String get averagePriceStr => $_getSZ(12);
  @$pb.TagNumber(13)
  set averagePriceStr($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasAveragePriceStr() => $_has(12);
  @$pb.TagNumber(13)
  void clearAveragePriceStr() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get totalQuantityStr => $_getSZ(13);
  @$pb.TagNumber(14)
  set totalQuantityStr($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasTotalQuantityStr() => $_has(13);
  @$pb.TagNumber(14)
  void clearTotalQuantityStr() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get lastBuyPriceStr => $_getSZ(14);
  @$pb.TagNumber(15)
  set lastBuyPriceStr($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasLastBuyPriceStr() => $_has(14);
  @$pb.TagNumber(15)
  void clearLastBuyPriceStr() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get cumulativeProfitStr => $_getSZ(15);
  @$pb.TagNumber(16)
  set cumulativeProfitStr($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasCumulativeProfitStr() => $_has(15);
  @$pb.TagNumber(16)
  void clearCumulativeProfitStr() => $_clearField(16);
}

class GetTradeHistoryRequest extends $pb.GeneratedMessage {
  factory GetTradeHistoryRequest() => create();

  GetTradeHistoryRequest._();

  factory GetTradeHistoryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetTradeHistoryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetTradeHistoryRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTradeHistoryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTradeHistoryRequest copyWith(
          void Function(GetTradeHistoryRequest) updates) =>
      super.copyWith((message) => updates(message as GetTradeHistoryRequest))
          as GetTradeHistoryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetTradeHistoryRequest create() => GetTradeHistoryRequest._();
  @$core.override
  GetTradeHistoryRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetTradeHistoryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetTradeHistoryRequest>(create);
  static GetTradeHistoryRequest? _defaultInstance;
}

class TradeHistoryResponse extends $pb.GeneratedMessage {
  factory TradeHistoryResponse({
    $core.Iterable<Trade>? trades,
  }) {
    final result = create();
    if (trades != null) result.trades.addAll(trades);
    return result;
  }

  TradeHistoryResponse._();

  factory TradeHistoryResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TradeHistoryResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TradeHistoryResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..pPM<Trade>(1, _omitFieldNames ? '' : 'trades', subBuilder: Trade.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TradeHistoryResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TradeHistoryResponse copyWith(void Function(TradeHistoryResponse) updates) =>
      super.copyWith((message) => updates(message as TradeHistoryResponse))
          as TradeHistoryResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TradeHistoryResponse create() => TradeHistoryResponse._();
  @$core.override
  TradeHistoryResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TradeHistoryResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TradeHistoryResponse>(create);
  static TradeHistoryResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Trade> get trades => $_getList(0);
}

class Trade extends $pb.GeneratedMessage {
  factory Trade({
    $core.String? symbol,
    $core.double? price,
    $core.double? quantity,
    $core.bool? isBuy,
    $fixnum.Int64? timestamp,
    $core.String? orderStatus,
    $core.double? profit,
    $core.String? priceStr,
    $core.String? quantityStr,
    $core.String? profitStr,
  }) {
    final result = create();
    if (symbol != null) result.symbol = symbol;
    if (price != null) result.price = price;
    if (quantity != null) result.quantity = quantity;
    if (isBuy != null) result.isBuy = isBuy;
    if (timestamp != null) result.timestamp = timestamp;
    if (orderStatus != null) result.orderStatus = orderStatus;
    if (profit != null) result.profit = profit;
    if (priceStr != null) result.priceStr = priceStr;
    if (quantityStr != null) result.quantityStr = quantityStr;
    if (profitStr != null) result.profitStr = profitStr;
    return result;
  }

  Trade._();

  factory Trade.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Trade.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Trade',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'symbol')
    ..aD(2, _omitFieldNames ? '' : 'price')
    ..aD(3, _omitFieldNames ? '' : 'quantity')
    ..aOB(4, _omitFieldNames ? '' : 'isBuy', protoName: 'isBuy')
    ..aInt64(5, _omitFieldNames ? '' : 'timestamp')
    ..aOS(6, _omitFieldNames ? '' : 'orderStatus', protoName: 'orderStatus')
    ..aD(7, _omitFieldNames ? '' : 'profit')
    ..aOS(8, _omitFieldNames ? '' : 'priceStr', protoName: 'priceStr')
    ..aOS(9, _omitFieldNames ? '' : 'quantityStr', protoName: 'quantityStr')
    ..aOS(10, _omitFieldNames ? '' : 'profitStr', protoName: 'profitStr')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Trade clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Trade copyWith(void Function(Trade) updates) =>
      super.copyWith((message) => updates(message as Trade)) as Trade;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Trade create() => Trade._();
  @$core.override
  Trade createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Trade getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Trade>(create);
  static Trade? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get symbol => $_getSZ(0);
  @$pb.TagNumber(1)
  set symbol($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSymbol() => $_has(0);
  @$pb.TagNumber(1)
  void clearSymbol() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get price => $_getN(1);
  @$pb.TagNumber(2)
  set price($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPrice() => $_has(1);
  @$pb.TagNumber(2)
  void clearPrice() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get quantity => $_getN(2);
  @$pb.TagNumber(3)
  set quantity($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasQuantity() => $_has(2);
  @$pb.TagNumber(3)
  void clearQuantity() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isBuy => $_getBF(3);
  @$pb.TagNumber(4)
  set isBuy($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsBuy() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsBuy() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get timestamp => $_getI64(4);
  @$pb.TagNumber(5)
  set timestamp($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTimestamp() => $_has(4);
  @$pb.TagNumber(5)
  void clearTimestamp() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get orderStatus => $_getSZ(5);
  @$pb.TagNumber(6)
  set orderStatus($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOrderStatus() => $_has(5);
  @$pb.TagNumber(6)
  void clearOrderStatus() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get profit => $_getN(6);
  @$pb.TagNumber(7)
  set profit($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasProfit() => $_has(6);
  @$pb.TagNumber(7)
  void clearProfit() => $_clearField(7);

  /// Nuovi campi string
  @$pb.TagNumber(8)
  $core.String get priceStr => $_getSZ(7);
  @$pb.TagNumber(8)
  set priceStr($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPriceStr() => $_has(7);
  @$pb.TagNumber(8)
  void clearPriceStr() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get quantityStr => $_getSZ(8);
  @$pb.TagNumber(9)
  set quantityStr($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasQuantityStr() => $_has(8);
  @$pb.TagNumber(9)
  void clearQuantityStr() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get profitStr => $_getSZ(9);
  @$pb.TagNumber(10)
  set profitStr($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasProfitStr() => $_has(9);
  @$pb.TagNumber(10)
  void clearProfitStr() => $_clearField(10);
}

class SymbolLimitsRequest extends $pb.GeneratedMessage {
  factory SymbolLimitsRequest({
    $core.String? symbol,
  }) {
    final result = create();
    if (symbol != null) result.symbol = symbol;
    return result;
  }

  SymbolLimitsRequest._();

  factory SymbolLimitsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SymbolLimitsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SymbolLimitsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'symbol')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SymbolLimitsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SymbolLimitsRequest copyWith(void Function(SymbolLimitsRequest) updates) =>
      super.copyWith((message) => updates(message as SymbolLimitsRequest))
          as SymbolLimitsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SymbolLimitsRequest create() => SymbolLimitsRequest._();
  @$core.override
  SymbolLimitsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SymbolLimitsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SymbolLimitsRequest>(create);
  static SymbolLimitsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get symbol => $_getSZ(0);
  @$pb.TagNumber(1)
  set symbol($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSymbol() => $_has(0);
  @$pb.TagNumber(1)
  void clearSymbol() => $_clearField(1);
}

class SymbolLimitsResponse extends $pb.GeneratedMessage {
  factory SymbolLimitsResponse({
    $core.String? symbol,
    $core.double? minQty,
    $core.double? maxQty,
    $core.double? stepSize,
    $core.double? minNotional,
    $core.String? minQtyStr,
    $core.String? maxQtyStr,
    $core.String? stepSizeStr,
    $core.String? minNotionalStr,
    $core.double? makerFee,
    $core.double? takerFee,
    $core.String? feeCurrency,
    $core.bool? isDiscountActive,
    $core.double? discountPercentage,
    $fixnum.Int64? lastUpdated,
  }) {
    final result = create();
    if (symbol != null) result.symbol = symbol;
    if (minQty != null) result.minQty = minQty;
    if (maxQty != null) result.maxQty = maxQty;
    if (stepSize != null) result.stepSize = stepSize;
    if (minNotional != null) result.minNotional = minNotional;
    if (minQtyStr != null) result.minQtyStr = minQtyStr;
    if (maxQtyStr != null) result.maxQtyStr = maxQtyStr;
    if (stepSizeStr != null) result.stepSizeStr = stepSizeStr;
    if (minNotionalStr != null) result.minNotionalStr = minNotionalStr;
    if (makerFee != null) result.makerFee = makerFee;
    if (takerFee != null) result.takerFee = takerFee;
    if (feeCurrency != null) result.feeCurrency = feeCurrency;
    if (isDiscountActive != null) result.isDiscountActive = isDiscountActive;
    if (discountPercentage != null)
      result.discountPercentage = discountPercentage;
    if (lastUpdated != null) result.lastUpdated = lastUpdated;
    return result;
  }

  SymbolLimitsResponse._();

  factory SymbolLimitsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SymbolLimitsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SymbolLimitsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'symbol')
    ..aD(2, _omitFieldNames ? '' : 'minQty', protoName: 'minQty')
    ..aD(3, _omitFieldNames ? '' : 'maxQty', protoName: 'maxQty')
    ..aD(4, _omitFieldNames ? '' : 'stepSize', protoName: 'stepSize')
    ..aD(5, _omitFieldNames ? '' : 'minNotional', protoName: 'minNotional')
    ..aOS(6, _omitFieldNames ? '' : 'minQtyStr', protoName: 'minQtyStr')
    ..aOS(7, _omitFieldNames ? '' : 'maxQtyStr', protoName: 'maxQtyStr')
    ..aOS(8, _omitFieldNames ? '' : 'stepSizeStr', protoName: 'stepSizeStr')
    ..aOS(9, _omitFieldNames ? '' : 'minNotionalStr',
        protoName: 'minNotionalStr')
    ..aD(10, _omitFieldNames ? '' : 'makerFee', protoName: 'makerFee')
    ..aD(11, _omitFieldNames ? '' : 'takerFee', protoName: 'takerFee')
    ..aOS(12, _omitFieldNames ? '' : 'feeCurrency', protoName: 'feeCurrency')
    ..aOB(13, _omitFieldNames ? '' : 'isDiscountActive',
        protoName: 'isDiscountActive')
    ..aD(14, _omitFieldNames ? '' : 'discountPercentage',
        protoName: 'discountPercentage')
    ..aInt64(15, _omitFieldNames ? '' : 'lastUpdated', protoName: 'lastUpdated')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SymbolLimitsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SymbolLimitsResponse copyWith(void Function(SymbolLimitsResponse) updates) =>
      super.copyWith((message) => updates(message as SymbolLimitsResponse))
          as SymbolLimitsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SymbolLimitsResponse create() => SymbolLimitsResponse._();
  @$core.override
  SymbolLimitsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SymbolLimitsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SymbolLimitsResponse>(create);
  static SymbolLimitsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get symbol => $_getSZ(0);
  @$pb.TagNumber(1)
  set symbol($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSymbol() => $_has(0);
  @$pb.TagNumber(1)
  void clearSymbol() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get minQty => $_getN(1);
  @$pb.TagNumber(2)
  set minQty($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMinQty() => $_has(1);
  @$pb.TagNumber(2)
  void clearMinQty() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get maxQty => $_getN(2);
  @$pb.TagNumber(3)
  set maxQty($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxQty() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxQty() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get stepSize => $_getN(3);
  @$pb.TagNumber(4)
  set stepSize($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStepSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearStepSize() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get minNotional => $_getN(4);
  @$pb.TagNumber(5)
  set minNotional($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMinNotional() => $_has(4);
  @$pb.TagNumber(5)
  void clearMinNotional() => $_clearField(5);

  /// Nuovi campi string
  @$pb.TagNumber(6)
  $core.String get minQtyStr => $_getSZ(5);
  @$pb.TagNumber(6)
  set minQtyStr($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMinQtyStr() => $_has(5);
  @$pb.TagNumber(6)
  void clearMinQtyStr() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get maxQtyStr => $_getSZ(6);
  @$pb.TagNumber(7)
  set maxQtyStr($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMaxQtyStr() => $_has(6);
  @$pb.TagNumber(7)
  void clearMaxQtyStr() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get stepSizeStr => $_getSZ(7);
  @$pb.TagNumber(8)
  set stepSizeStr($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasStepSizeStr() => $_has(7);
  @$pb.TagNumber(8)
  void clearStepSizeStr() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get minNotionalStr => $_getSZ(8);
  @$pb.TagNumber(9)
  set minNotionalStr($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasMinNotionalStr() => $_has(8);
  @$pb.TagNumber(9)
  void clearMinNotionalStr() => $_clearField(9);

  /// NUOVI CAMPI PER FEE
  @$pb.TagNumber(10)
  $core.double get makerFee => $_getN(9);
  @$pb.TagNumber(10)
  set makerFee($core.double value) => $_setDouble(9, value);
  @$pb.TagNumber(10)
  $core.bool hasMakerFee() => $_has(9);
  @$pb.TagNumber(10)
  void clearMakerFee() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.double get takerFee => $_getN(10);
  @$pb.TagNumber(11)
  set takerFee($core.double value) => $_setDouble(10, value);
  @$pb.TagNumber(11)
  $core.bool hasTakerFee() => $_has(10);
  @$pb.TagNumber(11)
  void clearTakerFee() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get feeCurrency => $_getSZ(11);
  @$pb.TagNumber(12)
  set feeCurrency($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasFeeCurrency() => $_has(11);
  @$pb.TagNumber(12)
  void clearFeeCurrency() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.bool get isDiscountActive => $_getBF(12);
  @$pb.TagNumber(13)
  set isDiscountActive($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasIsDiscountActive() => $_has(12);
  @$pb.TagNumber(13)
  void clearIsDiscountActive() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.double get discountPercentage => $_getN(13);
  @$pb.TagNumber(14)
  set discountPercentage($core.double value) => $_setDouble(13, value);
  @$pb.TagNumber(14)
  $core.bool hasDiscountPercentage() => $_has(13);
  @$pb.TagNumber(14)
  void clearDiscountPercentage() => $_clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get lastUpdated => $_getI64(14);
  @$pb.TagNumber(15)
  set lastUpdated($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(15)
  $core.bool hasLastUpdated() => $_has(14);
  @$pb.TagNumber(15)
  void clearLastUpdated() => $_clearField(15);
}

class OpenOrdersRequest extends $pb.GeneratedMessage {
  factory OpenOrdersRequest({
    $core.String? symbol,
  }) {
    final result = create();
    if (symbol != null) result.symbol = symbol;
    return result;
  }

  OpenOrdersRequest._();

  factory OpenOrdersRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OpenOrdersRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OpenOrdersRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'symbol')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenOrdersRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenOrdersRequest copyWith(void Function(OpenOrdersRequest) updates) =>
      super.copyWith((message) => updates(message as OpenOrdersRequest))
          as OpenOrdersRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OpenOrdersRequest create() => OpenOrdersRequest._();
  @$core.override
  OpenOrdersRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OpenOrdersRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OpenOrdersRequest>(create);
  static OpenOrdersRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get symbol => $_getSZ(0);
  @$pb.TagNumber(1)
  set symbol($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSymbol() => $_has(0);
  @$pb.TagNumber(1)
  void clearSymbol() => $_clearField(1);
}

class OpenOrdersResponse extends $pb.GeneratedMessage {
  factory OpenOrdersResponse({
    $core.Iterable<OrderStatus>? orders,
  }) {
    final result = create();
    if (orders != null) result.orders.addAll(orders);
    return result;
  }

  OpenOrdersResponse._();

  factory OpenOrdersResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OpenOrdersResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OpenOrdersResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..pPM<OrderStatus>(1, _omitFieldNames ? '' : 'orders',
        subBuilder: OrderStatus.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenOrdersResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenOrdersResponse copyWith(void Function(OpenOrdersResponse) updates) =>
      super.copyWith((message) => updates(message as OpenOrdersResponse))
          as OpenOrdersResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OpenOrdersResponse create() => OpenOrdersResponse._();
  @$core.override
  OpenOrdersResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OpenOrdersResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OpenOrdersResponse>(create);
  static OpenOrdersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<OrderStatus> get orders => $_getList(0);
}

class OrderStatus extends $pb.GeneratedMessage {
  factory OrderStatus({
    $core.String? symbol,
    $fixnum.Int64? orderId,
    $core.String? clientOrderId,
    $core.double? price,
    $core.double? origQty,
    $core.double? executedQty,
    $core.String? status,
    $core.String? timeInForce,
    $core.String? type,
    $core.String? side,
    $fixnum.Int64? time,
    $core.String? priceStr,
    $core.String? origQtyStr,
    $core.String? executedQtyStr,
  }) {
    final result = create();
    if (symbol != null) result.symbol = symbol;
    if (orderId != null) result.orderId = orderId;
    if (clientOrderId != null) result.clientOrderId = clientOrderId;
    if (price != null) result.price = price;
    if (origQty != null) result.origQty = origQty;
    if (executedQty != null) result.executedQty = executedQty;
    if (status != null) result.status = status;
    if (timeInForce != null) result.timeInForce = timeInForce;
    if (type != null) result.type = type;
    if (side != null) result.side = side;
    if (time != null) result.time = time;
    if (priceStr != null) result.priceStr = priceStr;
    if (origQtyStr != null) result.origQtyStr = origQtyStr;
    if (executedQtyStr != null) result.executedQtyStr = executedQtyStr;
    return result;
  }

  OrderStatus._();

  factory OrderStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OrderStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OrderStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'symbol')
    ..aInt64(2, _omitFieldNames ? '' : 'orderId', protoName: 'orderId')
    ..aOS(3, _omitFieldNames ? '' : 'clientOrderId', protoName: 'clientOrderId')
    ..aD(4, _omitFieldNames ? '' : 'price')
    ..aD(5, _omitFieldNames ? '' : 'origQty', protoName: 'origQty')
    ..aD(6, _omitFieldNames ? '' : 'executedQty', protoName: 'executedQty')
    ..aOS(7, _omitFieldNames ? '' : 'status')
    ..aOS(8, _omitFieldNames ? '' : 'timeInForce', protoName: 'timeInForce')
    ..aOS(9, _omitFieldNames ? '' : 'type')
    ..aOS(10, _omitFieldNames ? '' : 'side')
    ..aInt64(11, _omitFieldNames ? '' : 'time')
    ..aOS(12, _omitFieldNames ? '' : 'priceStr', protoName: 'priceStr')
    ..aOS(13, _omitFieldNames ? '' : 'origQtyStr', protoName: 'origQtyStr')
    ..aOS(14, _omitFieldNames ? '' : 'executedQtyStr',
        protoName: 'executedQtyStr')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OrderStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OrderStatus copyWith(void Function(OrderStatus) updates) =>
      super.copyWith((message) => updates(message as OrderStatus))
          as OrderStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OrderStatus create() => OrderStatus._();
  @$core.override
  OrderStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OrderStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OrderStatus>(create);
  static OrderStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get symbol => $_getSZ(0);
  @$pb.TagNumber(1)
  set symbol($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSymbol() => $_has(0);
  @$pb.TagNumber(1)
  void clearSymbol() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get orderId => $_getI64(1);
  @$pb.TagNumber(2)
  set orderId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOrderId() => $_has(1);
  @$pb.TagNumber(2)
  void clearOrderId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get clientOrderId => $_getSZ(2);
  @$pb.TagNumber(3)
  set clientOrderId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClientOrderId() => $_has(2);
  @$pb.TagNumber(3)
  void clearClientOrderId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get price => $_getN(3);
  @$pb.TagNumber(4)
  set price($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPrice() => $_has(3);
  @$pb.TagNumber(4)
  void clearPrice() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get origQty => $_getN(4);
  @$pb.TagNumber(5)
  set origQty($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOrigQty() => $_has(4);
  @$pb.TagNumber(5)
  void clearOrigQty() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get executedQty => $_getN(5);
  @$pb.TagNumber(6)
  set executedQty($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasExecutedQty() => $_has(5);
  @$pb.TagNumber(6)
  void clearExecutedQty() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get status => $_getSZ(6);
  @$pb.TagNumber(7)
  set status($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasStatus() => $_has(6);
  @$pb.TagNumber(7)
  void clearStatus() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get timeInForce => $_getSZ(7);
  @$pb.TagNumber(8)
  set timeInForce($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTimeInForce() => $_has(7);
  @$pb.TagNumber(8)
  void clearTimeInForce() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get type => $_getSZ(8);
  @$pb.TagNumber(9)
  set type($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasType() => $_has(8);
  @$pb.TagNumber(9)
  void clearType() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get side => $_getSZ(9);
  @$pb.TagNumber(10)
  set side($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasSide() => $_has(9);
  @$pb.TagNumber(10)
  void clearSide() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get time => $_getI64(10);
  @$pb.TagNumber(11)
  set time($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasTime() => $_has(10);
  @$pb.TagNumber(11)
  void clearTime() => $_clearField(11);

  /// Precision fields
  @$pb.TagNumber(12)
  $core.String get priceStr => $_getSZ(11);
  @$pb.TagNumber(12)
  set priceStr($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasPriceStr() => $_has(11);
  @$pb.TagNumber(12)
  void clearPriceStr() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get origQtyStr => $_getSZ(12);
  @$pb.TagNumber(13)
  set origQtyStr($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasOrigQtyStr() => $_has(12);
  @$pb.TagNumber(13)
  void clearOrigQtyStr() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get executedQtyStr => $_getSZ(13);
  @$pb.TagNumber(14)
  set executedQtyStr($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasExecutedQtyStr() => $_has(13);
  @$pb.TagNumber(14)
  void clearExecutedQtyStr() => $_clearField(14);
}

class CancelOrderRequest extends $pb.GeneratedMessage {
  factory CancelOrderRequest({
    $core.String? symbol,
    $fixnum.Int64? orderId,
  }) {
    final result = create();
    if (symbol != null) result.symbol = symbol;
    if (orderId != null) result.orderId = orderId;
    return result;
  }

  CancelOrderRequest._();

  factory CancelOrderRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CancelOrderRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelOrderRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'symbol')
    ..aInt64(2, _omitFieldNames ? '' : 'orderId', protoName: 'orderId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelOrderRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelOrderRequest copyWith(void Function(CancelOrderRequest) updates) =>
      super.copyWith((message) => updates(message as CancelOrderRequest))
          as CancelOrderRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelOrderRequest create() => CancelOrderRequest._();
  @$core.override
  CancelOrderRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CancelOrderRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelOrderRequest>(create);
  static CancelOrderRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get symbol => $_getSZ(0);
  @$pb.TagNumber(1)
  set symbol($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSymbol() => $_has(0);
  @$pb.TagNumber(1)
  void clearSymbol() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get orderId => $_getI64(1);
  @$pb.TagNumber(2)
  set orderId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOrderId() => $_has(1);
  @$pb.TagNumber(2)
  void clearOrderId() => $_clearField(2);
}

class CancelOrderResponse extends $pb.GeneratedMessage {
  factory CancelOrderResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  CancelOrderResponse._();

  factory CancelOrderResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CancelOrderResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelOrderResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelOrderResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelOrderResponse copyWith(void Function(CancelOrderResponse) updates) =>
      super.copyWith((message) => updates(message as CancelOrderResponse))
          as CancelOrderResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelOrderResponse create() => CancelOrderResponse._();
  @$core.override
  CancelOrderResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CancelOrderResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelOrderResponse>(create);
  static CancelOrderResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class AccountInfoRequest extends $pb.GeneratedMessage {
  factory AccountInfoRequest() => create();

  AccountInfoRequest._();

  factory AccountInfoRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AccountInfoRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AccountInfoRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AccountInfoRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AccountInfoRequest copyWith(void Function(AccountInfoRequest) updates) =>
      super.copyWith((message) => updates(message as AccountInfoRequest))
          as AccountInfoRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AccountInfoRequest create() => AccountInfoRequest._();
  @$core.override
  AccountInfoRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AccountInfoRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AccountInfoRequest>(create);
  static AccountInfoRequest? _defaultInstance;
}

class AccountInfoResponse extends $pb.GeneratedMessage {
  factory AccountInfoResponse({
    $core.Iterable<BalanceProto>? balances,
    $core.double? totalEstimatedValueUSDC,
    $core.String? totalEstimatedValueUSDCStr,
  }) {
    final result = create();
    if (balances != null) result.balances.addAll(balances);
    if (totalEstimatedValueUSDC != null)
      result.totalEstimatedValueUSDC = totalEstimatedValueUSDC;
    if (totalEstimatedValueUSDCStr != null)
      result.totalEstimatedValueUSDCStr = totalEstimatedValueUSDCStr;
    return result;
  }

  AccountInfoResponse._();

  factory AccountInfoResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AccountInfoResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AccountInfoResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..pPM<BalanceProto>(1, _omitFieldNames ? '' : 'balances',
        subBuilder: BalanceProto.create)
    ..aD(2, _omitFieldNames ? '' : 'totalEstimatedValueUSDC',
        protoName: 'totalEstimatedValueUSDC')
    ..aOS(3, _omitFieldNames ? '' : 'totalEstimatedValueUSDCStr',
        protoName: 'totalEstimatedValueUSDCStr')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AccountInfoResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AccountInfoResponse copyWith(void Function(AccountInfoResponse) updates) =>
      super.copyWith((message) => updates(message as AccountInfoResponse))
          as AccountInfoResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AccountInfoResponse create() => AccountInfoResponse._();
  @$core.override
  AccountInfoResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AccountInfoResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AccountInfoResponse>(create);
  static AccountInfoResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<BalanceProto> get balances => $_getList(0);

  @$pb.TagNumber(2)
  $core.double get totalEstimatedValueUSDC => $_getN(1);
  @$pb.TagNumber(2)
  set totalEstimatedValueUSDC($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotalEstimatedValueUSDC() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotalEstimatedValueUSDC() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get totalEstimatedValueUSDCStr => $_getSZ(2);
  @$pb.TagNumber(3)
  set totalEstimatedValueUSDCStr($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotalEstimatedValueUSDCStr() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotalEstimatedValueUSDCStr() => $_clearField(3);
}

class BalanceProto extends $pb.GeneratedMessage {
  factory BalanceProto({
    $core.String? asset,
    $core.double? free,
    $core.double? locked,
    $core.double? estimatedValueUSDC,
    $core.String? freeStr,
    $core.String? lockedStr,
    $core.String? estimatedValueUSDCStr,
  }) {
    final result = create();
    if (asset != null) result.asset = asset;
    if (free != null) result.free = free;
    if (locked != null) result.locked = locked;
    if (estimatedValueUSDC != null)
      result.estimatedValueUSDC = estimatedValueUSDC;
    if (freeStr != null) result.freeStr = freeStr;
    if (lockedStr != null) result.lockedStr = lockedStr;
    if (estimatedValueUSDCStr != null)
      result.estimatedValueUSDCStr = estimatedValueUSDCStr;
    return result;
  }

  BalanceProto._();

  factory BalanceProto.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BalanceProto.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BalanceProto',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'asset')
    ..aD(2, _omitFieldNames ? '' : 'free')
    ..aD(3, _omitFieldNames ? '' : 'locked')
    ..aD(4, _omitFieldNames ? '' : 'estimatedValueUSDC',
        protoName: 'estimatedValueUSDC')
    ..aOS(5, _omitFieldNames ? '' : 'freeStr', protoName: 'freeStr')
    ..aOS(6, _omitFieldNames ? '' : 'lockedStr', protoName: 'lockedStr')
    ..aOS(7, _omitFieldNames ? '' : 'estimatedValueUSDCStr',
        protoName: 'estimatedValueUSDCStr')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BalanceProto clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BalanceProto copyWith(void Function(BalanceProto) updates) =>
      super.copyWith((message) => updates(message as BalanceProto))
          as BalanceProto;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BalanceProto create() => BalanceProto._();
  @$core.override
  BalanceProto createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BalanceProto getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BalanceProto>(create);
  static BalanceProto? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get asset => $_getSZ(0);
  @$pb.TagNumber(1)
  set asset($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAsset() => $_has(0);
  @$pb.TagNumber(1)
  void clearAsset() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get free => $_getN(1);
  @$pb.TagNumber(2)
  set free($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFree() => $_has(1);
  @$pb.TagNumber(2)
  void clearFree() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get locked => $_getN(2);
  @$pb.TagNumber(3)
  set locked($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLocked() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocked() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get estimatedValueUSDC => $_getN(3);
  @$pb.TagNumber(4)
  set estimatedValueUSDC($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEstimatedValueUSDC() => $_has(3);
  @$pb.TagNumber(4)
  void clearEstimatedValueUSDC() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get freeStr => $_getSZ(4);
  @$pb.TagNumber(5)
  set freeStr($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFreeStr() => $_has(4);
  @$pb.TagNumber(5)
  void clearFreeStr() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get lockedStr => $_getSZ(5);
  @$pb.TagNumber(6)
  set lockedStr($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLockedStr() => $_has(5);
  @$pb.TagNumber(6)
  void clearLockedStr() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get estimatedValueUSDCStr => $_getSZ(6);
  @$pb.TagNumber(7)
  set estimatedValueUSDCStr($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasEstimatedValueUSDCStr() => $_has(6);
  @$pb.TagNumber(7)
  void clearEstimatedValueUSDCStr() => $_clearField(7);
}

class GetLogSettingsRequest extends $pb.GeneratedMessage {
  factory GetLogSettingsRequest() => create();

  GetLogSettingsRequest._();

  factory GetLogSettingsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetLogSettingsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetLogSettingsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLogSettingsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLogSettingsRequest copyWith(
          void Function(GetLogSettingsRequest) updates) =>
      super.copyWith((message) => updates(message as GetLogSettingsRequest))
          as GetLogSettingsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetLogSettingsRequest create() => GetLogSettingsRequest._();
  @$core.override
  GetLogSettingsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetLogSettingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetLogSettingsRequest>(create);
  static GetLogSettingsRequest? _defaultInstance;
}

class UpdateLogSettingsRequest extends $pb.GeneratedMessage {
  factory UpdateLogSettingsRequest({
    LogSettingsProto? logSettings,
  }) {
    final result = create();
    if (logSettings != null) result.logSettings = logSettings;
    return result;
  }

  UpdateLogSettingsRequest._();

  factory UpdateLogSettingsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateLogSettingsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateLogSettingsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOM<LogSettingsProto>(1, _omitFieldNames ? '' : 'logSettings',
        protoName: 'logSettings', subBuilder: LogSettingsProto.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateLogSettingsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateLogSettingsRequest copyWith(
          void Function(UpdateLogSettingsRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateLogSettingsRequest))
          as UpdateLogSettingsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateLogSettingsRequest create() => UpdateLogSettingsRequest._();
  @$core.override
  UpdateLogSettingsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateLogSettingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateLogSettingsRequest>(create);
  static UpdateLogSettingsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  LogSettingsProto get logSettings => $_getN(0);
  @$pb.TagNumber(1)
  set logSettings(LogSettingsProto value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLogSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearLogSettings() => $_clearField(1);
  @$pb.TagNumber(1)
  LogSettingsProto ensureLogSettings() => $_ensure(0);
}

class LogSettingsResponse extends $pb.GeneratedMessage {
  factory LogSettingsResponse({
    LogSettingsProto? logSettings,
  }) {
    final result = create();
    if (logSettings != null) result.logSettings = logSettings;
    return result;
  }

  LogSettingsResponse._();

  factory LogSettingsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LogSettingsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LogSettingsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOM<LogSettingsProto>(1, _omitFieldNames ? '' : 'logSettings',
        protoName: 'logSettings', subBuilder: LogSettingsProto.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogSettingsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogSettingsResponse copyWith(void Function(LogSettingsResponse) updates) =>
      super.copyWith((message) => updates(message as LogSettingsResponse))
          as LogSettingsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LogSettingsResponse create() => LogSettingsResponse._();
  @$core.override
  LogSettingsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LogSettingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LogSettingsResponse>(create);
  static LogSettingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  LogSettingsProto get logSettings => $_getN(0);
  @$pb.TagNumber(1)
  set logSettings(LogSettingsProto value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLogSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearLogSettings() => $_clearField(1);
  @$pb.TagNumber(1)
  LogSettingsProto ensureLogSettings() => $_ensure(0);
}

class LogSettingsProto extends $pb.GeneratedMessage {
  factory LogSettingsProto({
    $core.String? logLevel,
    $core.bool? enableFileLogging,
    $core.bool? enableConsoleLogging,
  }) {
    final result = create();
    if (logLevel != null) result.logLevel = logLevel;
    if (enableFileLogging != null) result.enableFileLogging = enableFileLogging;
    if (enableConsoleLogging != null)
      result.enableConsoleLogging = enableConsoleLogging;
    return result;
  }

  LogSettingsProto._();

  factory LogSettingsProto.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LogSettingsProto.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LogSettingsProto',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'logLevel', protoName: 'logLevel')
    ..aOB(2, _omitFieldNames ? '' : 'enableFileLogging',
        protoName: 'enableFileLogging')
    ..aOB(3, _omitFieldNames ? '' : 'enableConsoleLogging',
        protoName: 'enableConsoleLogging')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogSettingsProto clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogSettingsProto copyWith(void Function(LogSettingsProto) updates) =>
      super.copyWith((message) => updates(message as LogSettingsProto))
          as LogSettingsProto;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LogSettingsProto create() => LogSettingsProto._();
  @$core.override
  LogSettingsProto createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LogSettingsProto getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LogSettingsProto>(create);
  static LogSettingsProto? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get logLevel => $_getSZ(0);
  @$pb.TagNumber(1)
  set logLevel($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLogLevel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLogLevel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enableFileLogging => $_getBF(1);
  @$pb.TagNumber(2)
  set enableFileLogging($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnableFileLogging() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnableFileLogging() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get enableConsoleLogging => $_getBF(2);
  @$pb.TagNumber(3)
  set enableConsoleLogging($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEnableConsoleLogging() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnableConsoleLogging() => $_clearField(3);
}

/// NUOVO MESSAGGIO per i log di sistema
class LogEntry extends $pb.GeneratedMessage {
  factory LogEntry({
    $core.String? level,
    $core.String? message,
    $fixnum.Int64? timestamp,
    $core.String? serviceName,
  }) {
    final result = create();
    if (level != null) result.level = level;
    if (message != null) result.message = message;
    if (timestamp != null) result.timestamp = timestamp;
    if (serviceName != null) result.serviceName = serviceName;
    return result;
  }

  LogEntry._();

  factory LogEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LogEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LogEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'level')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aInt64(3, _omitFieldNames ? '' : 'timestamp')
    ..aOS(4, _omitFieldNames ? '' : 'serviceName', protoName: 'serviceName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogEntry copyWith(void Function(LogEntry) updates) =>
      super.copyWith((message) => updates(message as LogEntry)) as LogEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LogEntry create() => LogEntry._();
  @$core.override
  LogEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LogEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogEntry>(create);
  static LogEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get level => $_getSZ(0);
  @$pb.TagNumber(1)
  set level($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLevel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLevel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get timestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set timestamp($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimestamp() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get serviceName => $_getSZ(3);
  @$pb.TagNumber(4)
  set serviceName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasServiceName() => $_has(3);
  @$pb.TagNumber(4)
  void clearServiceName() => $_clearField(4);
}

class StreamCurrentPriceRequest extends $pb.GeneratedMessage {
  factory StreamCurrentPriceRequest({
    $core.String? symbol,
  }) {
    final result = create();
    if (symbol != null) result.symbol = symbol;
    return result;
  }

  StreamCurrentPriceRequest._();

  factory StreamCurrentPriceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamCurrentPriceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamCurrentPriceRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'symbol')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamCurrentPriceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamCurrentPriceRequest copyWith(
          void Function(StreamCurrentPriceRequest) updates) =>
      super.copyWith((message) => updates(message as StreamCurrentPriceRequest))
          as StreamCurrentPriceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StreamCurrentPriceRequest create() => StreamCurrentPriceRequest._();
  @$core.override
  StreamCurrentPriceRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StreamCurrentPriceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StreamCurrentPriceRequest>(create);
  static StreamCurrentPriceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get symbol => $_getSZ(0);
  @$pb.TagNumber(1)
  set symbol($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSymbol() => $_has(0);
  @$pb.TagNumber(1)
  void clearSymbol() => $_clearField(1);
}

class PriceResponse extends $pb.GeneratedMessage {
  factory PriceResponse({
    $core.double? price,
    $core.double? priceChange24h,
    $core.double? priceChangeAbsolute24h,
    $core.double? highPrice24h,
    $core.double? lowPrice24h,
    $core.double? volume24h,
    $core.String? priceStr,
    $core.String? priceChange24hStr,
    $core.String? priceChangeAbsolute24hStr,
    $core.String? highPrice24hStr,
    $core.String? lowPrice24hStr,
    $core.String? volume24hStr,
  }) {
    final result = create();
    if (price != null) result.price = price;
    if (priceChange24h != null) result.priceChange24h = priceChange24h;
    if (priceChangeAbsolute24h != null)
      result.priceChangeAbsolute24h = priceChangeAbsolute24h;
    if (highPrice24h != null) result.highPrice24h = highPrice24h;
    if (lowPrice24h != null) result.lowPrice24h = lowPrice24h;
    if (volume24h != null) result.volume24h = volume24h;
    if (priceStr != null) result.priceStr = priceStr;
    if (priceChange24hStr != null) result.priceChange24hStr = priceChange24hStr;
    if (priceChangeAbsolute24hStr != null)
      result.priceChangeAbsolute24hStr = priceChangeAbsolute24hStr;
    if (highPrice24hStr != null) result.highPrice24hStr = highPrice24hStr;
    if (lowPrice24hStr != null) result.lowPrice24hStr = lowPrice24hStr;
    if (volume24hStr != null) result.volume24hStr = volume24hStr;
    return result;
  }

  PriceResponse._();

  factory PriceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PriceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PriceResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'price')
    ..aD(2, _omitFieldNames ? '' : 'priceChange24h',
        protoName: 'priceChange24h')
    ..aD(3, _omitFieldNames ? '' : 'priceChangeAbsolute24h',
        protoName: 'priceChangeAbsolute24h')
    ..aD(4, _omitFieldNames ? '' : 'highPrice24h', protoName: 'highPrice24h')
    ..aD(5, _omitFieldNames ? '' : 'lowPrice24h', protoName: 'lowPrice24h')
    ..aD(6, _omitFieldNames ? '' : 'volume24h')
    ..aOS(7, _omitFieldNames ? '' : 'priceStr', protoName: 'priceStr')
    ..aOS(8, _omitFieldNames ? '' : 'priceChange24hStr',
        protoName: 'priceChange24hStr')
    ..aOS(9, _omitFieldNames ? '' : 'priceChangeAbsolute24hStr',
        protoName: 'priceChangeAbsolute24hStr')
    ..aOS(10, _omitFieldNames ? '' : 'highPrice24hStr',
        protoName: 'highPrice24hStr')
    ..aOS(11, _omitFieldNames ? '' : 'lowPrice24hStr',
        protoName: 'lowPrice24hStr')
    ..aOS(12, _omitFieldNames ? '' : 'volume24hStr', protoName: 'volume24hStr')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PriceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PriceResponse copyWith(void Function(PriceResponse) updates) =>
      super.copyWith((message) => updates(message as PriceResponse))
          as PriceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PriceResponse create() => PriceResponse._();
  @$core.override
  PriceResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PriceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PriceResponse>(create);
  static PriceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get price => $_getN(0);
  @$pb.TagNumber(1)
  set price($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPrice() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrice() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get priceChange24h => $_getN(1);
  @$pb.TagNumber(2)
  set priceChange24h($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPriceChange24h() => $_has(1);
  @$pb.TagNumber(2)
  void clearPriceChange24h() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get priceChangeAbsolute24h => $_getN(2);
  @$pb.TagNumber(3)
  set priceChangeAbsolute24h($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPriceChangeAbsolute24h() => $_has(2);
  @$pb.TagNumber(3)
  void clearPriceChangeAbsolute24h() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get highPrice24h => $_getN(3);
  @$pb.TagNumber(4)
  set highPrice24h($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHighPrice24h() => $_has(3);
  @$pb.TagNumber(4)
  void clearHighPrice24h() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get lowPrice24h => $_getN(4);
  @$pb.TagNumber(5)
  set lowPrice24h($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLowPrice24h() => $_has(4);
  @$pb.TagNumber(5)
  void clearLowPrice24h() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get volume24h => $_getN(5);
  @$pb.TagNumber(6)
  set volume24h($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVolume24h() => $_has(5);
  @$pb.TagNumber(6)
  void clearVolume24h() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get priceStr => $_getSZ(6);
  @$pb.TagNumber(7)
  set priceStr($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPriceStr() => $_has(6);
  @$pb.TagNumber(7)
  void clearPriceStr() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get priceChange24hStr => $_getSZ(7);
  @$pb.TagNumber(8)
  set priceChange24hStr($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPriceChange24hStr() => $_has(7);
  @$pb.TagNumber(8)
  void clearPriceChange24hStr() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get priceChangeAbsolute24hStr => $_getSZ(8);
  @$pb.TagNumber(9)
  set priceChangeAbsolute24hStr($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPriceChangeAbsolute24hStr() => $_has(8);
  @$pb.TagNumber(9)
  void clearPriceChangeAbsolute24hStr() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get highPrice24hStr => $_getSZ(9);
  @$pb.TagNumber(10)
  set highPrice24hStr($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasHighPrice24hStr() => $_has(9);
  @$pb.TagNumber(10)
  void clearHighPrice24hStr() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get lowPrice24hStr => $_getSZ(10);
  @$pb.TagNumber(11)
  set lowPrice24hStr($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasLowPrice24hStr() => $_has(10);
  @$pb.TagNumber(11)
  void clearLowPrice24hStr() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get volume24hStr => $_getSZ(11);
  @$pb.TagNumber(12)
  set volume24hStr($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasVolume24hStr() => $_has(11);
  @$pb.TagNumber(12)
  void clearVolume24hStr() => $_clearField(12);
}

class GetSymbolFeesRequest extends $pb.GeneratedMessage {
  factory GetSymbolFeesRequest({
    $core.String? symbol,
  }) {
    final result = create();
    if (symbol != null) result.symbol = symbol;
    return result;
  }

  GetSymbolFeesRequest._();

  factory GetSymbolFeesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSymbolFeesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSymbolFeesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'symbol')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSymbolFeesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSymbolFeesRequest copyWith(void Function(GetSymbolFeesRequest) updates) =>
      super.copyWith((message) => updates(message as GetSymbolFeesRequest))
          as GetSymbolFeesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSymbolFeesRequest create() => GetSymbolFeesRequest._();
  @$core.override
  GetSymbolFeesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSymbolFeesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSymbolFeesRequest>(create);
  static GetSymbolFeesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get symbol => $_getSZ(0);
  @$pb.TagNumber(1)
  set symbol($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSymbol() => $_has(0);
  @$pb.TagNumber(1)
  void clearSymbol() => $_clearField(1);
}

class SymbolFeesResponse extends $pb.GeneratedMessage {
  factory SymbolFeesResponse({
    $core.String? symbol,
    $core.double? makerFee,
    $core.double? takerFee,
    $core.String? feeCurrency,
    $core.bool? isDiscountActive,
    $core.double? discountPercentage,
    $fixnum.Int64? lastUpdated,
  }) {
    final result = create();
    if (symbol != null) result.symbol = symbol;
    if (makerFee != null) result.makerFee = makerFee;
    if (takerFee != null) result.takerFee = takerFee;
    if (feeCurrency != null) result.feeCurrency = feeCurrency;
    if (isDiscountActive != null) result.isDiscountActive = isDiscountActive;
    if (discountPercentage != null)
      result.discountPercentage = discountPercentage;
    if (lastUpdated != null) result.lastUpdated = lastUpdated;
    return result;
  }

  SymbolFeesResponse._();

  factory SymbolFeesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SymbolFeesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SymbolFeesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'symbol')
    ..aD(2, _omitFieldNames ? '' : 'makerFee', protoName: 'makerFee')
    ..aD(3, _omitFieldNames ? '' : 'takerFee', protoName: 'takerFee')
    ..aOS(4, _omitFieldNames ? '' : 'feeCurrency', protoName: 'feeCurrency')
    ..aOB(5, _omitFieldNames ? '' : 'isDiscountActive',
        protoName: 'isDiscountActive')
    ..aD(6, _omitFieldNames ? '' : 'discountPercentage',
        protoName: 'discountPercentage')
    ..aInt64(7, _omitFieldNames ? '' : 'lastUpdated', protoName: 'lastUpdated')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SymbolFeesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SymbolFeesResponse copyWith(void Function(SymbolFeesResponse) updates) =>
      super.copyWith((message) => updates(message as SymbolFeesResponse))
          as SymbolFeesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SymbolFeesResponse create() => SymbolFeesResponse._();
  @$core.override
  SymbolFeesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SymbolFeesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SymbolFeesResponse>(create);
  static SymbolFeesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get symbol => $_getSZ(0);
  @$pb.TagNumber(1)
  set symbol($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSymbol() => $_has(0);
  @$pb.TagNumber(1)
  void clearSymbol() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get makerFee => $_getN(1);
  @$pb.TagNumber(2)
  set makerFee($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMakerFee() => $_has(1);
  @$pb.TagNumber(2)
  void clearMakerFee() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get takerFee => $_getN(2);
  @$pb.TagNumber(3)
  set takerFee($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTakerFee() => $_has(2);
  @$pb.TagNumber(3)
  void clearTakerFee() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get feeCurrency => $_getSZ(3);
  @$pb.TagNumber(4)
  set feeCurrency($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFeeCurrency() => $_has(3);
  @$pb.TagNumber(4)
  void clearFeeCurrency() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isDiscountActive => $_getBF(4);
  @$pb.TagNumber(5)
  set isDiscountActive($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIsDiscountActive() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsDiscountActive() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get discountPercentage => $_getN(5);
  @$pb.TagNumber(6)
  set discountPercentage($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDiscountPercentage() => $_has(5);
  @$pb.TagNumber(6)
  void clearDiscountPercentage() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get lastUpdated => $_getI64(6);
  @$pb.TagNumber(7)
  set lastUpdated($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLastUpdated() => $_has(6);
  @$pb.TagNumber(7)
  void clearLastUpdated() => $_clearField(7);
}

class AllSymbolFeesResponse extends $pb.GeneratedMessage {
  factory AllSymbolFeesResponse({
    $core.Iterable<SymbolFeesResponse>? symbolFees,
  }) {
    final result = create();
    if (symbolFees != null) result.symbolFees.addAll(symbolFees);
    return result;
  }

  AllSymbolFeesResponse._();

  factory AllSymbolFeesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AllSymbolFeesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AllSymbolFeesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..pPM<SymbolFeesResponse>(1, _omitFieldNames ? '' : 'symbolFees',
        protoName: 'symbolFees', subBuilder: SymbolFeesResponse.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AllSymbolFeesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AllSymbolFeesResponse copyWith(
          void Function(AllSymbolFeesResponse) updates) =>
      super.copyWith((message) => updates(message as AllSymbolFeesResponse))
          as AllSymbolFeesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AllSymbolFeesResponse create() => AllSymbolFeesResponse._();
  @$core.override
  AllSymbolFeesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AllSymbolFeesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AllSymbolFeesResponse>(create);
  static AllSymbolFeesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SymbolFeesResponse> get symbolFees => $_getList(0);
}

class StatusReportResponse extends $pb.GeneratedMessage {
  factory StatusReportResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  StatusReportResponse._();

  factory StatusReportResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StatusReportResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatusReportResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusReportResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusReportResponse copyWith(void Function(StatusReportResponse) updates) =>
      super.copyWith((message) => updates(message as StatusReportResponse))
          as StatusReportResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatusReportResponse create() => StatusReportResponse._();
  @$core.override
  StatusReportResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StatusReportResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StatusReportResponse>(create);
  static StatusReportResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class StartBacktestRequest extends $pb.GeneratedMessage {
  factory StartBacktestRequest({
    $core.String? symbol,
    $fixnum.Int64? startTime,
    $fixnum.Int64? endTime,
    $core.String? interval,
    $core.double? initialBalance,
    Settings? settings,
  }) {
    final result = create();
    if (symbol != null) result.symbol = symbol;
    if (startTime != null) result.startTime = startTime;
    if (endTime != null) result.endTime = endTime;
    if (interval != null) result.interval = interval;
    if (initialBalance != null) result.initialBalance = initialBalance;
    if (settings != null) result.settings = settings;
    return result;
  }

  StartBacktestRequest._();

  factory StartBacktestRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartBacktestRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartBacktestRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'symbol')
    ..aInt64(2, _omitFieldNames ? '' : 'startTime', protoName: 'startTime')
    ..aInt64(3, _omitFieldNames ? '' : 'endTime', protoName: 'endTime')
    ..aOS(4, _omitFieldNames ? '' : 'interval')
    ..aD(5, _omitFieldNames ? '' : 'initialBalance',
        protoName: 'initialBalance')
    ..aOM<Settings>(6, _omitFieldNames ? '' : 'settings',
        subBuilder: Settings.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartBacktestRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartBacktestRequest copyWith(void Function(StartBacktestRequest) updates) =>
      super.copyWith((message) => updates(message as StartBacktestRequest))
          as StartBacktestRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartBacktestRequest create() => StartBacktestRequest._();
  @$core.override
  StartBacktestRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartBacktestRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartBacktestRequest>(create);
  static StartBacktestRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get symbol => $_getSZ(0);
  @$pb.TagNumber(1)
  set symbol($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSymbol() => $_has(0);
  @$pb.TagNumber(1)
  void clearSymbol() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get startTime => $_getI64(1);
  @$pb.TagNumber(2)
  set startTime($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStartTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearStartTime() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get endTime => $_getI64(2);
  @$pb.TagNumber(3)
  set endTime($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEndTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearEndTime() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get interval => $_getSZ(3);
  @$pb.TagNumber(4)
  set interval($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasInterval() => $_has(3);
  @$pb.TagNumber(4)
  void clearInterval() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get initialBalance => $_getN(4);
  @$pb.TagNumber(5)
  set initialBalance($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasInitialBalance() => $_has(4);
  @$pb.TagNumber(5)
  void clearInitialBalance() => $_clearField(5);

  @$pb.TagNumber(6)
  Settings get settings => $_getN(5);
  @$pb.TagNumber(6)
  set settings(Settings value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasSettings() => $_has(5);
  @$pb.TagNumber(6)
  void clearSettings() => $_clearField(6);
  @$pb.TagNumber(6)
  Settings ensureSettings() => $_ensure(5);
}

class BacktestResponse extends $pb.GeneratedMessage {
  factory BacktestResponse({
    $core.bool? success,
    $core.String? message,
    $core.String? backtestId,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (backtestId != null) result.backtestId = backtestId;
    return result;
  }

  BacktestResponse._();

  factory BacktestResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BacktestResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BacktestResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOS(3, _omitFieldNames ? '' : 'backtestId', protoName: 'backtestId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BacktestResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BacktestResponse copyWith(void Function(BacktestResponse) updates) =>
      super.copyWith((message) => updates(message as BacktestResponse))
          as BacktestResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BacktestResponse create() => BacktestResponse._();
  @$core.override
  BacktestResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BacktestResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BacktestResponse>(create);
  static BacktestResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get backtestId => $_getSZ(2);
  @$pb.TagNumber(3)
  set backtestId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBacktestId() => $_has(2);
  @$pb.TagNumber(3)
  void clearBacktestId() => $_clearField(3);
}

class GetBacktestResultsRequest extends $pb.GeneratedMessage {
  factory GetBacktestResultsRequest({
    $core.String? backtestId,
  }) {
    final result = create();
    if (backtestId != null) result.backtestId = backtestId;
    return result;
  }

  GetBacktestResultsRequest._();

  factory GetBacktestResultsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetBacktestResultsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetBacktestResultsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'backtestId', protoName: 'backtestId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBacktestResultsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBacktestResultsRequest copyWith(
          void Function(GetBacktestResultsRequest) updates) =>
      super.copyWith((message) => updates(message as GetBacktestResultsRequest))
          as GetBacktestResultsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBacktestResultsRequest create() => GetBacktestResultsRequest._();
  @$core.override
  GetBacktestResultsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetBacktestResultsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetBacktestResultsRequest>(create);
  static GetBacktestResultsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get backtestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set backtestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBacktestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBacktestId() => $_clearField(1);
}

class BacktestResultsResponse extends $pb.GeneratedMessage {
  factory BacktestResultsResponse({
    $core.String? backtestId,
    $core.double? totalProfit,
    $core.double? profitPercentage,
    $core.int? tradesCount,
    $core.Iterable<Trade>? trades,
    $core.String? totalProfitStr,
    $core.String? profitPercentageStr,
  }) {
    final result = create();
    if (backtestId != null) result.backtestId = backtestId;
    if (totalProfit != null) result.totalProfit = totalProfit;
    if (profitPercentage != null) result.profitPercentage = profitPercentage;
    if (tradesCount != null) result.tradesCount = tradesCount;
    if (trades != null) result.trades.addAll(trades);
    if (totalProfitStr != null) result.totalProfitStr = totalProfitStr;
    if (profitPercentageStr != null)
      result.profitPercentageStr = profitPercentageStr;
    return result;
  }

  BacktestResultsResponse._();

  factory BacktestResultsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BacktestResultsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BacktestResultsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'trading.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'backtestId', protoName: 'backtestId')
    ..aD(2, _omitFieldNames ? '' : 'totalProfit', protoName: 'totalProfit')
    ..aD(3, _omitFieldNames ? '' : 'profitPercentage',
        protoName: 'profitPercentage')
    ..aI(4, _omitFieldNames ? '' : 'tradesCount', protoName: 'tradesCount')
    ..pPM<Trade>(5, _omitFieldNames ? '' : 'trades', subBuilder: Trade.create)
    ..aOS(6, _omitFieldNames ? '' : 'totalProfitStr',
        protoName: 'totalProfitStr')
    ..aOS(7, _omitFieldNames ? '' : 'profitPercentageStr',
        protoName: 'profitPercentageStr')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BacktestResultsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BacktestResultsResponse copyWith(
          void Function(BacktestResultsResponse) updates) =>
      super.copyWith((message) => updates(message as BacktestResultsResponse))
          as BacktestResultsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BacktestResultsResponse create() => BacktestResultsResponse._();
  @$core.override
  BacktestResultsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BacktestResultsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BacktestResultsResponse>(create);
  static BacktestResultsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get backtestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set backtestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBacktestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBacktestId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get totalProfit => $_getN(1);
  @$pb.TagNumber(2)
  set totalProfit($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotalProfit() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotalProfit() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get profitPercentage => $_getN(2);
  @$pb.TagNumber(3)
  set profitPercentage($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProfitPercentage() => $_has(2);
  @$pb.TagNumber(3)
  void clearProfitPercentage() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get tradesCount => $_getIZ(3);
  @$pb.TagNumber(4)
  set tradesCount($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTradesCount() => $_has(3);
  @$pb.TagNumber(4)
  void clearTradesCount() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<Trade> get trades => $_getList(4);

  @$pb.TagNumber(6)
  $core.String get totalProfitStr => $_getSZ(5);
  @$pb.TagNumber(6)
  set totalProfitStr($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTotalProfitStr() => $_has(5);
  @$pb.TagNumber(6)
  void clearTotalProfitStr() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get profitPercentageStr => $_getSZ(6);
  @$pb.TagNumber(7)
  set profitPercentageStr($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasProfitPercentageStr() => $_has(6);
  @$pb.TagNumber(7)
  void clearProfitPercentageStr() => $_clearField(7);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
