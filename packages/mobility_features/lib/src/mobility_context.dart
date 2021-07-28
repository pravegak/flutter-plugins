part of mobility_features;

/// Daily mobility context.
/// All Stops and Moves should be on the same date.
/// Places are all places for which the duration
/// on the given data is greater than 0
class MobilityContext {
  List<Stop> _stops;
  List<Place>? _places, _significantPlaces;
  Place? _homePlace;

  List<Move> _moves;
  DateTime? _timestamp, _date;
  late _HourMatrix _hourMatrix;

  /// Features
  int? _numberOfPlaces;
  double? _locationVariance,
      _entropy,
      _normalizedEntropy,
      _homeStay,
      _distanceTravelled;
  List<MobilityContext>? contexts;

  /// Private constructor, cannot be instantiated from outside
  MobilityContext._(this._stops, this._places, this._moves, this._date,
      {this.contexts}) {
    _timestamp = DateTime.now();

    // If contexts array is null, init to empty array
    contexts = contexts ?? [];

    _significantPlaces =
        _places!.where((p) => p.duration > Duration(minutes: 3)).toList();

    // Compute all the features
    _numberOfPlaces = _calculateNumberOfSignificantPlaces();

    _hourMatrix = _HourMatrix.fromStops(_stops, _places!.length);

    _homePlace = _findHomePlaceToday();

    _homeStay = _calculateHomeStay();

    _locationVariance = _calculateLocationVariance();

    _entropy = _calculateEntropy();

    _normalizedEntropy = _calculateNormalizedEntropy();

    _distanceTravelled = _calculateDistanceTravelled();
  }

  // Get the date of the context
  DateTime? get date => _date;

  /// Get stops today
  List<Stop> get stops => _stops;

  /// Get moves today
  List<Move> get moves => _moves;

  /// Get places today
  List<Place>? get places => _places;

  /// Get all the significant places (places with a minimum duration)
  List<Place>? get significantPlaces => _significantPlaces;

  /// Get the timestamp at which the features were computed
  DateTime? get timestamp => _timestamp;

  /// Get the home place cluster
  Place? get homePlace => _homePlace;

  /// Number of Places today
  int? get numberOfSignificantPlaces => _numberOfPlaces;

  /// Home Stay Percentage today
  /// A scalar between 0 and 1, i.e. from 0% to 100%
  double? get homeStay => _homeStay;

  /// Location Variance today
  double? get locationVariance => _locationVariance;

  /// Entropy
  /// High entropy: Time is spent evenly among all places
  /// Low  entropy: Time is mainly spent at a few of the places
  double? get entropy => _entropy;

  /// Normalized entropy,
  /// a scalar between 0 and 1
  double? get normalizedEntropy => _normalizedEntropy;

  /// Distance travelled today, in meters
  double? get distanceTravelled => _distanceTravelled;

  /// Private number of places calculation
  int _calculateNumberOfSignificantPlaces() => significantPlaces!.length;

  /// Private home stay calculation
  double _calculateHomeStay() {
    if (stops.isEmpty) return -1.0;

    // Latest known sample time
    DateTime latestTime = _stops.last.departure;

    // Total time elapsed from midnight until the last stop
    int totalTime = latestTime.millisecondsSinceEpoch -
        latestTime.midnight.millisecondsSinceEpoch;

    // Find todays home id, if no home exists today return -1.0
    if (_hourMatrix.homePlaceId == -1) {
      return -1.0;
    }

    int homeTime = stops
        .where((s) => s.placeId == _hourMatrix.homePlaceId)
        .map((s) => s.duration.inMilliseconds)
        .fold(0, (a, b) => a + b);

    return homeTime.toDouble() / totalTime.toDouble();
  }

  Place? _findHomePlaceToday() {
    int home = _hourMatrix.homePlaceId;
    if (home == -1) {
      return null;
    }
    return _places!.where((p) => p.id == _hourMatrix.homePlaceId).first;
  }

  /// Location variance calculation
  double _calculateLocationVariance() {
    // Require at least 2 observations
    if (_stops.length < 2) {
      return 0.0;
    }
    double latStd = Stats.fromData(_stops.map((s) => (s.geoLocation.latitude)))
        .standardDeviation as double;

    double lonStd = Stats.fromData(_stops.map((s) => (s.geoLocation.longitude)))
        .standardDeviation as double;
    return log(latStd * latStd + lonStd * lonStd + 1);
  }

  double _calculateEntropy() {
    // If no places were visited return -1.0
    if (places!.isEmpty) {
      return -1.0;
    }
    // The Entropy is zero when one outcome is certain to occur.
    else if (places!.length == 1) {
      return 0.0;
    }
    // Calculate time spent at different places
    List<Duration> durations =
        places!.map((p) => p.durationForDate(date)).toList();

    Duration totalTimeSpent = durations.fold(Duration(), (a, b) => a + b);

    List<double> distribution = durations
        .map((d) => (d.inMilliseconds.toDouble() /
            totalTimeSpent.inMilliseconds.toDouble()))
        .toList();

    return -distribution.map((p) => p * log(p)).reduce((a, b) => (a + b));
  }

  /// Private normalized entropy calculation
  double _calculateNormalizedEntropy() {
    if (places!.length == 1) {
      return 0.0;
    }
    return entropy! / log(places!.length);
  }

  /// Private distance travelled calculation
  double _calculateDistanceTravelled() {
    return _moves.map((m) => (m.distance)).fold(0.0, (a, b) => a + b!);
  }

  Map<String, dynamic> toJson() => {
        "date": date!.toIso8601String(),
        "computed_at": timestamp!.toIso8601String(),
        "num_of_stops": stops.length,
        "num_of_moves": moves.length,
        "num_of_significant_places": significantPlaces!.length,
        "normalized_entropy": normalizedEntropy,
        "home_stay": homeStay,
        "distance_travelled": distanceTravelled,
        "location_variance": locationVariance
      };
}

//  /// Routine index (overlap) calculation
//  double _calculateRoutineIndex() {
//    /// We require at least 2 days to compute the routine index
//    if (contexts.isEmpty) return -1.0;
//
//    /// Compute the HourMatrix for each context that is older
//    List<_HourMatrix> matrices = contexts
//        .where((c) => c.date.isBefore(this.date))
//        .map((c) => c._hourMatrix)
//        .toList();
//
//    if (matrices.isEmpty) return -1.0;
//
//    /// Compute the 'average day' from the matrices
//    _HourMatrix routine = _HourMatrix.routineMatrix(matrices);
//
//    /// Compute the overlap between the 'average day' and today
//    return _hourMatrix.computeOverlap(routine);
//  }
