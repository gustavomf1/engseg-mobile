/// Rotas de criação de NC/Desvio que o perfil EXTERNO não pode acessar
/// diretamente (deep link, estado salvo de navegação, etc.).
bool isExternoBlockedRoute(String matchedLocation) {
  return matchedLocation == '/camera' || matchedLocation.startsWith('/wizard');
}
