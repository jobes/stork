class Notam {
  final String facilityDesignator;
  final String notamNumber;
  final String featureName;
  final String issueDate;
  final String startDate;
  final String endDate;
  final String icaoMessage;
  final String? status;
  final String? keyword;
  final String? airportName;

  // Decoded properties
  final String id;
  final String type; // e.g. NOTAMN, NOTAMR, NOTAMC
  final String? linkedNotam;
  final String issuer; // A)
  final DateTime from; // B)
  final DateTime to; // C)
  final String? schedule; // D)
  final String msg; // E) decoded message text
  final String? lowerLimit2; // F)
  final String? upperLimit2; // G)
  final String fir; // Q) fir
  final double latitude; // Q) coordinates
  final double longitude;
  final double radius; // in meters
  final int flightLevelLowerLimit;
  final int flightLevelUpperLimit;

  Notam({
    required this.facilityDesignator,
    required this.notamNumber,
    required this.featureName,
    required this.issueDate,
    required this.startDate,
    required this.endDate,
    required this.icaoMessage,
    this.status,
    this.keyword,
    this.airportName,
    required this.id,
    required this.type,
    this.linkedNotam,
    required this.issuer,
    required this.from,
    required this.to,
    this.schedule,
    required this.msg,
    this.lowerLimit2,
    this.upperLimit2,
    required this.fir,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.flightLevelLowerLimit,
    required this.flightLevelUpperLimit,
  });

  Map<String, dynamic> toJson() => {
        'facilityDesignator': facilityDesignator,
        'notamNumber': notamNumber,
        'featureName': featureName,
        'issueDate': issueDate,
        'startDate': startDate,
        'endDate': endDate,
        'icaoMessage': icaoMessage,
        'status': status,
        'keyword': keyword,
        'airportName': airportName,
        'id': id,
        'type': type,
        'linkedNotam': linkedNotam,
        'issuer': issuer,
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
        'schedule': schedule,
        'msg': msg,
        'lowerLimit2': lowerLimit2,
        'upperLimit2': upperLimit2,
        'fir': fir,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'flightLevelLowerLimit': flightLevelLowerLimit,
        'flightLevelUpperLimit': flightLevelUpperLimit,
      };

  factory Notam.fromJson(Map<String, dynamic> json) {
    return Notam(
      facilityDesignator: json['facilityDesignator'] as String? ?? '',
      notamNumber: json['notamNumber'] as String? ?? '',
      featureName: json['featureName'] as String? ?? '',
      issueDate: json['issueDate'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      icaoMessage: json['icaoMessage'] as String? ?? '',
      status: json['status'] as String?,
      keyword: json['keyword'] as String?,
      airportName: json['airportName'] as String?,
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      linkedNotam: json['linkedNotam'] as String?,
      issuer: json['issuer'] as String? ?? '',
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
      schedule: json['schedule'] as String?,
      msg: json['msg'] as String? ?? '',
      lowerLimit2: json['lowerLimit2'] as String?,
      upperLimit2: json['upperLimit2'] as String?,
      fir: json['fir'] as String? ?? '',
      latitude: (json['latitude'] as num? ?? 0.0).toDouble(),
      longitude: (json['longitude'] as num? ?? 0.0).toDouble(),
      radius: (json['radius'] as num? ?? 0.0).toDouble(),
      flightLevelLowerLimit:
          (json['flightLevelLowerLimit'] as num? ?? 0).toInt(),
      flightLevelUpperLimit:
          (json['flightLevelUpperLimit'] as num? ?? 999).toInt(),
    );
  }
}
