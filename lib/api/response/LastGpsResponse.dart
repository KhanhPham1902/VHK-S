class LastGpsResponse{
    final double latitude;
    final double longitude;
    final int speed;
    final String time;

    LastGpsResponse({
        required this.latitude,
        required this.longitude,
        required this.speed,
        required this.time
    });

    factory LastGpsResponse.getLastGpsData(Map<String, dynamic> json) {
        final gpsInfo = json['data']['GPSInfo'] as Map<String, dynamic>;
        return LastGpsResponse(
            latitude: gpsInfo['Latitude'] as double,
            longitude: gpsInfo['Longitude'] as double,
            speed: gpsInfo['Speed'] as int,
            time: gpsInfo['Dtime'] as String
        );
    }
}