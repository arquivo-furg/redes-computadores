# =============================================================================
# Análise de Medições RIPE Atlas — Trabalho de Redes de Computadores
#
# Destinos: YouTube Music, Apple Music, Spotify
# Período: 29/06/2026 08:30 BRT a 30/06/2026 08:30 BRT (24 horas)
# Protocolo: Traceroute ICMP — IPv4 e IPv6
#
# Bibliotecas usadas:
#   - jsonlite : para ler os arquivos JSON do RIPE Atlas
#   - dplyr    : para manipulação e agrupamento dos dados
#   - tidyr    : para pivotar/organizar tabelas quando necessário
#   - ggplot2  : para gerar os gráficos
#
# Para instalar:
#   install.packages(c("jsonlite", "dplyr", "tidyr", "ggplot2"))
# =============================================================================

library(jsonlite)
library(dplyr)
library(tidyr)
library(ggplot2)

# =============================================================================
# 0. CONFIGURAÇÃO DE PASTAS E ARQUIVOS
# =============================================================================

# Pasta onde estão os arquivos JSON baixados do RIPE Atlas
pasta_dados <- "."

# Pasta onde os gráficos serão salvos (cria se não existir)
pasta_graficos <- "graficos"
dir.create(pasta_graficos, showWarnings = FALSE)

# Lista de arquivos de medição com destino e versão IP
lista_medicoes <- list(
  list(arquivo = file.path(pasta_dados, "youtube_ipv4.json"), destino = "YouTube Music", versao_ip = 4),
  list(arquivo = file.path(pasta_dados, "youtube_ipv6.json"), destino = "YouTube Music", versao_ip = 6),
  list(arquivo = file.path(pasta_dados, "apple_ipv4.json"),   destino = "Apple Music",   versao_ip = 4),
  list(arquivo = file.path(pasta_dados, "apple_ipv6.json"),   destino = "Apple Music",   versao_ip = 6),
  list(arquivo = file.path(pasta_dados, "spotify_ipv4.json"), destino = "Spotify",       versao_ip = 4),
  list(arquivo = file.path(pasta_dados, "spotify_ipv6.json"), destino = "Spotify",       versao_ip = 6)
)

# =============================================================================
# 1. MAPEAMENTO: PROBE → PAÍS → CONTINENTE
#
# Cada probe do RIPE Atlas tem um ID. Aqui associamos cada ID ao seu país
# e depois ao continente correspondente.
# =============================================================================

# ID da probe -> sigla do país (validado via API do RIPE Atlas)
probe_pais <- c(
  "3483"    = "US", "6882"    = "KE", "7018"    = "NC", "7623"    = "NG",
  "7634"    = "KE", "7653"    = "NG", "17797"   = "US", "22878"   = "NZ",
  "25182"   = "MX", "28898"   = "FR", "33516"   = "MX", "33674"   = "NC",
  "34005"   = "DE", "34665"   = "JP", "50383"   = "DE", "54716"   = "AU",
  "60109"   = "IN", "60396"   = "ZA", "61770"   = "FR", "62730"   = "FI",
  "62796"   = "NG", "63050"   = "NC", "1003582" = "FI", "1004065" = "SG",
  "1004598" = "MX", "1005929" = "KE", "1006482" = "AU", "1008741" = "SG",
  "1009257" = "DE", "1009342" = "NZ", "1009598" = "BR", "1010284" = "NZ",
  "1010568" = "FI", "1010884" = "IN", "1011068" = "IN", "1012985" = "ZA",
  "1013071" = "BR", "1014022" = "SG", "1014295" = "ZA", "1014593" = "US",
  "1014959" = "JP", "1015188" = "FR", "1015550" = "AU", "1015749" = "JP"
)

# Sigla do país -> nome legível em português
pais_nome <- c(
  US = "EUA", MX = "México", BR = "Brasil",
  DE = "Alemanha", FR = "França", FI = "Finlândia",
  JP = "Japão", IN = "Índia", SG = "Singapura",
  NG = "Nigéria", ZA = "África do Sul", KE = "Quênia",
  AU = "Austrália", NZ = "Nova Zelândia", NC = "Nova Caledônia"
)

