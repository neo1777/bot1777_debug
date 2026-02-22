// This is a generated file - do not edit.
//
// Generated from trading/v1/trading_service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use strategyStatusDescriptor instead')
const StrategyStatus$json = {
  '1': 'StrategyStatus',
  '2': [
    {'1': 'STRATEGY_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'STRATEGY_STATUS_IDLE', '2': 1},
    {'1': 'STRATEGY_STATUS_RUNNING', '2': 2},
    {'1': 'STRATEGY_STATUS_PAUSED', '2': 3},
    {'1': 'STRATEGY_STATUS_ERROR', '2': 4},
    {'1': 'STRATEGY_STATUS_RECOVERING', '2': 5},
  ],
};

/// Descriptor for `StrategyStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List strategyStatusDescriptor = $convert.base64Decode(
    'Cg5TdHJhdGVneVN0YXR1cxIfChtTVFJBVEVHWV9TVEFUVVNfVU5TUEVDSUZJRUQQABIYChRTVF'
    'JBVEVHWV9TVEFUVVNfSURMRRABEhsKF1NUUkFURUdZX1NUQVRVU19SVU5OSU5HEAISGgoWU1RS'
    'QVRFR1lfU1RBVFVTX1BBVVNFRBADEhkKFVNUUkFURUdZX1NUQVRVU19FUlJPUhAEEh4KGlNUUk'
    'FURUdZX1NUQVRVU19SRUNPVkVSSU5HEAU=');

@$core.Deprecated('Use updateSettingsRequestDescriptor instead')
const UpdateSettingsRequest$json = {
  '1': 'UpdateSettingsRequest',
  '2': [
    {
      '1': 'settings',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.trading.v1.Settings',
      '10': 'settings'
    },
  ],
};

/// Descriptor for `UpdateSettingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateSettingsRequestDescriptor = $convert.base64Decode(
    'ChVVcGRhdGVTZXR0aW5nc1JlcXVlc3QSMAoIc2V0dGluZ3MYASABKAsyFC50cmFkaW5nLnYxLl'
    'NldHRpbmdzUghzZXR0aW5ncw==');

@$core.Deprecated('Use settingsResponseDescriptor instead')
const SettingsResponse$json = {
  '1': 'SettingsResponse',
  '2': [
    {
      '1': 'settings',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.trading.v1.Settings',
      '10': 'settings'
    },
    {'1': 'warnings', '3': 2, '4': 3, '5': 9, '10': 'warnings'},
  ],
};

/// Descriptor for `SettingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List settingsResponseDescriptor = $convert.base64Decode(
    'ChBTZXR0aW5nc1Jlc3BvbnNlEjAKCHNldHRpbmdzGAEgASgLMhQudHJhZGluZy52MS5TZXR0aW'
    '5nc1IIc2V0dGluZ3MSGgoId2FybmluZ3MYAiADKAlSCHdhcm5pbmdz');

@$core.Deprecated('Use settingsDescriptor instead')
const Settings$json = {
  '1': 'Settings',
  '2': [
    {'1': 'tradeAmount', '3': 1, '4': 1, '5': 1, '10': 'tradeAmount'},
    {
      '1': 'fixedQuantityStr',
      '3': 26,
      '4': 1,
      '5': 9,
      '10': 'fixedQuantityStr'
    },
    {
      '1': 'profitTargetPercentage',
      '3': 2,
      '4': 1,
      '5': 1,
      '10': 'profitTargetPercentage'
    },
    {
      '1': 'stopLossPercentage',
      '3': 3,
      '4': 1,
      '5': 1,
      '10': 'stopLossPercentage'
    },
    {
      '1': 'dcaDecrementPercentage',
      '3': 4,
      '4': 1,
      '5': 1,
      '10': 'dcaDecrementPercentage'
    },
    {'1': 'maxOpenTrades', '3': 5, '4': 1, '5': 5, '10': 'maxOpenTrades'},
    {'1': 'isTestMode', '3': 6, '4': 1, '5': 8, '10': 'isTestMode'},
    {'1': 'buyOnStart', '3': 7, '4': 1, '5': 8, '10': 'buyOnStart'},
    {
      '1': 'initialWarmupTicks',
      '3': 8,
      '4': 1,
      '5': 5,
      '10': 'initialWarmupTicks'
    },
    {
      '1': 'initialWarmupSecondsStr',
      '3': 9,
      '4': 1,
      '5': 9,
      '10': 'initialWarmupSecondsStr'
    },
    {
      '1': 'initialSignalThresholdPctStr',
      '3': 10,
      '4': 1,
      '5': 9,
      '10': 'initialSignalThresholdPctStr'
    },
    {
      '1': 'dcaCooldownSecondsStr',
      '3': 11,
      '4': 1,
      '5': 9,
      '10': 'dcaCooldownSecondsStr'
    },
    {
      '1': 'dustRetryCooldownSecondsStr',
      '3': 12,
      '4': 1,
      '5': 9,
      '10': 'dustRetryCooldownSecondsStr'
    },
    {
      '1': 'maxTradeAmountCapStr',
      '3': 13,
      '4': 1,
      '5': 9,
      '10': 'maxTradeAmountCapStr'
    },
    {
      '1': 'maxBuyOveragePctStr',
      '3': 14,
      '4': 1,
      '5': 9,
      '10': 'maxBuyOveragePctStr'
    },
    {'1': 'strictBudget', '3': 15, '4': 1, '5': 8, '10': 'strictBudget'},
    {
      '1': 'buyOnStartRespectWarmup',
      '3': 16,
      '4': 1,
      '5': 8,
      '10': 'buyOnStartRespectWarmup'
    },
    {
      '1': 'buyCooldownSecondsStr',
      '3': 17,
      '4': 1,
      '5': 9,
      '10': 'buyCooldownSecondsStr'
    },
    {
      '1': 'dcaCompareAgainstAverage',
      '3': 18,
      '4': 1,
      '5': 8,
      '10': 'dcaCompareAgainstAverage'
    },
    {'1': 'maxCycles', '3': 20, '4': 1, '5': 5, '10': 'maxCycles'},
    {'1': 'tradeAmountStr', '3': 21, '4': 1, '5': 9, '10': 'tradeAmountStr'},
    {
      '1': 'profitTargetPercentageStr',
      '3': 22,
      '4': 1,
      '5': 9,
      '10': 'profitTargetPercentageStr'
    },
    {
      '1': 'stopLossPercentageStr',
      '3': 23,
      '4': 1,
      '5': 9,
      '10': 'stopLossPercentageStr'
    },
    {
      '1': 'dcaDecrementPercentageStr',
      '3': 24,
      '4': 1,
      '5': 9,
      '10': 'dcaDecrementPercentageStr'
    },
    {
      '1': 'enableFeeAwareTrading',
      '3': 25,
      '4': 1,
      '5': 8,
      '10': 'enableFeeAwareTrading'
    },
  ],
};

