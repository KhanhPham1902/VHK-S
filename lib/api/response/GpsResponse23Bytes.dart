class GpsResponse23Bytes{
    final int typeMessage;
    final double latitude;
    final double longitude;
    final int speed;

    GpsResponse23Bytes({
        required this.typeMessage,
        required this.latitude,
        required this.longitude,
        required this.speed,
    });

    factory GpsResponse23Bytes.fromJson(Map<String, dynamic> json) {
        final data = json['current'] as Map<String, dynamic>;
        return GpsResponse23Bytes(
            typeMessage: json['typeMessage'],
            latitude: data['latitude'] as double,
            longitude: data['longitude'] as double,
            speed: data['speed'] as int,
        );
    }
}