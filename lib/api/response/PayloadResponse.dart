class PayloadResponse {
    final String imei;
    final String transmitTime;
    final int byteCount;
    final String payload;

    PayloadResponse({
        required this.imei,
        required this.transmitTime,
        required this.byteCount,
        required this.payload,
    });

    factory PayloadResponse.fromMap(Map<String, dynamic> json) {
        return PayloadResponse(
            imei: json['imei'] ?? '',
            transmitTime: json['transmit_time'] ?? '',
            byteCount: int.tryParse(json['byteCount']?.toString() ?? '0') ?? 0,
            payload: json['data'] ?? '',
        );
    }

    static List<PayloadResponse> fromJson(Map<String, dynamic> json) {
        if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
            final data = json['data'];
            if (data.containsKey('messages') && data['messages'] is List) {
                return (data['messages'] as List)
                    .map((msg) => PayloadResponse.fromMap(msg as Map<String, dynamic>))
                    .toList();
            }
        }
        return [];
    }
}