/// Descriptor for `Settings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List settingsDescriptor = $convert.base64Decode(
    'CghTZXR0aW5ncxIgCgt0cmFkZUFtb3VudBgBIAEoAVILdHJhZGVBbW91bnQSKgoQZml4ZWRRdW'
    'FudGl0eVN0chgaIAEoCVIQZml4ZWRRdWFudGl0eVN0chI2ChZwcm9maXRUYXJnZXRQZXJjZW50'
    'YWdlGAIgASgBUhZwcm9maXRUYXJnZXRQZXJjZW50YWdlEi4KEnN0b3BMb3NzUGVyY2VudGFnZR'
    'gDIAEoAVISc3RvcExvc3NQZXJjZW50YWdlEjYKFmRjYURlY3JlbWVudFBlcmNlbnRhZ2UYBCAB'
    'KAFSFmRjYURlY3JlbWVudFBlcmNlbnRhZ2USJAoNbWF4T3BlblRyYWRlcxgFIAEoBVINbWF4T3'
    'BlblRyYWRlcxIeCgppc1Rlc3RNb2RlGAYgASgIUgppc1Rlc3RNb2RlEh4KCmJ1eU9uU3RhcnQY'
    'ByABKAhSCmJ1eU9uU3RhcnQSLgoSaW5pdGlhbFdhcm11cFRpY2tzGAggASgFUhJpbml0aWFsV2'
    'FybXVwVGlja3MSOAoXaW5pdGlhbFdhcm11cFNlY29uZHNTdHIYCSABKAlSF2luaXRpYWxXYXJt'
    'dXBTZWNvbmRzU3RyEkIKHGluaXRpYWxTaWduYWxUaHJlc2hvbGRQY3RTdHIYCiABKAlSHGluaX'
    'RpYWxTaWduYWxUaHJlc2hvbGRQY3RTdHISNAoVZGNhQ29vbGRvd25TZWNvbmRzU3RyGAsgASgJ'
    'UhVkY2FDb29sZG93blNlY29uZHNTdHISQAobZHVzdFJldHJ5Q29vbGRvd25TZWNvbmRzU3RyGA'
    'wgASgJUhtkdXN0UmV0cnlDb29sZG93blNlY29uZHNTdHISMgoUbWF4VHJhZGVBbW91bnRDYXBT'
    'dHIYDSABKAlSFG1heFRyYWRlQW1vdW50Q2FwU3RyEjAKE21heEJ1eU92ZXJhZ2VQY3RTdHIYDi'
    'ABKAlSE21heEJ1eU92ZXJhZ2VQY3RTdHISIgoMc3RyaWN0QnVkZ2V0GA8gASgIUgxzdHJpY3RC'
    'dWRnZXQSOAoXYnV5T25TdGFydFJlc3BlY3RXYXJtdXAYECABKAhSF2J1eU9uU3RhcnRSZXNwZW'
    'N0V2FybXVwEjQKFWJ1eUNvb2xkb3duU2Vjb25kc1N0chgRIAEoCVIVYnV5Q29vbGRvd25TZWNv'
    'bmRzU3RyEjoKGGRjYUNvbXBhcmVBZ2FpbnN0QXZlcmFnZRgSIAEoCFIYZGNhQ29tcGFyZUFnYW'
    'luc3RBdmVyYWdlEhwKCW1heEN5Y2xlcxgUIAEoBVIJbWF4Q3ljbGVzEiYKDnRyYWRlQW1vdW50'
    'U3RyGBUgASgJUg50cmFkZUFtb3VudFN0chI8Chlwcm9maXRUYXJnZXRQZXJjZW50YWdlU3RyGB'
    'YgASgJUhlwcm9maXRUYXJnZXRQZXJjZW50YWdlU3RyEjQKFXN0b3BMb3NzUGVyY2VudGFnZVN0'
    'chgXIAEoCVIVc3RvcExvc3NQZXJjZW50YWdlU3RyEjwKGWRjYURlY3JlbWVudFBlcmNlbnRhZ2'
    'VTdHIYGCABKAlSGWRjYURlY3JlbWVudFBlcmNlbnRhZ2VTdHISNAoVZW5hYmxlRmVlQXdhcmVU'
    'cmFkaW5nGBkgASgIUhVlbmFibGVGZWVBd2FyZVRyYWRpbmc=');

@$core.Deprecated('Use startStrategyRequestDescriptor instead')
const StartStrategyRequest$json = {
  '1': 'StartStrategyRequest',
  '2': [
    {'1': 'symbol', '3': 1, '4': 1, '5': 9, '10': 'symbol'},
  ],
};

/// Descriptor for `StartStrategyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startStrategyRequestDescriptor =
    $convert.base64Decode(
        'ChRTdGFydFN0cmF0ZWd5UmVxdWVzdBIWCgZzeW1ib2wYASABKAlSBnN5bWJvbA==');

@$core.Deprecated('Use stopStrategyRequestDescriptor instead')
const StopStrategyRequest$json = {
  '1': 'StopStrategyRequest',
  '2': [
    {'1': 'symbol', '3': 1, '4': 1, '5': 9, '10': 'symbol'},
  ],
};

/// Descriptor for `StopStrategyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stopStrategyRequestDescriptor =
    $convert.base64Decode(
        'ChNTdG9wU3RyYXRlZ3lSZXF1ZXN0EhYKBnN5bWJvbBgBIAEoCVIGc3ltYm9s');

@$core.Deprecated('Use pauseTradingRequestDescriptor instead')
const PauseTradingRequest$json = {
  '1': 'PauseTradingRequest',
  '2': [
    {'1': 'symbol', '3': 1, '4': 1, '5': 9, '10': 'symbol'},
  ],
};

/// Descriptor for `PauseTradingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pauseTradingRequestDescriptor =
    $convert.base64Decode(
        'ChNQYXVzZVRyYWRpbmdSZXF1ZXN0EhYKBnN5bWJvbBgBIAEoCVIGc3ltYm9s');

