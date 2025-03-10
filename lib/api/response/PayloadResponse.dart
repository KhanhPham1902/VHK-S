class PayloadResponse{
    final String id;
    final String imei;
    final int monSn;
    final String sessionTime;
    final int length;
    final String payload;

    PayloadResponse({
        required this.id,
        required this.imei,
        required this.monSn,
        required this.sessionTime,
        required this.length,
        required this.payload
    });

    factory PayloadResponse.fromJson(Map<String, dynamic> json) {
        return PayloadResponse(
            id: json['id'] ?? '',
            imei: json['imei'] ?? '',
            monSn: json['monSn'] != null ? int.tryParse(json['monSn'].toString()) ?? 0 : 0,
            sessionTime: json['sessionTime'] ?? '',
            length: json['length'] != null ? int.tryParse(json['length'].toString()) ?? 0 : 0,
            payload: json['payload'] ?? ''
        );
    }

}