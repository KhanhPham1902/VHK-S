class LoginResponse{
    final String shipId;
    final String shipName;

    LoginResponse({
        required this.shipId,
        required this.shipName,
    });

    factory LoginResponse.fromJson(Map<String, dynamic> json) {
        return LoginResponse(
            shipId: json['idTau'],
            shipName: json['tenTau'],
        );
    }
}