@$core.Deprecated('Use resumeTradingRequestDescriptor instead')
const ResumeTradingRequest$json = {
  '1': 'ResumeTradingRequest',
  '2': [
    {'1': 'symbol', '3': 1, '4': 1, '5': 9, '10': 'symbol'},
  ],
};

/// Descriptor for `ResumeTradingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resumeTradingRequestDescriptor =
    $convert.base64Decode(
        'ChRSZXN1bWVUcmFkaW5nUmVxdWVzdBIWCgZzeW1ib2wYASABKAlSBnN5bWJvbA==');

@$core.Deprecated('Use strategyResponseDescriptor instead')
const StrategyResponse$json = {
  '1': 'StrategyResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `StrategyResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List strategyResponseDescriptor = $convert.base64Decode(
    'ChBTdHJhdGVneVJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbWVzc2FnZR'
    'gCIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use getStrategyStateRequestDescriptor instead')
const GetStrategyStateRequest$json = {
  '1': 'GetStrategyStateRequest',
  '2': [
    {'1': 'symbol', '3': 1, '4': 1, '5': 9, '10': 'symbol'},
  ],
};

/// Descriptor for `GetStrategyStateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStrategyStateRequestDescriptor =
    $convert.base64Decode(
        'ChdHZXRTdHJhdGVneVN0YXRlUmVxdWVzdBIWCgZzeW1ib2wYASABKAlSBnN5bWJvbA==');

@$core.Deprecated('Use strategyStateResponseDescriptor instead')
const StrategyStateResponse$json = {
  '1': 'StrategyStateResponse',
  '2': [
    {'1': 'symbol', '3': 1, '4': 1, '5': 9, '10': 'symbol'},
    {
      '1': 'status',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.trading.v1.StrategyStatus',
      '10': 'status'
    },
    {'1': 'openTradesCount', '3': 3, '4': 1, '5': 5, '10': 'openTradesCount'},
    {'1': 'averagePrice', '3': 4, '4': 1, '5': 1, '10': 'averagePrice'},
    {'1': 'totalQuantity', '3': 5, '4': 1, '5': 1, '10': 'totalQuantity'},
    {'1': 'lastBuyPrice', '3': 6, '4': 1, '5': 1, '10': 'lastBuyPrice'},
    {'1': 'currentRoundId', '3': 7, '4': 1, '5': 5, '10': 'currentRoundId'},
    {'1': 'cumulativeProfit', '3': 8, '4': 1, '5': 1, '10': 'cumulativeProfit'},
    {'1': 'successfulRounds', '3': 9, '4': 1, '5': 5, '10': 'successfulRounds'},
    {'1': 'failedRounds', '3': 10, '4': 1, '5': 5, '10': 'failedRounds'},
    {'1': 'warningMessage', '3': 11, '4': 1, '5': 9, '10': 'warningMessage'},
    {'1': 'warnings', '3': 12, '4': 3, '5': 9, '10': 'warnings'},
    {'1': 'averagePriceStr', '3': 13, '4': 1, '5': 9, '10': 'averagePriceStr'},
    {
      '1': 'totalQuantityStr',
      '3': 14,
      '4': 1,
      '5': 9,
      '10': 'totalQuantityStr'
    },
    {'1': 'lastBuyPriceStr', '3': 15, '4': 1, '5': 9, '10': 'lastBuyPriceStr'},
    {
      '1': 'cumulativeProfitStr',
      '3': 16,
      '4': 1,
      '5': 9,
      '10': 'cumulativeProfitStr'
    },
  ],
};

/// Descriptor for `StrategyStateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List strategyStateResponseDescriptor = $convert.base64Decode(
    'ChVTdHJhdGVneVN0YXRlUmVzcG9uc2USFgoGc3ltYm9sGAEgASgJUgZzeW1ib2wSMgoGc3RhdH'
    'VzGAIgASgOMhoudHJhZGluZy52MS5TdHJhdGVneVN0YXR1c1IGc3RhdHVzEigKD29wZW5UcmFk'
    'ZXNDb3VudBgDIAEoBVIPb3BlblRyYWRlc0NvdW50EiIKDGF2ZXJhZ2VQcmljZRgEIAEoAVIMYX'
    'ZlcmFnZVByaWNlEiQKDXRvdGFsUXVhbnRpdHkYBSABKAFSDXRvdGFsUXVhbnRpdHkSIgoMbGFz'
    'dEJ1eVByaWNlGAYgASgBUgxsYXN0QnV5UHJpY2USJgoOY3VycmVudFJvdW5kSWQYByABKAVSDm'
    'N1cnJlbnRSb3VuZElkEioKEGN1bXVsYXRpdmVQcm9maXQYCCABKAFSEGN1bXVsYXRpdmVQcm9m'
    'aXQSKgoQc3VjY2Vzc2Z1bFJvdW5kcxgJIAEoBVIQc3VjY2Vzc2Z1bFJvdW5kcxIiCgxmYWlsZW'
    'RSb3VuZHMYCiABKAVSDGZhaWxlZFJvdW5kcxImCg53YXJuaW5nTWVzc2FnZRgLIAEoCVIOd2Fy'
    'bmluZ01lc3NhZ2USGgoId2FybmluZ3MYDCADKAlSCHdhcm5pbmdzEigKD2F2ZXJhZ2VQcmljZV'
    'N0chgNIAEoCVIPYXZlcmFnZVByaWNlU3RyEioKEHRvdGFsUXVhbnRpdHlTdHIYDiABKAlSEHRv'
    'dGFsUXVhbnRpdHlTdHISKAoPbGFzdEJ1eVByaWNlU3RyGA8gASgJUg9sYXN0QnV5UHJpY2VTdH'
    'ISMAoTY3VtdWxhdGl2ZVByb2ZpdFN0chgQIAEoCVITY3VtdWxhdGl2ZVByb2ZpdFN0cg==');

@$core.Deprecated('Use getTradeHistoryRequestDescriptor instead')
const GetTradeHistoryRequest$json = {
  '1': 'GetTradeHistoryRequest',
};

/// Descriptor for `GetTradeHistoryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTradeHistoryRequestDescriptor =
    $convert.base64Decode('ChZHZXRUcmFkZUhpc3RvcnlSZXF1ZXN0');

@$core.Deprecated('Use tradeHistoryResponseDescriptor instead')
const TradeHistoryResponse$json = {
  '1': 'TradeHistoryResponse',
  '2': [
    {
      '1': 'trades',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.trading.v1.Trade',
      '10': 'trades'
    },
  ],
};

