class FeeResponse{
    final int balance;
    final String status;
    final String plan;
    final String paymentDate;
    final String expireDate;
    final int messageCost;

    FeeResponse({
        required this.balance,
        required this.status,
        required this.plan,
        required this.paymentDate,
        required this.expireDate,
        required this.messageCost,
    });

    factory FeeResponse.fromJson(Map<String, dynamic> json) {
        return FeeResponse(
            balance: json['cost'] != null ? int.tryParse(json['cost'].toString()) ?? 0 : 0,
            status: json['trangThai'] ?? '',
            plan: json['goiCuoc'] ?? '',
            paymentDate: json['ngayDongCuoc'] ?? '',
            expireDate: json['ngayHetHanCuoc'] ?? '',
            messageCost: json['costTinNhan'] != null ? int.tryParse(json['costTinNhan'].toString()) ?? 0 : 0,
        );
    }
}