# Sigla do país -> continente
pais_continente <- c(
  US = "Américas", MX = "Américas", BR = "Américas",
  DE = "Europa",   FR = "Europa",   FI = "Europa",
  JP = "Ásia",     IN = "Ásia",     SG = "Ásia",
  NG = "África",   ZA = "África",   KE = "África",
  AU = "Oceania",  NZ = "Oceania",  NC = "Oceania"
)

# Ordem dos continentes para usar nos gráficos
ordem_continentes <- c("Américas", "Europa", "Ásia", "África", "Oceania")

# Cores fixas para cada continente
cores_continentes <- c(
  "Américas" = "#E74C3C",
  "Europa"   = "#3498DB",
  "Ásia"     = "#F39C12",
  "África"   = "#27AE60",
  "Oceania"  = "#9B59B6"
)

# =============================================================================
# 2. FUNÇÕES AUXILIARES PARA EXTRAIR DADOS DO TRACEROUTE
# =============================================================================

# Operador auxiliar: retorna 'a' se não for NULL, senão retorna 'b'
`%ou%` <- function(a, b) {
  if (!is.null(a)) a else b
}

# Função que extrai o RTT mínimo e o número de saltos de UM registro de traceroute.
#
# No RIPE Atlas, cada registro de traceroute tem uma lista de hops.
# O hop 255 indica que o destino respondeu diretamente.
# Se o hop 255 existe, pegamos o RTT mínimo dos pacotes desse hop.
# Se não existe, procuramos o último hop que teve resposta válida.
extrair_rtt_e_saltos <- function(registro) {

  lista_hops <- registro$result

  # Se não tem hops, retorna nulo
  if (is.null(lista_hops) || length(lista_hops) == 0) {
    return(NULL)
  }

  rtt_minimo <- NA_real_
  numero_saltos <- NA_integer_

  # Pega o último hop da lista
  ultimo_hop <- lista_hops[[length(lista_hops)]]

  # Verifica se o último hop é o 255 (destino respondeu)
  if (!is.null(ultimo_hop$hop) && ultimo_hop$hop == 255) {

    # Extrai os RTTs dos pacotes enviados ao destino
    rtts_pacotes <- sapply(ultimo_hop$result, function(pacote) {
      pacote$rtt %ou% NA_real_
    })
    rtts_validos <- as.numeric(rtts_pacotes[!is.na(rtts_pacotes)])

    if (length(rtts_validos) > 0) {
      rtt_minimo <- min(rtts_validos)
    }

    # O número de saltos é o hop anterior ao 255
    if (length(lista_hops) >= 2) {
      numero_saltos <- as.integer(lista_hops[[length(lista_hops) - 1]]$hop)
    } else {
      numero_saltos <- 1L
    }

  } else {
    # Destino não respondeu: procura de trás pra frente o último hop com RTT válido
    for (i in rev(seq_along(lista_hops))) {
      hop_atual <- lista_hops[[i]]
      rtts_pacotes <- sapply(hop_atual$result, function(pacote) {
        pacote$rtt %ou% NA_real_
      })
      rtts_validos <- as.numeric(rtts_pacotes[!is.na(rtts_pacotes)])

      if (length(rtts_validos) > 0) {
        rtt_minimo <- min(rtts_validos)
        numero_saltos <- as.integer(hop_atual$hop)
        break
      }
    }
  }

  return(list(rtt = rtt_minimo, saltos = numero_saltos))
}