/// Descriptor for `TradeHistoryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tradeHistoryResponseDescriptor = $convert.base64Decode(
    'ChRUcmFkZUhpc3RvcnlSZXNwb25zZRIpCgZ0cmFkZXMYASADKAsyES50cmFkaW5nLnYxLlRyYW'
    'RlUgZ0cmFkZXM=');

@$core.Deprecated('Use tradeDescriptor instead')
const Trade$json = {
  '1': 'Trade',
  '2': [
    {'1': 'symbol', '3': 1, '4': 1, '5': 9, '10': 'symbol'},
    {'1': 'price', '3': 2, '4': 1, '5': 1, '10': 'price'},
    {'1': 'quantity', '3': 3, '4': 1, '5': 1, '10': 'quantity'},
    {'1': 'isBuy', '3': 4, '4': 1, '5': 8, '10': 'isBuy'},
    {'1': 'timestamp', '3': 5, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'orderStatus', '3': 6, '4': 1, '5': 9, '10': 'orderStatus'},
    {'1': 'profit', '3': 7, '4': 1, '5': 1, '9': 0, '10': 'profit', '17': true},
    {'1': 'priceStr', '3': 8, '4': 1, '5': 9, '10': 'priceStr'},
    {'1': 'quantityStr', '3': 9, '4': 1, '5': 9, '10': 'quantityStr'},
    {'1': 'profitStr', '3': 10, '4': 1, '5': 9, '10': 'profitStr'},
  ],
  '8': [
    {'1': '_profit'},
  ],
};

/// Descriptor for `Trade`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tradeDescriptor = $convert.base64Decode(
    'CgVUcmFkZRIWCgZzeW1ib2wYASABKAlSBnN5bWJvbBIUCgVwcmljZRgCIAEoAVIFcHJpY2USGg'
    'oIcXVhbnRpdHkYAyABKAFSCHF1YW50aXR5EhQKBWlzQnV5GAQgASgIUgVpc0J1eRIcCgl0aW1l'
    'c3RhbXAYBSABKANSCXRpbWVzdGFtcBIgCgtvcmRlclN0YXR1cxgGIAEoCVILb3JkZXJTdGF0dX'
    'MSGwoGcHJvZml0GAcgASgBSABSBnByb2ZpdIgBARIaCghwcmljZVN0chgIIAEoCVIIcHJpY2VT'
    'dHISIAoLcXVhbnRpdHlTdHIYCSABKAlSC3F1YW50aXR5U3RyEhwKCXByb2ZpdFN0chgKIAEoCV'
    'IJcHJvZml0U3RyQgkKB19wcm9maXQ=');

@$core.Deprecated('Use symbolLimitsRequestDescriptor instead')
const SymbolLimitsRequest$json = {
  '1': 'SymbolLimitsRequest',
  '2': [
    {'1': 'symbol', '3': 1, '4': 1, '5': 9, '10': 'symbol'},
  ],
};

/// Descriptor for `SymbolLimitsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List symbolLimitsRequestDescriptor =
    $convert.base64Decode(
        'ChNTeW1ib2xMaW1pdHNSZXF1ZXN0EhYKBnN5bWJvbBgBIAEoCVIGc3ltYm9s');

@$core.Deprecated('Use symbolLimitsResponseDescriptor instead')
const SymbolLimitsResponse$json = {
  '1': 'SymbolLimitsResponse',
  '2': [
    {'1': 'symbol', '3': 1, '4': 1, '5': 9, '10': 'symbol'},
    {'1': 'minQty', '3': 2, '4': 1, '5': 1, '10': 'minQty'},
    {'1': 'maxQty', '3': 3, '4': 1, '5': 1, '10': 'maxQty'},
    {'1': 'stepSize', '3': 4, '4': 1, '5': 1, '10': 'stepSize'},
    {'1': 'minNotional', '3': 5, '4': 1, '5': 1, '10': 'minNotional'},
    {'1': 'minQtyStr', '3': 6, '4': 1, '5': 9, '10': 'minQtyStr'},
    {'1': 'maxQtyStr', '3': 7, '4': 1, '5': 9, '10': 'maxQtyStr'},
    {'1': 'stepSizeStr', '3': 8, '4': 1, '5': 9, '10': 'stepSizeStr'},
    {'1': 'minNotionalStr', '3': 9, '4': 1, '5': 9, '10': 'minNotionalStr'},
    {'1': 'makerFee', '3': 10, '4': 1, '5': 1, '10': 'makerFee'},
    {'1': 'takerFee', '3': 11, '4': 1, '5': 1, '10': 'takerFee'},
    {'1': 'feeCurrency', '3': 12, '4': 1, '5': 9, '10': 'feeCurrency'},
    {
      '1': 'isDiscountActive',
      '3': 13,
      '4': 1,
      '5': 8,
      '10': 'isDiscountActive'
    },
    {
      '1': 'discountPercentage',
      '3': 14,
      '4': 1,
      '5': 1,
      '10': 'discountPercentage'
    },
    {'1': 'lastUpdated', '3': 15, '4': 1, '5': 3, '10': 'lastUpdated'},
  ],
};

/// Descriptor for `SymbolLimitsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List symbolLimitsResponseDescriptor = $convert.base64Decode(
    'ChRTeW1ib2xMaW1pdHNSZXNwb25zZRIWCgZzeW1ib2wYASABKAlSBnN5bWJvbBIWCgZtaW5RdH'
    'kYAiABKAFSBm1pblF0eRIWCgZtYXhRdHkYAyABKAFSBm1heFF0eRIaCghzdGVwU2l6ZRgEIAEo'
    'AVIIc3RlcFNpemUSIAoLbWluTm90aW9uYWwYBSABKAFSC21pbk5vdGlvbmFsEhwKCW1pblF0eV'
    'N0chgGIAEoCVIJbWluUXR5U3RyEhwKCW1heFF0eVN0chgHIAEoCVIJbWF4UXR5U3RyEiAKC3N0'
    'ZXBTaXplU3RyGAggASgJUgtzdGVwU2l6ZVN0chImCg5taW5Ob3Rpb25hbFN0chgJIAEoCVIObW'
    'luTm90aW9uYWxTdHISGgoIbWFrZXJGZWUYCiABKAFSCG1ha2VyRmVlEhoKCHRha2VyRmVlGAsg'
    'ASgBUgh0YWtlckZlZRIgCgtmZWVDdXJyZW5jeRgMIAEoCVILZmVlQ3VycmVuY3kSKgoQaXNEaX'
    'Njb3VudEFjdGl2ZRgNIAEoCFIQaXNEaXNjb3VudEFjdGl2ZRIuChJkaXNjb3VudFBlcmNlbnRh'
    'Z2UYDiABKAFSEmRpc2NvdW50UGVyY2VudGFnZRIgCgtsYXN0VXBkYXRlZBgPIAEoA1ILbGFzdF'
    'VwZGF0ZWQ=');

