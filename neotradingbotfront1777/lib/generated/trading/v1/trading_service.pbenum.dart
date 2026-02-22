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

import 'package:protobuf/protobuf.dart' as $pb;

/// Definizione dell'enum per lo stato della strategia
class StrategyStatus extends $pb.ProtobufEnum {
  static const StrategyStatus STRATEGY_STATUS_UNSPECIFIED =
      StrategyStatus._(0, _omitEnumNames ? '' : 'STRATEGY_STATUS_UNSPECIFIED');
  static const StrategyStatus STRATEGY_STATUS_IDLE =
      StrategyStatus._(1, _omitEnumNames ? '' : 'STRATEGY_STATUS_IDLE');
  static const StrategyStatus STRATEGY_STATUS_RUNNING =
      StrategyStatus._(2, _omitEnumNames ? '' : 'STRATEGY_STATUS_RUNNING');
  static const StrategyStatus STRATEGY_STATUS_PAUSED =
      StrategyStatus._(3, _omitEnumNames ? '' : 'STRATEGY_STATUS_PAUSED');
  static const StrategyStatus STRATEGY_STATUS_ERROR =
      StrategyStatus._(4, _omitEnumNames ? '' : 'STRATEGY_STATUS_ERROR');
  static const StrategyStatus STRATEGY_STATUS_RECOVERING =
      StrategyStatus._(5, _omitEnumNames ? '' : 'STRATEGY_STATUS_RECOVERING');

  static const $core.List<StrategyStatus> values = <StrategyStatus>[
    STRATEGY_STATUS_UNSPECIFIED,
    STRATEGY_STATUS_IDLE,
    STRATEGY_STATUS_RUNNING,
    STRATEGY_STATUS_PAUSED,
    STRATEGY_STATUS_ERROR,
    STRATEGY_STATUS_RECOVERING,
  ];

  static final $core.List<StrategyStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static StrategyStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const StrategyStatus._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
