class MockOcorrencia {
  final String id;
  final String tipo;
  final String titulo;
  final String estabelecimento;
  final String autor;
  final String data;
  final int prazoDias;
  final String status;
  final String severidade;
  final int progresso;
  final List<String> normas;
  final bool origemMobile;
  final bool vencida;
  final bool concluida;

  const MockOcorrencia({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.estabelecimento,
    required this.autor,
    required this.data,
    required this.prazoDias,
    required this.status,
    required this.severidade,
    required this.progresso,
    this.normas = const [],
    this.origemMobile = false,
    this.vencida = false,
    this.concluida = false,
  });
}

const mockOcorrencias = [
  MockOcorrencia(
    id: 'NC-2026-0287',
    tipo: 'NC',
    titulo: 'Trabalho em altura sem ancoragem dupla na fachada do bloco C',
    estabelecimento: 'Refinaria Paulínia · Bloco C',
    autor: 'Carla Mendes',
    data: 'há 2h',
    prazoDias: 7,
    status: 'ABERTA',
    severidade: 'critico',
    progresso: 25,
    normas: ['NR-35', 'NR-06'],
    origemMobile: true,
  ),
  MockOcorrencia(
    id: 'DS-2026-0931',
    tipo: 'Desvio',
    titulo: 'EPI inadequado em soldagem MIG — luva sem proteção térmica',
    estabelecimento: 'Planta Cubatão · Caldeiraria',
    autor: 'Diego Rocha',
    data: 'há 5h',
    prazoDias: 14,
    status: 'EM_TRATAMENTO',
    severidade: 'medio',
    progresso: 60,
    origemMobile: true,
  ),
  MockOcorrencia(
    id: 'NC-2026-0285',
    tipo: 'NC',
    titulo: 'Sinalização de área classificada apagada na ala leste',
    estabelecimento: 'Terminal Santos · Pátio 4',
    autor: 'Renata Lima',
    data: 'ontem',
    prazoDias: 3,
    status: 'AGUARDANDO_APROVACAO_PLANO',
    severidade: 'alto',
    progresso: 80,
  ),
  MockOcorrencia(
    id: 'DS-2026-0928',
    tipo: 'Desvio',
    titulo: 'Extintor com lacre violado próximo à área de carga',
    estabelecimento: 'CD Guarulhos · Doca 12',
    autor: 'Marcos Silva',
    data: 'ontem',
    prazoDias: 21,
    status: 'EM_EXECUCAO',
    severidade: 'baixo',
    progresso: 40,
  ),
  MockOcorrencia(
    id: 'NC-2026-0282',
    tipo: 'NC',
    titulo: 'Espaço confinado liberado sem PT atualizada',
    estabelecimento: 'Refinaria Paulínia · Tq-204',
    autor: 'Carla Mendes',
    data: '06/05',
    prazoDias: -2,
    status: 'NAO_RESOLVIDA',
    severidade: 'critico',
    progresso: 100,
    normas: ['NR-33'],
    origemMobile: true,
    vencida: true,
  ),
  MockOcorrencia(
    id: 'NC-2026-0279',
    tipo: 'NC',
    titulo: 'Andaime sem placa de liberação visível',
    estabelecimento: 'Planta Cubatão · ETA',
    autor: 'Felipe Tanaka',
    data: '05/05',
    prazoDias: 18,
    status: 'CONCLUIDO',
    severidade: 'medio',
    progresso: 100,
    concluida: true,
  ),
];

const statusLabel = {
  'ABERTA': 'Aberta',
  'AGUARDANDO_TRATATIVA': 'Aguard. tratativa',
  'AGUARDANDO_APROVACAO_PLANO': 'Aguard. aprovação',
  'EM_AJUSTE_PELO_EXTERNO': 'Em ajuste',
  'EM_EXECUCAO': 'Em execução',
  'AGUARDANDO_VALIDACAO_FINAL': 'Aguard. validação',
  'CONCLUIDA': 'Concluída',
  'FECHADA': 'Fechada',
  'EM_TRATAMENTO': 'Em tratamento',
  'NAO_RESOLVIDA': 'Vencida',
};