@$core.Deprecated('Use openOrdersRequestDescriptor instead')
const OpenOrdersRequest$json = {
  '1': 'OpenOrdersRequest',
  '2': [
    {'1': 'symbol', '3': 1, '4': 1, '5': 9, '10': 'symbol'},
  ],
};

/// Descriptor for `OpenOrdersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List openOrdersRequestDescriptor = $convert.base64Decode(
    'ChFPcGVuT3JkZXJzUmVxdWVzdBIWCgZzeW1ib2wYASABKAlSBnN5bWJvbA==');

@$core.Deprecated('Use openOrdersResponseDescriptor instead')
const OpenOrdersResponse$json = {
  '1': 'OpenOrdersResponse',
  '2': [
    {
      '1': 'orders',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.trading.v1.OrderStatus',
      '10': 'orders'
    },
  ],
};

/// Descriptor for `OpenOrdersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List openOrdersResponseDescriptor = $convert.base64Decode(
    'ChJPcGVuT3JkZXJzUmVzcG9uc2USLwoGb3JkZXJzGAEgAygLMhcudHJhZGluZy52MS5PcmRlcl'
    'N0YXR1c1IGb3JkZXJz');

@$core.Deprecated('Use orderStatusDescriptor instead')
const OrderStatus$json = {
  '1': 'OrderStatus',
  '2': [
    {'1': 'symbol', '3': 1, '4': 1, '5': 9, '10': 'symbol'},
    {'1': 'orderId', '3': 2, '4': 1, '5': 3, '10': 'orderId'},
    {'1': 'clientOrderId', '3': 3, '4': 1, '5': 9, '10': 'clientOrderId'},
    {'1': 'price', '3': 4, '4': 1, '5': 1, '10': 'price'},
    {'1': 'origQty', '3': 5, '4': 1, '5': 1, '10': 'origQty'},
    {'1': 'executedQty', '3': 6, '4': 1, '5': 1, '10': 'executedQty'},
    {'1': 'status', '3': 7, '4': 1, '5': 9, '10': 'status'},
    {'1': 'timeInForce', '3': 8, '4': 1, '5': 9, '10': 'timeInForce'},
    {'1': 'type', '3': 9, '4': 1, '5': 9, '10': 'type'},
    {'1': 'side', '3': 10, '4': 1, '5': 9, '10': 'side'},
    {'1': 'time', '3': 11, '4': 1, '5': 3, '10': 'time'},
    {'1': 'priceStr', '3': 12, '4': 1, '5': 9, '10': 'priceStr'},
    {'1': 'origQtyStr', '3': 13, '4': 1, '5': 9, '10': 'origQtyStr'},
    {'1': 'executedQtyStr', '3': 14, '4': 1, '5': 9, '10': 'executedQtyStr'},
  ],
};

/// Descriptor for `OrderStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List orderStatusDescriptor = $convert.base64Decode(
    'CgtPcmRlclN0YXR1cxIWCgZzeW1ib2wYASABKAlSBnN5bWJvbBIYCgdvcmRlcklkGAIgASgDUg'
    'dvcmRlcklkEiQKDWNsaWVudE9yZGVySWQYAyABKAlSDWNsaWVudE9yZGVySWQSFAoFcHJpY2UY'
    'BCABKAFSBXByaWNlEhgKB29yaWdRdHkYBSABKAFSB29yaWdRdHkSIAoLZXhlY3V0ZWRRdHkYBi'
    'ABKAFSC2V4ZWN1dGVkUXR5EhYKBnN0YXR1cxgHIAEoCVIGc3RhdHVzEiAKC3RpbWVJbkZvcmNl'
    'GAggASgJUgt0aW1lSW5Gb3JjZRISCgR0eXBlGAkgASgJUgR0eXBlEhIKBHNpZGUYCiABKAlSBH'
    'NpZGUSEgoEdGltZRgLIAEoA1IEdGltZRIaCghwcmljZVN0chgMIAEoCVIIcHJpY2VTdHISHgoK'
    'b3JpZ1F0eVN0chgNIAEoCVIKb3JpZ1F0eVN0chImCg5leGVjdXRlZFF0eVN0chgOIAEoCVIOZX'
    'hlY3V0ZWRRdHlTdHI=');

@$core.Deprecated('Use cancelOrderRequestDescriptor instead')
const CancelOrderRequest$json = {
  '1': 'CancelOrderRequest',
  '2': [
    {'1': 'symbol', '3': 1, '4': 1, '5': 9, '10': 'symbol'},
    {'1': 'orderId', '3': 2, '4': 1, '5': 3, '10': 'orderId'},
  ],
};

/// Descriptor for `CancelOrderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelOrderRequestDescriptor = $convert.base64Decode(
    'ChJDYW5jZWxPcmRlclJlcXVlc3QSFgoGc3ltYm9sGAEgASgJUgZzeW1ib2wSGAoHb3JkZXJJZB'
    'gCIAEoA1IHb3JkZXJJZA==');

@$core.Deprecated('Use cancelOrderResponseDescriptor instead')
const CancelOrderResponse$json = {
  '1': 'CancelOrderResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `CancelOrderResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelOrderResponseDescriptor = $convert.base64Decode(
    'ChNDYW5jZWxPcmRlclJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbWVzc2'
    'FnZRgCIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use accountInfoRequestDescriptor instead')
const AccountInfoRequest$json = {
  '1': 'AccountInfoRequest',
};

/// Descriptor for `AccountInfoRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List accountInfoRequestDescriptor =
    $convert.base64Decode('ChJBY2NvdW50SW5mb1JlcXVlc3Q=');

