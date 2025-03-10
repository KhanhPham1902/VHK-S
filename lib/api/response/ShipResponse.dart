class ShipResponse{
    final String id;
    final String imei;
    final String shipNumber;
    final String owner;
    final String captain;
    final String phone;

    ShipResponse({
        required this.id,
        required this.imei,
        required this.shipNumber,
        required this.owner,
        required this.captain,
        required this.phone,
    });

    factory ShipResponse.getShipData(Map<String, dynamic> json){
        return ShipResponse(
            id: json['_id'],
            imei: json['Satellite_Id'],
            shipNumber: json['SerialRegister'],
            owner: json['ShipOwnerName'],
            captain: json['CaptianName'],
            phone: json['PhoneNumber'],
        );
    }

    factory ShipResponse.fromSqliteDatabase(Map<String, dynamic> map) => ShipResponse(
        id: map['idResponse'] ?? '',
        imei: map['imei'] ?? '',
        shipNumber: map['shipNumber'] ?? '',
        owner: map['owner'] ?? '',
        captain: map['captain'] ?? '',
        phone: map['phone'] ?? '',
    );
}