# Função que lê um arquivo JSON de medição e retorna um data.frame com os dados extraídos.
ler_arquivo_medicao <- function(caminho_arquivo, nome_destino, versao_ip) {

  cat("Lendo arquivo:", basename(caminho_arquivo), "\n")

  # Lê o JSON inteiro (cada elemento é um registro de traceroute)
  dados_brutos <- fromJSON(caminho_arquivo, flatten = FALSE, simplifyVector = FALSE)

  # Processa cada registro individualmente
  lista_linhas <- lapply(dados_brutos, function(registro) {

    resultado <- extrair_rtt_e_saltos(registro)

    # Se não conseguiu extrair nada, pula esse registro
    if (is.null(resultado)) {
      return(NULL)
    }

    # Monta uma linha do data.frame
    data.frame(
      probe_id          = as.character(registro$prb_id),
      momento_medicao   = as.POSIXct(registro$timestamp, origin = "1970-01-01", tz = "UTC"),
      versao_ip         = versao_ip,
      destino           = nome_destino,
      chegou_destino    = isTRUE(registro$destination_ip_responded),
      rtt_minimo_ms     = resultado$rtt,
      numero_saltos     = resultado$saltos,
      stringsAsFactors  = FALSE
    )
  })

  # Remove NULLs e junta tudo em um data.frame
  linhas_validas <- Filter(Negate(is.null), lista_linhas)
  do.call(rbind, linhas_validas)
}

# =============================================================================
# 3. LEITURA DE TODOS OS ARQUIVOS
# =============================================================================

# Lê cada arquivo e combina tudo num único data.frame
todos_registros <- do.call(rbind, lapply(lista_medicoes, function(medicao) {
  ler_arquivo_medicao(medicao$arquivo, medicao$destino, medicao$versao_ip)
}))

# =============================================================================
# 4. ENRIQUECIMENTO DOS DADOS (adiciona país, continente, rótulo IPv4/IPv6)
# =============================================================================

dados_completos <- todos_registros %>%
  mutate(
    # Descobre o país da probe pelo mapeamento
    sigla_pais     = probe_pais[probe_id],
    # Nome legível do país
    nome_pais      = pais_nome[sigla_pais],
    # Continente
    continente     = pais_continente[sigla_pais],
    continente     = factor(continente, levels = ordem_continentes),
    # Rótulo "IPv4" ou "IPv6"
    rotulo_ip      = paste0("IPv", versao_ip),
    # Arredonda o timestamp para a hora cheia (para agrupar por rodada)
    hora_rodada    = as.POSIXct(trunc(momento_medicao, units = "hours"))
  ) %>%
  # Remove probes que não estão no mapeamento
  filter(!is.na(sigla_pais))

cat("\nTotal de registros carregados:", nrow(dados_completos), "\n")
cat("Período:", format(min(dados_completos$momento_medicao)),
    "a", format(max(dados_completos$momento_medicao)), "\n\n")

# =============================================================================
# 5. RESUMO DE CHEGADA AO DESTINO
# =============================================================================

resumo_chegada <- dados_completos %>%
  group_by(destino, rotulo_ip) %>%
  summarise(
    total_medicoes     = n(),
    medicoes_chegaram  = sum(chegou_destino),
    percentual_chegada = round(100 * mean(chegou_destino), 1),
    .groups = "drop"
  )

cat("=== Resumo de chegada ao destino ===\n")
print(resumo_chegada)

# =============================================================================
# 6. FILTRA APENAS MEDIÇÕES QUE CHEGARAM AO DESTINO
#    (como orientado pelo enunciado do trabalho)
# =============================================================================

dados_chegaram <- dados_completos %>%
  filter(chegou_destino, !is.na(rtt_minimo_ms), !is.na(numero_saltos))

# =============================================================================
# 7. TEMA VISUAL DOS GRÁFICOS (simples e limpo)
# =============================================================================

tema_graficos <- theme_minimal(base_size = 12) +
  theme(
    plot.title       = element_text(face = "bold", size = 13),
    plot.subtitle    = element_text(size = 10, color = "gray40"),
    legend.position  = "bottom",
    panel.grid.minor = element_blank(),
    strip.text       = element_text(face = "bold")
  )

# Função para salvar gráfico em PDF
salvar_grafico <- function(nome_arquivo, largura = 10, altura = 6) {
  caminho_completo <- file.path(pasta_graficos, paste0(nome_arquivo, ".pdf"))
  ggsave(caminho_completo, width = largura, height = altura, device = "pdf")
  cat("Gráfico salvo:", caminho_completo, "\n")
}

# Cores fixas para IPv4 e IPv6
cores_ipv4_ipv6 <- c("IPv4" = "#2196F3", "IPv6" = "#FF5722")


# =============================================================================
# 8. ANÁLISE DE LATÊNCIA
# =============================================================================