const statusTone = {
  'ABERTA': 'yellow',
  'AGUARDANDO_TRATATIVA': 'blue',
  'AGUARDANDO_APROVACAO_PLANO': 'blue',
  'EM_AJUSTE_PELO_EXTERNO': 'red',
  'EM_EXECUCAO': 'purple',
  'AGUARDANDO_VALIDACAO_FINAL': 'indigo',
  'CONCLUIDA': 'green',
  'FECHADA': 'green',
  'EM_TRATAMENTO': 'blue',
  'NAO_RESOLVIDA': 'red',
};

class MockNotif {
  final String dia;
  final String tone;
  final String titulo;
  final String texto;
  final String hora;
  final bool lida;

  const MockNotif({
    required this.dia,
    required this.tone,
    required this.titulo,
    required this.texto,
    required this.hora,
    required this.lida,
  });
}

const mockNotifs = [
  MockNotif(
    dia: 'Hoje',
    tone: 'red',
    titulo: 'NC-2026-0287 atribuída a você',
    texto: '"Trabalho em altura sem ancoragem dupla…" — Refinaria Paulínia · Carla Mendes',
    hora: '14:32',
    lida: false,
  ),
  MockNotif(
    dia: 'Hoje',
    tone: 'yellow',
    titulo: 'NC-2026-0282 vence em 2 dias',
    texto: 'Tratativa pendente de validação final pelo engenheiro responsável.',
    hora: '11:08',
    lida: false,
  ),
  MockNotif(
    dia: 'Hoje',
    tone: 'green',
    titulo: 'Plano de ação aprovado',
    texto: 'NC-2026-0279 — andaime liberado por Felipe Tanaka às 09:14.',
    hora: '09:15',
    lida: true,
  ),
  MockNotif(
    dia: 'Ontem',
    tone: 'red',
    titulo: 'Plano rejeitado — NC-2026-0274',
    texto: 'Eng. responsável solicitou inclusão de barreira física antes da liberação.',
    hora: '17:42',
    lida: true,
  ),
];

class MockDraft {
  final String id;
  final String tipo;
  final String titulo;
  final int fotos;
  final bool gps;
  final String timestamp;
  final String sync;
  final int? progressPct;
  final String? protocolo;
  final String? erro;
  final String size;

  const MockDraft({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.fotos,
    required this.gps,
    required this.timestamp,
    required this.sync,
    this.progressPct,
    this.protocolo,
    this.erro,
    required this.size,
  });
}

const mockDrafts = [
  MockDraft(
    id: 'D-04',
    tipo: 'NC',
    titulo: 'Vazamento na flange da bomba P-203',
    fotos: 3,
    gps: true,
    timestamp: 'há 3min',
    sync: 'pending',
    size: '2.4 MB',
  ),
  MockDraft(
    id: 'D-03',
    tipo: 'Desvio',
    titulo: 'Operador sem protetor auricular na sala de compressores',
    fotos: 1,
    gps: true,
    timestamp: 'há 12min',
    sync: 'syncing',
    progressPct: 62,
    size: '0.8 MB',
  ),
  MockDraft(
    id: 'D-02',
    tipo: 'NC',
    titulo: 'Tubulação amarela sem identificação NBR-7195',
    fotos: 2,
    gps: true,
    timestamp: '14:02',
    sync: 'synced',
    protocolo: 'NC-2026-0288',
    size: '1.6 MB',
  ),
  MockDraft(
    id: 'D-01',
    tipo: 'Desvio',
    titulo: 'Iluminação de emergência apagada — corredor B',
    fotos: 1,
    gps: false,
    timestamp: '08:45',
    sync: 'failed',
    erro: 'Foto corrompida',
    size: '0.3 MB',
  ),
];