@$core.Deprecated('Use accountInfoResponseDescriptor instead')
const AccountInfoResponse$json = {
  '1': 'AccountInfoResponse',
  '2': [
    {
      '1': 'balances',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.trading.v1.BalanceProto',
      '10': 'balances'
    },
    {
      '1': 'totalEstimatedValueUSDC',
      '3': 2,
      '4': 1,
      '5': 1,
      '10': 'totalEstimatedValueUSDC'
    },
    {
      '1': 'totalEstimatedValueUSDCStr',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'totalEstimatedValueUSDCStr'
    },
  ],
};

/// Descriptor for `AccountInfoResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List accountInfoResponseDescriptor = $convert.base64Decode(
    'ChNBY2NvdW50SW5mb1Jlc3BvbnNlEjQKCGJhbGFuY2VzGAEgAygLMhgudHJhZGluZy52MS5CYW'
    'xhbmNlUHJvdG9SCGJhbGFuY2VzEjgKF3RvdGFsRXN0aW1hdGVkVmFsdWVVU0RDGAIgASgBUhd0'
    'b3RhbEVzdGltYXRlZFZhbHVlVVNEQxI+Chp0b3RhbEVzdGltYXRlZFZhbHVlVVNEQ1N0chgDIA'
    'EoCVIadG90YWxFc3RpbWF0ZWRWYWx1ZVVTRENTdHI=');

@$core.Deprecated('Use balanceProtoDescriptor instead')
const BalanceProto$json = {
  '1': 'BalanceProto',
  '2': [
    {'1': 'asset', '3': 1, '4': 1, '5': 9, '10': 'asset'},
    {'1': 'free', '3': 2, '4': 1, '5': 1, '10': 'free'},
    {'1': 'locked', '3': 3, '4': 1, '5': 1, '10': 'locked'},
    {
      '1': 'estimatedValueUSDC',
      '3': 4,
      '4': 1,
      '5': 1,
      '10': 'estimatedValueUSDC'
    },
    {'1': 'freeStr', '3': 5, '4': 1, '5': 9, '10': 'freeStr'},
    {'1': 'lockedStr', '3': 6, '4': 1, '5': 9, '10': 'lockedStr'},
    {
      '1': 'estimatedValueUSDCStr',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'estimatedValueUSDCStr'
    },
  ],
};

/// Descriptor for `BalanceProto`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List balanceProtoDescriptor = $convert.base64Decode(
    'CgxCYWxhbmNlUHJvdG8SFAoFYXNzZXQYASABKAlSBWFzc2V0EhIKBGZyZWUYAiABKAFSBGZyZW'
    'USFgoGbG9ja2VkGAMgASgBUgZsb2NrZWQSLgoSZXN0aW1hdGVkVmFsdWVVU0RDGAQgASgBUhJl'
    'c3RpbWF0ZWRWYWx1ZVVTREMSGAoHZnJlZVN0chgFIAEoCVIHZnJlZVN0chIcCglsb2NrZWRTdH'
    'IYBiABKAlSCWxvY2tlZFN0chI0ChVlc3RpbWF0ZWRWYWx1ZVVTRENTdHIYByABKAlSFWVzdGlt'
    'YXRlZFZhbHVlVVNEQ1N0cg==');

@$core.Deprecated('Use getLogSettingsRequestDescriptor instead')
const GetLogSettingsRequest$json = {
  '1': 'GetLogSettingsRequest',
};

/// Descriptor for `GetLogSettingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLogSettingsRequestDescriptor =
    $convert.base64Decode('ChVHZXRMb2dTZXR0aW5nc1JlcXVlc3Q=');

@$core.Deprecated('Use updateLogSettingsRequestDescriptor instead')
const UpdateLogSettingsRequest$json = {
  '1': 'UpdateLogSettingsRequest',
  '2': [
    {
      '1': 'logSettings',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.trading.v1.LogSettingsProto',
      '10': 'logSettings'
    },
  ],
};

/// Descriptor for `UpdateLogSettingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateLogSettingsRequestDescriptor =
    $convert.base64Decode(
        'ChhVcGRhdGVMb2dTZXR0aW5nc1JlcXVlc3QSPgoLbG9nU2V0dGluZ3MYASABKAsyHC50cmFkaW'
        '5nLnYxLkxvZ1NldHRpbmdzUHJvdG9SC2xvZ1NldHRpbmdz');

@$core.Deprecated('Use logSettingsResponseDescriptor instead')
const LogSettingsResponse$json = {
  '1': 'LogSettingsResponse',
  '2': [
    {
      '1': 'logSettings',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.trading.v1.LogSettingsProto',
      '10': 'logSettings'
    },
  ],
};

/// Descriptor for `LogSettingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logSettingsResponseDescriptor = $convert.base64Decode(
    'ChNMb2dTZXR0aW5nc1Jlc3BvbnNlEj4KC2xvZ1NldHRpbmdzGAEgASgLMhwudHJhZGluZy52MS'
    '5Mb2dTZXR0aW5nc1Byb3RvUgtsb2dTZXR0aW5ncw==');

@$core.Deprecated('Use logSettingsProtoDescriptor instead')
const LogSettingsProto$json = {
  '1': 'LogSettingsProto',
  '2': [
    {'1': 'logLevel', '3': 1, '4': 1, '5': 9, '10': 'logLevel'},
    {
      '1': 'enableFileLogging',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'enableFileLogging'
    },
    {
      '1': 'enableConsoleLogging',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'enableConsoleLogging'
    },
  ],
};

/// Descriptor for `LogSettingsProto`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logSettingsProtoDescriptor = $convert.base64Decode(
    'ChBMb2dTZXR0aW5nc1Byb3RvEhoKCGxvZ0xldmVsGAEgASgJUghsb2dMZXZlbBIsChFlbmFibG'
    'VGaWxlTG9nZ2luZxgCIAEoCFIRZW5hYmxlRmlsZUxvZ2dpbmcSMgoUZW5hYmxlQ29uc29sZUxv'
    'Z2dpbmcYAyABKAhSFGVuYWJsZUNvbnNvbGVMb2dnaW5n');

@$core.Deprecated('Use logEntryDescriptor instead')
const LogEntry$json = {
  '1': 'LogEntry',
  '2': [
    {'1': 'level', '3': 1, '4': 1, '5': 9, '10': 'level'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'timestamp', '3': 3, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'serviceName', '3': 4, '4': 1, '5': 9, '10': 'serviceName'},
  ],
};