# ── 8.1 Latência ao longo do tempo (mediana por rodada, por destino) ─────────

latencia_hora <- dados_chegaram %>%
  group_by(destino, rotulo_ip, hora_rodada) %>%
  summarise(rtt_mediano = median(rtt_minimo_ms), .groups = "drop")

ggplot(latencia_hora, aes(x = hora_rodada, y = rtt_mediano,
                          color = rotulo_ip)) +
  geom_line() +
  geom_point(size = 1) +
  facet_wrap(~destino, ncol = 1, scales = "free_y") +
  scale_color_manual(values = cores_ipv4_ipv6) +
  labs(
    title    = "Latência ao Longo do Tempo",
    subtitle = "Mediana do RTT mínimo por rodada horária",
    x = "Horário (UTC)", y = "RTT mínimo (ms)", color = NULL
  ) +
  tema_graficos

salvar_grafico("1_latencia_serie_temporal", largura = 11, altura = 9)

# ── 8.2 Comparação IPv4 vs IPv6 — boxplot por destino ────────────────────────

# Remove apenas os outliers muito extremos (acima do percentil 99) para legibilidade
dados_sem_outliers <- dados_chegaram %>%
  filter(rtt_minimo_ms < quantile(rtt_minimo_ms, 0.99))

ggplot(dados_sem_outliers,
       aes(x = rotulo_ip, y = rtt_minimo_ms, fill = rotulo_ip)) +
  geom_boxplot() +
  facet_wrap(~destino) +
  scale_fill_manual(values = cores_ipv4_ipv6) +
  labs(
    title    = "Distribuição de Latência: IPv4 vs IPv6",
    subtitle = "Outliers acima do percentil 99 foram removidos",
    x = NULL, y = "RTT mínimo (ms)", fill = NULL
  ) +
  tema_graficos

salvar_grafico("2_latencia_ipv4_vs_ipv6")

# ── 8.3 Latência mediana por país ────────────────────────────────────────────

latencia_pais <- dados_chegaram %>%
  group_by(destino, nome_pais, continente, rotulo_ip) %>%
  summarise(rtt_mediano = median(rtt_minimo_ms), .groups = "drop")

ggplot(latencia_pais,
       aes(x = reorder(nome_pais, rtt_mediano), y = rtt_mediano,
           fill = continente)) +
  geom_col() +
  facet_grid(rotulo_ip ~ destino) +
  scale_fill_manual(values = cores_continentes) +
  labs(
    title = "Latência Mediana por País",
    x = NULL, y = "RTT mediano (ms)", fill = "Continente"
  ) +
  tema_graficos +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8))

salvar_grafico("3_latencia_por_pais", largura = 14, altura = 8)

# ── 8.4 Latência por continente ──────────────────────────────────────────────

ggplot(dados_sem_outliers,
       aes(x = continente, y = rtt_minimo_ms, fill = continente)) +
  geom_boxplot() +
  facet_grid(rotulo_ip ~ destino) +
  scale_fill_manual(values = cores_continentes) +
  labs(
    title = "Distribuição de Latência por Continente",
    x = NULL, y = "RTT mínimo (ms)", fill = "Continente"
  ) +
  tema_graficos +
  theme(axis.text.x = element_text(angle = 30, hjust = 1, size = 9))

salvar_grafico("4_latencia_por_continente", largura = 13, altura = 8)


# =============================================================================
# 9. ANÁLISE DO NÚMERO DE SALTOS
# =============================================================================

# ── 9.1 Saltos ao longo do tempo (mediana por rodada, por destino) ───────────

saltos_hora <- dados_chegaram %>%
  group_by(destino, rotulo_ip, hora_rodada) %>%
  summarise(saltos_medianos = median(numero_saltos), .groups = "drop")

ggplot(saltos_hora, aes(x = hora_rodada, y = saltos_medianos,
                        color = rotulo_ip)) +
  geom_line() +
  geom_point(size = 1) +
  facet_wrap(~destino, ncol = 1, scales = "free_y") +
  scale_color_manual(values = cores_ipv4_ipv6) +
  labs(
    title    = "Número de Saltos ao Longo do Tempo",
    subtitle = "Mediana por rodada horária",
    x = "Horário (UTC)", y = "Número de saltos", color = NULL
  ) +
  tema_graficos

