class GpsResponse15Bytes{
    final int typeMessage;
    final double latitude;
    final double longitude;
    final int speed;
    final String time;

    GpsResponse15Bytes({
        required this.typeMessage,
        required this.latitude,
        required this.longitude,
        required this.speed,
        required this.time
    });

    factory GpsResponse15Bytes.fromJson(Map<String, dynamic> json){
        final status = json['status'] as Map<String, dynamic>;
        return GpsResponse15Bytes(
            typeMessage: json['typeMessage'],
            latitude: json['latitude'],
            longitude: json['longitude'],
            speed: json['speed'],
            time: json['time']
        );
    }
}