/// Descriptor for `LogEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logEntryDescriptor = $convert.base64Decode(
    'CghMb2dFbnRyeRIUCgVsZXZlbBgBIAEoCVIFbGV2ZWwSGAoHbWVzc2FnZRgCIAEoCVIHbWVzc2'
    'FnZRIcCgl0aW1lc3RhbXAYAyABKANSCXRpbWVzdGFtcBIgCgtzZXJ2aWNlTmFtZRgEIAEoCVIL'
    'c2VydmljZU5hbWU=');

@$core.Deprecated('Use streamCurrentPriceRequestDescriptor instead')
const StreamCurrentPriceRequest$json = {
  '1': 'StreamCurrentPriceRequest',
  '2': [
    {'1': 'symbol', '3': 1, '4': 1, '5': 9, '10': 'symbol'},
  ],
};

/// Descriptor for `StreamCurrentPriceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamCurrentPriceRequestDescriptor =
    $convert.base64Decode(
        'ChlTdHJlYW1DdXJyZW50UHJpY2VSZXF1ZXN0EhYKBnN5bWJvbBgBIAEoCVIGc3ltYm9s');

@$core.Deprecated('Use priceResponseDescriptor instead')
const PriceResponse$json = {
  '1': 'PriceResponse',
  '2': [
    {'1': 'price', '3': 1, '4': 1, '5': 1, '10': 'price'},
    {'1': 'priceChange24h', '3': 2, '4': 1, '5': 1, '10': 'priceChange24h'},
    {
      '1': 'priceChangeAbsolute24h',
      '3': 3,
      '4': 1,
      '5': 1,
      '10': 'priceChangeAbsolute24h'
    },
    {'1': 'highPrice24h', '3': 4, '4': 1, '5': 1, '10': 'highPrice24h'},
    {'1': 'lowPrice24h', '3': 5, '4': 1, '5': 1, '10': 'lowPrice24h'},
    {'1': 'volume24h', '3': 6, '4': 1, '5': 1, '10': 'volume24h'},
    {'1': 'priceStr', '3': 7, '4': 1, '5': 9, '10': 'priceStr'},
    {
      '1': 'priceChange24hStr',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'priceChange24hStr'
    },
    {
      '1': 'priceChangeAbsolute24hStr',
      '3': 9,
      '4': 1,
      '5': 9,
      '10': 'priceChangeAbsolute24hStr'
    },
    {'1': 'highPrice24hStr', '3': 10, '4': 1, '5': 9, '10': 'highPrice24hStr'},
    {'1': 'lowPrice24hStr', '3': 11, '4': 1, '5': 9, '10': 'lowPrice24hStr'},
    {'1': 'volume24hStr', '3': 12, '4': 1, '5': 9, '10': 'volume24hStr'},
  ],
};

/// Descriptor for `PriceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List priceResponseDescriptor = $convert.base64Decode(
    'Cg1QcmljZVJlc3BvbnNlEhQKBXByaWNlGAEgASgBUgVwcmljZRImCg5wcmljZUNoYW5nZTI0aB'
    'gCIAEoAVIOcHJpY2VDaGFuZ2UyNGgSNgoWcHJpY2VDaGFuZ2VBYnNvbHV0ZTI0aBgDIAEoAVIW'
    'cHJpY2VDaGFuZ2VBYnNvbHV0ZTI0aBIiCgxoaWdoUHJpY2UyNGgYBCABKAFSDGhpZ2hQcmljZT'
    'I0aBIgCgtsb3dQcmljZTI0aBgFIAEoAVILbG93UHJpY2UyNGgSHAoJdm9sdW1lMjRoGAYgASgB'
    'Ugl2b2x1bWUyNGgSGgoIcHJpY2VTdHIYByABKAlSCHByaWNlU3RyEiwKEXByaWNlQ2hhbmdlMj'
    'RoU3RyGAggASgJUhFwcmljZUNoYW5nZTI0aFN0chI8ChlwcmljZUNoYW5nZUFic29sdXRlMjRo'
    'U3RyGAkgASgJUhlwcmljZUNoYW5nZUFic29sdXRlMjRoU3RyEigKD2hpZ2hQcmljZTI0aFN0ch'
    'gKIAEoCVIPaGlnaFByaWNlMjRoU3RyEiYKDmxvd1ByaWNlMjRoU3RyGAsgASgJUg5sb3dQcmlj'
    'ZTI0aFN0chIiCgx2b2x1bWUyNGhTdHIYDCABKAlSDHZvbHVtZTI0aFN0cg==');

@$core.Deprecated('Use getSymbolFeesRequestDescriptor instead')
const GetSymbolFeesRequest$json = {
  '1': 'GetSymbolFeesRequest',
  '2': [
    {'1': 'symbol', '3': 1, '4': 1, '5': 9, '10': 'symbol'},
  ],
};

/// Descriptor for `GetSymbolFeesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSymbolFeesRequestDescriptor =
    $convert.base64Decode(
        'ChRHZXRTeW1ib2xGZWVzUmVxdWVzdBIWCgZzeW1ib2wYASABKAlSBnN5bWJvbA==');

@$core.Deprecated('Use symbolFeesResponseDescriptor instead')
const SymbolFeesResponse$json = {
  '1': 'SymbolFeesResponse',
  '2': [
    {'1': 'symbol', '3': 1, '4': 1, '5': 9, '10': 'symbol'},
    {'1': 'makerFee', '3': 2, '4': 1, '5': 1, '10': 'makerFee'},
    {'1': 'takerFee', '3': 3, '4': 1, '5': 1, '10': 'takerFee'},
    {'1': 'feeCurrency', '3': 4, '4': 1, '5': 9, '10': 'feeCurrency'},
    {'1': 'isDiscountActive', '3': 5, '4': 1, '5': 8, '10': 'isDiscountActive'},
    {
      '1': 'discountPercentage',
      '3': 6,
      '4': 1,
      '5': 1,
      '10': 'discountPercentage'
    },
    {'1': 'lastUpdated', '3': 7, '4': 1, '5': 3, '10': 'lastUpdated'},
  ],
};

/// Descriptor for `SymbolFeesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List symbolFeesResponseDescriptor = $convert.base64Decode(
    'ChJTeW1ib2xGZWVzUmVzcG9uc2USFgoGc3ltYm9sGAEgASgJUgZzeW1ib2wSGgoIbWFrZXJGZW'
    'UYAiABKAFSCG1ha2VyRmVlEhoKCHRha2VyRmVlGAMgASgBUgh0YWtlckZlZRIgCgtmZWVDdXJy'
    'ZW5jeRgEIAEoCVILZmVlQ3VycmVuY3kSKgoQaXNEaXNjb3VudEFjdGl2ZRgFIAEoCFIQaXNEaX'
    'Njb3VudEFjdGl2ZRIuChJkaXNjb3VudFBlcmNlbnRhZ2UYBiABKAFSEmRpc2NvdW50UGVyY2Vu'
    'dGFnZRIgCgtsYXN0VXBkYXRlZBgHIAEoA1ILbGFzdFVwZGF0ZWQ=');

