# EngSeg Mobile — Guia de Teste Completo

## Pré-requisitos

- Docker + Docker Compose instalados
- Flutter SDK instalado (`flutter doctor` sem erros)
- Emulador Android rodando ou dispositivo físico conectado
- Conta Google com acesso ao Firebase Console

---

## Passo 1: Firebase — criar projeto e registrar app

1. Acessa https://console.firebase.google.com
2. "Criar projeto" → nome: `EngSeg` → desativa Google Analytics (opcional)
3. No projeto criado → "Adicionar app" → ícone Android
4. Package name: `com.example.engseg_mobile`
5. Baixa o `google-services.json` gerado
6. Coloca o arquivo em: `android/app/google-services.json`

### Gerar Service Account para o BFF

1. Console Firebase → ⚙️ Configurações do projeto → aba "Contas de serviço"
2. "Gerar nova chave privada" → confirma → baixa o JSON
3. Substitui o arquivo em:
   `/home/mag/Documents/Java Projects/EngSeg/engseg-mobile-backend/firebase-service-account.json`

---

## Passo 2: Corrigir URLs do app

Edita `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  // Emulador Android → use 10.0.2.2
  // Dispositivo físico → use o IP da sua máquina na rede (ex: 192.168.1.x)
  static const apiBaseUrl = 'http://10.0.2.2:8080';
  static const bffBaseUrl = 'http://10.0.2.2:8081';
  static const connectTimeout = Duration(seconds: 30);
  static const receiveTimeout = Duration(seconds: 60);
}
```

---

## Passo 3: Habilitar HTTP no Android

Em `android/app/src/main/AndroidManifest.xml`, adiciona `android:usesCleartextTraffic="true"` na tag `<application>`:

```xml
<application
    android:usesCleartextTraffic="true"
    android:label="engseg_mobile"
    ...>
```

---

## Passo 4: Subir o backend

```bash
cd "/home/mag/Documents/Java Projects/EngSeg"
docker-compose up -d --build
```

Aguarda ~60–90s. Verifica que tudo subiu:

```bash
# API principal
curl http://localhost:8080/actuator/health
# → {"status":"UP"}

# BFF mobile
curl http://localhost:8081/actuator/health
# → {"status":"UP"}
```

Se o BFF travar (Firebase mal configurado), verifica os logs:

```bash
docker-compose logs -f engseg-mobile-backend
```

---

## Passo 5: Rodar o app

```bash
cd /home/mag/Documents/mobile/engseg-mobile
flutter run
```

No primeiro login, o app pede permissão de notificação → **aceitar**. Isso registra o token FCM no BFF automaticamente.

---

## Checklist de funcionalidades

### Auth
- [ ] Login com usuário existente
- [ ] SplashPage redireciona corretamente (sem workspace → tela de seleção)
- [ ] Selecionar workspace (estabelecimento) → vai para o feed
- [ ] Logout limpa sessão e volta para login

### Feed e listagem
- [ ] Feed carrega lista de NCs da API
- [ ] Filtros "abertas" e "vencidas" funcionam
- [ ] Detalhe de NC abre com dados reais

### Criação — online
- [ ] Criar NC pelo WizardPage → normas carregam da API → responsável carrega da API
- [ ] Publicar NC → aparece no feed
- [ ] Criar Desvio pelo WizardPage → publicar → aparece no feed

### Criação — offline
- [ ] Desligar Wi-Fi/dados
- [ ] Criar NC → publicar → salvo como rascunho local
- [ ] Aba Rascunhos mostra o item pendente
- [ ] Religar Wi-Fi → sync automático → rascunho some da lista

### Câmera e GPS
- [ ] Abrir câmera pelo FAB → foto tirada → GPS capturado automaticamente
- [ ] WizardPage recebe foto e coordenadas do paso anterior

### Dashboard (só perfil ENGENHEIRO)
- [ ] KPIs carregam da API (total NCs, abertas, vencidas, desvios)

### Push notifications
- [ ] Abrir o web em http://localhost
- [ ] Criar NC com "Responsável pela tratativa" = o usuário logado no mobile
- [ ] App mobile em background → notificação do sistema aparece
- [ ] App mobile em foreground → banner interno (SnackBar azul) aparece

---

## Portas dos serviços

| Serviço | Porta | URL |
|---------|-------|-----|
| engseg-api | 8080 | http://localhost:8080 |
| engseg-mobile-backend | 8081 | http://localhost:8081 |
| engseg-web | 80 | http://localhost |
| PostgreSQL | 5432 | — |
| MinIO (storage) | 9000 / 9001 | http://localhost:9001 (console) |
| Redpanda (Kafka) | 9092 | — |

---

## Troubleshooting

| Problema | Causa provável | Fix |
|----------|---------------|-----|
| `Connection refused` | Backend não subiu | `docker-compose logs engseg-api` |
| `Cleartext HTTP not permitted` | Faltou `usesCleartextTraffic` | Ver Passo 3 |
| App trava na SplashPage | API inacessível | Verificar URL no AppConfig (Passo 2) |
| Push não chega | Service account errado | Regenerar chave no Firebase Console e rebuild do BFF |
| `google-services.json not found` | Arquivo no lugar errado | Deve ficar em `android/app/google-services.json` |
| BFF não sobe | Service account inválido | `docker-compose logs engseg-mobile-backend` |
| Rascunho não sincroniza | Connectivity lento | Fechar e reabrir o app |
| Token FCM não registrado | Login antes do Firebase estar configurado | Fazer logout e login novamente |
