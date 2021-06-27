part of '../health.dart';

/// Main class for the Plugin
class HealthFactory {
  static const MethodChannel _channel = MethodChannel('flutter_health');
  String? _deviceId;
  final _deviceInfo = DeviceInfoPlugin();

  static PlatformType _platformType =
      Platform.isAndroid ? PlatformType.ANDROID : PlatformType.IOS;

  /// Check if a given data type is available on the platform
  bool _isDataTypeAvailable(HealthDataType dataType) =>
      _platformType == PlatformType.ANDROID
          ? _dataTypeKeysAndroid.contains(dataType)
          : _dataTypeKeysIOS.contains(dataType);

  /// Request access to GoogleFit/Apple HealthKit
  Future<bool> requestAuthorization(List<HealthDataType> types) async {
    /// If BMI is requested, then also ask for weight and height
    if (types.contains(HealthDataType.BODY_MASS_INDEX)) {
      if (!types.contains(HealthDataType.WEIGHT)) {
        types.add(HealthDataType.WEIGHT);
      }

      if (!types.contains(HealthDataType.HEIGHT)) {
        types.add(HealthDataType.HEIGHT);
      }
    }

    List<String> keys = types.map((e) => _enumToString(e)).toList();
    final bool isAuthorized =
        await _channel.invokeMethod('requestAuthorization', {'types': keys});
    return isAuthorized;
  }

  /// Calculate the BMI using the last observed height and weight values.
  // Future<List<AbstractDataPoint>> _computeAndroidBMI(
  //     DateTime startDate, DateTime endDate) async {
  //   List<AbstractDataPoint> heights =
  //       await _prepareQuery(startDate, endDate, HealthDataType.HEIGHT);

  //   if (heights.isEmpty) {
  //     return [];
  //   }

  //   List<AbstractDataPoint> weights =
  //       await _prepareQuery(startDate, endDate, HealthDataType.WEIGHT);

  //   double h = heights.last.value.toDouble();

  //   const dataType = HealthDataType.BODY_MASS_INDEX;
  //   final unit = _dataTypeToUnit[dataType]!;

  //   final bmiHealthPoints = <HealthDataPoint>[];
  //   for (var i = 0; i < weights.length; i++) {
  //     final bmiValue = weights[i].value.toDouble() / (h * h);
  //     final x = HealthDataPoint._(bmiValue, dataType, unit, weights[i].dateFrom,
  //         weights[i].dateTo, _platformType, _deviceId!, '', '', 'android');

  //     bmiHealthPoints.add(x);
  //   }
  //   return bmiHealthPoints;
  // }

  /// Get an array of [HealthDataPoint] from an array of [HealthDataType]
  Future<List<WorkoutDataPoint>> getHealthDataFromTypes(
      DateTime startDate, DateTime endDate, List<HealthDataType> types) async {
    final dataPoints = <WorkoutDataPoint>[];

    for (var type in types) {
      final result = await _prepareQuery(startDate, endDate, type);
      dataPoints.addAll(result);
    }
    return removeDuplicates(dataPoints);
  }

  /// Prepares a query, i.e. checks if the types are available, etc.
  Future<List<WorkoutDataPoint>> _prepareQuery(
      DateTime startDate, DateTime endDate, HealthDataType dataType) async {
    /// Ask for device ID only once
    _deviceId ??= _platformType == PlatformType.ANDROID
        ? (await _deviceInfo.androidInfo).androidId
        : (await _deviceInfo.iosInfo).identifierForVendor;

    /// If not implemented on platform, throw an exception
    if (!_isDataTypeAvailable(dataType)) {
      throw _HealthException(
          dataType, 'Not available on platform $_platformType');
    }

    /// If BodyMassIndex is requested on Android, calculate this manually in Dart
    // if (dataType == HealthDataType.BODY_MASS_INDEX &&
    //     _platformType == PlatformType.ANDROID) {
    //   return _computeAndroidBMI(startDate, endDate);
    // }
    return await _dataQuery(startDate, endDate, dataType);
  }

  /// The main function for fetching health data
  Future<List<WorkoutDataPoint>> _dataQuery(
      DateTime startDate, DateTime endDate, HealthDataType dataType) async {
    // Set parameters for method channel request
    final args = <String, dynamic>{
      'dataTypeKey': _enumToString(dataType),
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch
    };

    final fetchedDataPoints = await _channel.invokeMethod('getData', args);
    if (fetchedDataPoints != null) {
      return fetchedDataPoints.map<WorkoutDataPoint>((e) {
        final DateTime from =
            DateTime.fromMillisecondsSinceEpoch(e['date_from']);
        final DateTime to = DateTime.fromMillisecondsSinceEpoch(e['date_to']);
        final String sourceId = e["source_id"];
        final String sourceName = e["source_name"];
        final String deviceModel =
            e["device_model"] == null ? "manually stored" : e["device_model"];

        if (e['sample_type'] == 'workout') {
          final Double duration = e['duration'];
          final String activityType = e['workout_activity_type'];
          final Double distance = e['total_distance'];
          final Double energyBurned = e['total_energy_burned'];
          return WorkoutDataPoint._(
            dataType,
            from,
            to,
            _platformType,
            _deviceId!,
            sourceId,
            sourceName,
            deviceModel,
            activityType,
            distance,
            energyBurned,
            duration,
          );
        }
        // final num value = e['value'];
        // final unit = _dataTypeToUnit[dataType]!;
        // return HealthDataPoint._(
        //   value,
        //   dataType,
        //   unit,
        //   from,
        //   to,
        //   _platformType,
        //   _deviceId!,
        //   sourceId,
        //   sourceName,
        //   deviceModel,
        // );
      }).toList();
    } else {
      return <WorkoutDataPoint>[];
    }
  }

  /// Given an array of [HealthDataPoint]s, this method will return the array
  /// without any duplicates.
  static List<WorkoutDataPoint> removeDuplicates(
      List<WorkoutDataPoint> points) {
    final List<WorkoutDataPoint> unique = [];

    for (var p in points) {
      var seenBefore = false;
      for (var s in unique) {
        if (s == p) {
          seenBefore = true;
        }
      }
      if (!seenBefore) {
        unique.add(p);
      }
    }
    return unique;
  }
}
