class TokenResponse{
    final String token;
    final String refreshToken;

    TokenResponse({
        required this.token,
        required this.refreshToken,
    });

    factory TokenResponse.fromJson(Map<String, dynamic> json){
        return TokenResponse(
            token: json['token'],
            refreshToken: json['refreshToken'],
        );
    }
}