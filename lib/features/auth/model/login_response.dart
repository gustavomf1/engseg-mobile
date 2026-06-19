class LoginResponse {
  final String id;
  final String token;
  final String? refreshToken;
  final String nome;
  final String email;
  final String perfil; // ENGENHEIRO | TECNICO | EXTERNO
  final bool isAdmin;

  const LoginResponse({
    required this.id,
    required this.token,
    this.refreshToken,
    required this.nome,
    required this.email,
    required this.perfil,
    required this.isAdmin,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    id: json['id'] as String,
    token: json['token'] as String,
    refreshToken: json['refreshToken'] as String?,
    nome: json['nome'] as String,
    email: json['email'] as String,
    perfil: json['perfil'] as String,
    isAdmin: json['isAdmin'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'token': token,
    'refreshToken': refreshToken,
    'nome': nome,
    'email': email,
    'perfil': perfil,
    'isAdmin': isAdmin,
  };
}