@$core.Deprecated('Use allSymbolFeesResponseDescriptor instead')
const AllSymbolFeesResponse$json = {
  '1': 'AllSymbolFeesResponse',
  '2': [
    {
      '1': 'symbolFees',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.trading.v1.SymbolFeesResponse',
      '10': 'symbolFees'
    },
  ],
};

/// Descriptor for `AllSymbolFeesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List allSymbolFeesResponseDescriptor = $convert.base64Decode(
    'ChVBbGxTeW1ib2xGZWVzUmVzcG9uc2USPgoKc3ltYm9sRmVlcxgBIAMoCzIeLnRyYWRpbmcudj'
    'EuU3ltYm9sRmVlc1Jlc3BvbnNlUgpzeW1ib2xGZWVz');

@$core.Deprecated('Use statusReportResponseDescriptor instead')
const StatusReportResponse$json = {
  '1': 'StatusReportResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `StatusReportResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statusReportResponseDescriptor = $convert.base64Decode(
    'ChRTdGF0dXNSZXBvcnRSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3'
    'NhZ2UYAiABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use startBacktestRequestDescriptor instead')
const StartBacktestRequest$json = {
  '1': 'StartBacktestRequest',
  '2': [
    {'1': 'symbol', '3': 1, '4': 1, '5': 9, '10': 'symbol'},
    {'1': 'startTime', '3': 2, '4': 1, '5': 3, '10': 'startTime'},
    {'1': 'endTime', '3': 3, '4': 1, '5': 3, '10': 'endTime'},
    {'1': 'interval', '3': 4, '4': 1, '5': 9, '10': 'interval'},
    {'1': 'initialBalance', '3': 5, '4': 1, '5': 1, '10': 'initialBalance'},
    {
      '1': 'settings',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.trading.v1.Settings',
      '10': 'settings'
    },
  ],
};

/// Descriptor for `StartBacktestRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startBacktestRequestDescriptor = $convert.base64Decode(
    'ChRTdGFydEJhY2t0ZXN0UmVxdWVzdBIWCgZzeW1ib2wYASABKAlSBnN5bWJvbBIcCglzdGFydF'
    'RpbWUYAiABKANSCXN0YXJ0VGltZRIYCgdlbmRUaW1lGAMgASgDUgdlbmRUaW1lEhoKCGludGVy'
    'dmFsGAQgASgJUghpbnRlcnZhbBImCg5pbml0aWFsQmFsYW5jZRgFIAEoAVIOaW5pdGlhbEJhbG'
    'FuY2USMAoIc2V0dGluZ3MYBiABKAsyFC50cmFkaW5nLnYxLlNldHRpbmdzUghzZXR0aW5ncw==');

@$core.Deprecated('Use backtestResponseDescriptor instead')
const BacktestResponse$json = {
  '1': 'BacktestResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'backtestId', '3': 3, '4': 1, '5': 9, '10': 'backtestId'},
  ],
};

/// Descriptor for `BacktestResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List backtestResponseDescriptor = $convert.base64Decode(
    'ChBCYWNrdGVzdFJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbWVzc2FnZR'
    'gCIAEoCVIHbWVzc2FnZRIeCgpiYWNrdGVzdElkGAMgASgJUgpiYWNrdGVzdElk');

@$core.Deprecated('Use getBacktestResultsRequestDescriptor instead')
const GetBacktestResultsRequest$json = {
  '1': 'GetBacktestResultsRequest',
  '2': [
    {'1': 'backtestId', '3': 1, '4': 1, '5': 9, '10': 'backtestId'},
  ],
};

/// Descriptor for `GetBacktestResultsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBacktestResultsRequestDescriptor =
    $convert.base64Decode(
        'ChlHZXRCYWNrdGVzdFJlc3VsdHNSZXF1ZXN0Eh4KCmJhY2t0ZXN0SWQYASABKAlSCmJhY2t0ZX'
        'N0SWQ=');

@$core.Deprecated('Use backtestResultsResponseDescriptor instead')
const BacktestResultsResponse$json = {
  '1': 'BacktestResultsResponse',
  '2': [
    {'1': 'backtestId', '3': 1, '4': 1, '5': 9, '10': 'backtestId'},
    {'1': 'totalProfit', '3': 2, '4': 1, '5': 1, '10': 'totalProfit'},
    {'1': 'profitPercentage', '3': 3, '4': 1, '5': 1, '10': 'profitPercentage'},
    {'1': 'tradesCount', '3': 4, '4': 1, '5': 5, '10': 'tradesCount'},
    {
      '1': 'trades',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.trading.v1.Trade',
      '10': 'trades'
    },
    {'1': 'totalProfitStr', '3': 6, '4': 1, '5': 9, '10': 'totalProfitStr'},
    {
      '1': 'profitPercentageStr',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'profitPercentageStr'
    },
  ],
};

/// Descriptor for `BacktestResultsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List backtestResultsResponseDescriptor = $convert.base64Decode(
    'ChdCYWNrdGVzdFJlc3VsdHNSZXNwb25zZRIeCgpiYWNrdGVzdElkGAEgASgJUgpiYWNrdGVzdE'
    'lkEiAKC3RvdGFsUHJvZml0GAIgASgBUgt0b3RhbFByb2ZpdBIqChBwcm9maXRQZXJjZW50YWdl'
    'GAMgASgBUhBwcm9maXRQZXJjZW50YWdlEiAKC3RyYWRlc0NvdW50GAQgASgFUgt0cmFkZXNDb3'
    'VudBIpCgZ0cmFkZXMYBSADKAsyES50cmFkaW5nLnYxLlRyYWRlUgZ0cmFkZXMSJgoOdG90YWxQ'
    'cm9maXRTdHIYBiABKAlSDnRvdGFsUHJvZml0U3RyEjAKE3Byb2ZpdFBlcmNlbnRhZ2VTdHIYBy'
    'ABKAlSE3Byb2ZpdFBlcmNlbnRhZ2VTdHI=');
