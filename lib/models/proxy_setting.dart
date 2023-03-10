class ProxySettings {
  final String host;
  final int port;
  final String? username;
  final String? password;

  ProxySettings({
    required this.host,
    required this.port,
    this.username,
    this.password,
  });
}
