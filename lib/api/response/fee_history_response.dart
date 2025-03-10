class FeeHistoryResponse{
    final int deposit;
    final int balance;
    final String depositTime;
    final String type;

    FeeHistoryResponse({
        required this.deposit,
        required this.balance,
        required this.depositTime,
        required this.type
    });

    factory FeeHistoryResponse.fromJson(Map<String, dynamic> json){
        return FeeHistoryResponse(
            deposit: json['cost'],
            balance: json['costdu'],
            depositTime: json['ngaythanhtoan'],
            type: json['loaigiaodich']
        );
    }
}