salvar_grafico("5_saltos_serie_temporal", largura = 11, altura = 9)

# ── 9.2 Comparação IPv4 vs IPv6 — boxplot de saltos por destino ──────────────

ggplot(dados_chegaram,
       aes(x = rotulo_ip, y = numero_saltos, fill = rotulo_ip)) +
  geom_boxplot() +
  facet_wrap(~destino) +
  scale_fill_manual(values = cores_ipv4_ipv6) +
  labs(
    title = "Distribuição do Número de Saltos: IPv4 vs IPv6",
    x = NULL, y = "Número de saltos", fill = NULL
  ) +
  tema_graficos

salvar_grafico("6_saltos_ipv4_vs_ipv6")

# ── 9.3 Saltos medianos por país ─────────────────────────────────────────────

saltos_pais <- dados_chegaram %>%
  group_by(destino, nome_pais, continente, rotulo_ip) %>%
  summarise(saltos_medianos = median(numero_saltos), .groups = "drop")

ggplot(saltos_pais,
       aes(x = reorder(nome_pais, saltos_medianos), y = saltos_medianos,
           fill = continente)) +
  geom_col() +
  facet_grid(rotulo_ip ~ destino) +
  scale_fill_manual(values = cores_continentes) +
  labs(
    title = "Número de Saltos Mediano por País",
    x = NULL, y = "Número de saltos (mediana)", fill = "Continente"
  ) +
  tema_graficos +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8))

salvar_grafico("7_saltos_por_pais", largura = 14, altura = 8)

# ── 9.4 Saltos por continente ────────────────────────────────────────────────

ggplot(dados_chegaram,
       aes(x = continente, y = numero_saltos, fill = continente)) +
  geom_boxplot() +
  facet_grid(rotulo_ip ~ destino) +
  scale_fill_manual(values = cores_continentes) +
  labs(
    title = "Distribuição do Número de Saltos por Continente",
    x = NULL, y = "Número de saltos", fill = "Continente"
  ) +
  tema_graficos +
  theme(axis.text.x = element_text(angle = 30, hjust = 1, size = 9))

salvar_grafico("8_saltos_por_continente", largura = 13, altura = 8)


# =============================================================================
# 10. GRÁFICO BÔNUS — TAXA DE CHEGADA AO DESTINO
# =============================================================================

taxa_chegada <- dados_completos %>%
  group_by(destino, rotulo_ip) %>%
  summarise(percentual = 100 * mean(chegou_destino), .groups = "drop")

ggplot(taxa_chegada,
       aes(x = rotulo_ip, y = percentual, fill = rotulo_ip)) +
  geom_col() +
  geom_text(aes(label = sprintf("%.1f%%", percentual)), vjust = -0.4, size = 3.5) +
  facet_wrap(~destino) +
  scale_fill_manual(values = cores_ipv4_ipv6) +
  scale_y_continuous(limits = c(0, 105)) +
  labs(
    title    = "Taxa de Medições que Chegaram ao Destino",
    subtitle = "Percentual de traceroutes com resposta do destino",
    x = NULL, y = "% de chegada", fill = NULL
  ) +
  tema_graficos

salvar_grafico("9_taxa_chegada_destino")


# =============================================================================
# 11. TABELA RESUMO FINAL (para referência no relatório)
# =============================================================================

tabela_resumo <- dados_chegaram %>%
  group_by(destino, rotulo_ip) %>%
  summarise(
    total_medicoes     = n(),
    rtt_mediano_ms     = round(median(rtt_minimo_ms), 2),
    rtt_medio_ms       = round(mean(rtt_minimo_ms), 2),
    rtt_desvio_padrao  = round(sd(rtt_minimo_ms), 2),
    saltos_medianos    = round(median(numero_saltos), 1),
    .groups = "drop"
  )

cat("\n=== RESUMO ESTATÍSTICO ===\n")
print(tabela_resumo)

cat("\nTodos os gráficos foram salvos em:", pasta_graficos, "\n")
