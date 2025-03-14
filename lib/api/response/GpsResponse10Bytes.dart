
class GpsResponse10Bytes{
    final int typeMessage;
    final double latitude;
    final double longitude;
    final int speed;
    final String time;

    GpsResponse10Bytes({
        required this.typeMessage,
        required this.latitude,
        required this.longitude,
        required this.speed,
        required this.time
    });

    factory GpsResponse10Bytes.fromJson(Map<String, dynamic> json){
        return GpsResponse10Bytes(
            typeMessage: json['typeMessage'],
            latitude: json['latitude'],
            longitude: json['longitude'],
            speed: json['speed'],
            time: json['time']
        );
    }
}