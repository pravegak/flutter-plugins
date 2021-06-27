part of '../health.dart';

abstract class AbstractDataPoint {}

/// A [HealthDataPoint] object corresponds to a data point captures from GoogleFit or Apple HealthKit
class HealthDataPoint extends AbstractDataPoint {
  num _value;
  HealthDataType _type;
  HealthDataUnit _unit;
  DateTime _dateFrom;
  DateTime _dateTo;
  PlatformType _platform;
  String _deviceId;
  String _sourceId;
  String _sourceName;
  String _deviceModel;

  HealthDataPoint._(
    this._value,
    this._type,
    this._unit,
    this._dateFrom,
    this._dateTo,
    this._platform,
    this._deviceId,
    this._sourceId,
    this._sourceName,
    this._deviceModel,
  ) {
    /// Set the value to minutes rather than the category
    /// returned by the native API
    if (type == HealthDataType.MINDFULNESS ||
        type == HealthDataType.SLEEP_IN_BED ||
        type == HealthDataType.SLEEP_ASLEEP ||
        type == HealthDataType.SLEEP_AWAKE) {
      this._value = _convertMinutes();
    }
  }

  double _convertMinutes() {
    int ms = dateTo.millisecondsSinceEpoch - dateFrom.millisecondsSinceEpoch;
    return ms / (1000 * 60);
  }

  /// Converts the [HealthDataPoint] to a json object
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['value'] = this.value;
    data['unit'] = this.unit;
    data['date_from'] = this.dateFrom;
    data['date_to'] = this.dateTo;
    data['data_type'] = this.type;
    data['platform_type'] = this.platform;
    data['source_id'] = this.sourceId;
    data['source_name'] = this.sourceName;
    data['device_model'] = this._deviceModel;
    return data;
  }

  /// Converts the [HealthDataPoint] to a string
  String toString() => '${this.runtimeType} - '
      'value: $value, '
      'unit: $unit, '
      'dateFrom: $dateFrom, '
      'dateTo: $dateTo, '
      'dataType: $type,'
      'platform: $platform'
      'sourceId: $sourceId,'
      'sourceName: $sourceName,';

  /// Get the quantity value of the data point
  num get value => _value;

  /// Get the start of the datetime interval
  DateTime get dateFrom => _dateFrom;

  /// Get the end of the datetime interval
  DateTime get dateTo => _dateTo;

  /// Get the type of the data point
  HealthDataType get type => _type;

  /// Get the unit of the data point
  HealthDataUnit get unit => _unit;

  /// Get the software platform of the data point
  /// (i.e. Android or iOS)
  PlatformType get platform => _platform;

  /// Get the data point type as a string
  String get typeString => _enumToString(_type);

  /// Get the data point unit as a string
  String get unitString => _enumToString(_unit);

  /// Get the id of the device from which
  /// the data point was extracted
  String get deviceId => _deviceId;

  /// Get the id of the source from which
  /// the data point was extracted
  String get sourceId => _sourceId;

  /// Get the name of the source from which
  /// the data point was extracted
  String get sourceName => _sourceName;

  String get deviceModel => _deviceModel;

  /// An equals (==) operator for comparing two data points
  /// This makes it possible to remove duplicate data points.
  @override
  bool operator ==(Object o) {
    return o is HealthDataPoint &&
        this.value == o.value &&
        this.unit == o.unit &&
        this.dateFrom == o.dateFrom &&
        this.dateTo == o.dateTo &&
        this.type == o.type &&
        this.platform == o.platform &&
        this.deviceId == o.deviceId &&
        this.sourceId == o.sourceId &&
        this.sourceName == o.sourceName;
  }

  /// Override required due to overriding the '==' operator
  @override
  int get hashCode => toJson().hashCode;
}

class WorkoutDataPoint extends AbstractDataPoint {
  late HealthDataType _type;
  late DateTime _dateFrom;
  late DateTime _dateTo;
  late PlatformType _platform;
  late String _deviceId;
  late String _sourceId;
  late String _sourceName;
  late String _deviceModel;
  late String _activityType;
  late double _totalDistance;
  late double _totalEnergyBurned;
  late double _duration;

  WorkoutDataPoint();

  WorkoutDataPoint._(
    this._type,
    this._dateFrom,
    this._dateTo,
    this._platform,
    this._deviceId,
    this._sourceId,
    this._sourceName,
    this._deviceModel,
    this._activityType,
    this._totalDistance,
    this._totalEnergyBurned,
    this._duration,
  );

  /// Converts the [HealthDataPoint] to a string
  String toString() => '${this.runtimeType} - '
      'activityType: $activityType, '
      'totalDistance: $totalDistance, '
      'total Energy Burned: $totalEnergyBurned, '
      'duration : $duration, '
      'dateFrom: $dateFrom, '
      'dateTo: $dateTo, '
      'dataType: $type,'
      'platform: $platform'
      'sourceId: $sourceId,'
      'sourceName: $sourceName,';

  /// Get the start of the datetime interval
  DateTime get dateFrom => _dateFrom;

  /// Get the end of the datetime interval
  DateTime get dateTo => _dateTo;

  /// Get the type of the data point
  HealthDataType get type => _type;

  /// Get the software platform of the data point
  /// (i.e. Android or iOS)
  PlatformType get platform => _platform;

  /// Get the data point type as a string
  String get typeString => _enumToString(_type);

  /// Get the id of the device from which
  /// the data point was extracted
  String get deviceId => _deviceId;

  /// Get the id of the source from which
  /// the data point was extracted
  String get sourceId => _sourceId;

  /// Get the name of the source from which
  /// the data point was extracted
  String get sourceName => _sourceName;

  String get deviceModel => _deviceModel;

  String get activityType => _activityType;

  double get totalDistance => _totalDistance;

  double get totalEnergyBurned => _totalEnergyBurned;

  double get duration => _duration;

  /// An equals (==) operator for comparing two data points
  /// This makes it possible to remove duplicate data points.
  @override
  bool operator ==(Object o) {
    return o is WorkoutDataPoint &&
        this.totalEnergyBurned == o.totalEnergyBurned &&
        this.duration == o.duration &&
        this.totalDistance == o.totalDistance &&
        this.activityType == o.activityType &&
        this.dateFrom == o.dateFrom &&
        this.dateTo == o.dateTo &&
        this.type == o.type &&
        this.platform == o.platform &&
        this.deviceId == o.deviceId &&
        this.sourceId == o.sourceId &&
        this.sourceName == o.sourceName;
  }

  /// Override required due to overriding the '==' operator
  @override
  int get hashCode => toString().hashCode;
}
