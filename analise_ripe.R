# =============================================================================
# Análise de Medições RIPE Atlas — Trabalho de Redes
# Destinos: YouTube Music, Apple Music, Spotify
# Período: 29/06/2026 08:30 BRT a 30/06/2026 08:30 BRT (24h)
# Protocolo: Traceroute ICMP — IPv4 e IPv6
# =============================================================================
# Pacotes necessários (instale com install.packages() se precisar):
#   install.packages(c("jsonlite","dplyr","tidyr","ggplot2","lubridate",
#                      "patchwork","scales","forcats"))
# =============================================================================

library(jsonlite)
library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)
library(patchwork)   # combinar múltiplos ggplots
library(scales)
library(forcats)

# =============================================================================
# 0. CONFIGURAÇÃO — ajuste os caminhos conforme necessário
# =============================================================================

# Diretório onde estão os JSONs baixados do RIPE Atlas
DATA_DIR <- "."   # altere se os arquivos estiverem em outro lugar

# Diretório de saída dos gráficos
OUT_DIR <- "graficos"
dir.create(OUT_DIR, showWarnings = FALSE)

# Arquivos JSON das medições
FILES <- list(
  list(path = file.path(DATA_DIR, "youtube_ipv4.json"), dst = "YouTube Music", af = 4),
  list(path = file.path(DATA_DIR, "youtube_ipv6.json"), dst = "YouTube Music", af = 6),
  list(path = file.path(DATA_DIR, "apple_ipv4.json"),   dst = "Apple Music",   af = 4),
  list(path = file.path(DATA_DIR, "apple_ipv6.json"),   dst = "Apple Music",   af = 6),
  list(path = file.path(DATA_DIR, "spotify_ipv4.json"), dst = "Spotify",       af = 4),
  list(path = file.path(DATA_DIR, "spotify_ipv6.json"), dst = "Spotify",       af = 6)
)

# =============================================================================
# 1. MAPEAMENTO PROBE → PAÍS → CONTINENTE
#    Validado via API do RIPE Atlas (GET /api/v2/probes/?id__in=...)
# =============================================================================

probe_country <- c(
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

country_name <- c(
  US="EUA", MX="México", BR="Brasil",
  DE="Alemanha", FR="França", FI="Finlândia",
  JP="Japão", IN="Índia", SG="Singapura",
  NG="Nigéria", ZA="África do Sul", KE="Quênia",
  AU="Austrália", NZ="Nova Zelândia", NC="Nova Caledônia"
)

continent_map <- c(
  US="Américas", MX="Américas", BR="Américas",
  DE="Europa",   FR="Europa",   FI="Europa",
  JP="Ásia",     IN="Ásia",     SG="Ásia",
  NG="África",   ZA="África",   KE="África",
  AU="Oceania",  NZ="Oceania",  NC="Oceania"
)

# Ordem dos continentes para os gráficos
CONT_ORDER <- c("Américas", "Europa", "Ásia", "África", "Oceania")

# Cores por continente
CONT_COLORS <- c(
  Américas = "#E74C3C",
  Europa   = "#3498DB",
  Ásia     = "#F39C12",
  África   = "#27AE60",
  Oceania  = "#9B59B6"
)

# =============================================================================
# 2. PARSING DOS RESULTADOS DE TRACEROUTE
#    Extrai latência (RTT mínimo até o destino) e número de saltos
#    de cada registro do RIPE Atlas.
# =============================================================================

# Função auxiliar: extrai RTT mínimo e nº de saltos de um resultado de traceroute
parse_traceroute_record <- function(record) {
  hops <- record$result

  # Filtra entradas válidas (lista de hops com campo 'hop')
  if (is.null(hops) || length(hops) == 0) return(NULL)

  rtt    <- NA_real_
  n_hops <- NA_integer_

  # Hop número 255 = destino respondeu diretamente (convenção RIPE Atlas)
  last_hop <- hops[[length(hops)]]

  if (!is.null(last_hop$hop) && last_hop$hop == 255) {
    # RTT = mínimo dos pacotes enviados ao destino (hop 255)
    rtts <- sapply(last_hop$result, function(p) p$rtt %||% NA_real_)
    rtts <- as.numeric(rtts[!is.na(rtts)])
    if (length(rtts) > 0) rtt <- min(rtts)

    # Nº de saltos = número do hop anterior ao 255
    if (length(hops) >= 2) {
      n_hops <- as.integer(hops[[length(hops) - 1]]$hop)
    } else {
      n_hops <- 1L
    }
  } else {
    # Destino não respondeu: usa o último hop que teve resposta
    for (i in rev(seq_along(hops))) {
      hop <- hops[[i]]
      rtts <- sapply(hop$result, function(p) p$rtt %||% NA_real_)
      rtts <- as.numeric(rtts[!is.na(rtts)])
      if (length(rtts) > 0) {
        rtt    <- min(rtts)
        n_hops <- as.integer(hop$hop)
        break
      }
    }
  }

  list(rtt = rtt, n_hops = n_hops)
}

# Operador "or default" (substituto do %||% do rlang)
`%||%` <- function(a, b) if (!is.null(a)) a else b

# Função principal: lê um arquivo JSON e retorna data.frame processado
read_measurement <- function(path, dst, af) {
  cat("Lendo:", basename(path), "\n")
  raw <- fromJSON(path, flatten = FALSE, simplifyVector = FALSE)

  rows <- lapply(raw, function(r) {
    parsed <- parse_traceroute_record(r)
    if (is.null(parsed)) return(NULL)

    data.frame(
      prb_id    = as.character(r$prb_id),
      timestamp = as.POSIXct(r$timestamp, origin = "1970-01-01", tz = "UTC"),
      af        = af,
      dst       = dst,
      reached   = isTRUE(r$destination_ip_responded),
      rtt       = parsed$rtt,
      n_hops    = parsed$n_hops,
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, Filter(Negate(is.null), rows))
}

# Lê todos os arquivos e combina em um único data.frame
df_raw <- do.call(rbind, lapply(FILES, function(f) {
  read_measurement(f$path, f$dst, f$af)
}))

# =============================================================================
# 3. ENRIQUECIMENTO E LIMPEZA
# =============================================================================

df <- df_raw %>%
  mutate(
    country   = probe_country[prb_id],
    country_n = country_name[country],
    continent = continent_map[country],
    continent = factor(continent, levels = CONT_ORDER),
    af_label  = paste0("IPv", af),
    # Arredonda timestamp para hora cheia (para agregar por rodada)
    hora      = floor_date(timestamp, "hour")
  ) %>%
  # Remove probes sem mapeamento de país
  filter(!is.na(country))

cat("\nTotal de registros:", nrow(df), "\n")
cat("Período:", format(min(df$timestamp)), "a", format(max(df$timestamp)), "\n\n")

# Resumo de chegada ao destino por medição
df %>%
  group_by(dst, af_label) %>%
  summarise(
    total      = n(),
    chegaram   = sum(reached),
    pct_chegou = round(100 * mean(reached), 1),
    .groups = "drop"
  ) %>%
  print()

# ── Filtra apenas medições que chegaram ao destino para as análises ──────────
# (conforme orientação do trabalho: verificar se chegou ao destino)
df_ok <- df %>% filter(reached, !is.na(rtt), !is.na(n_hops))

# =============================================================================
# 4. TEMA VISUAL PADRÃO
# =============================================================================

tema_base <- theme_minimal(base_size = 12) +
  theme(
    plot.title       = element_text(face = "bold", size = 13),
    plot.subtitle    = element_text(size = 10, color = "gray40"),
    legend.position  = "bottom",
    panel.grid.minor = element_blank(),
    strip.text       = element_text(face = "bold"),
    axis.text.x      = element_text(angle = 30, hjust = 1)
  )

salvar <- function(nome, largura = 10, altura = 6) {
  path <- file.path(OUT_DIR, paste0(nome, ".pdf"))
  ggsave(path, width = largura, height = altura, device = "pdf")
  cat("Salvo:", path, "\n")
}

# =============================================================================
# 5. ANÁLISE 1 — LATÊNCIA
# =============================================================================

# ── 5.1 Latência ao longo do tempo (mediana por rodada, por destino) ─────────
df_ts_lat <- df_ok %>%
  group_by(dst, af_label, hora) %>%
  summarise(mediana_rtt = median(rtt), .groups = "drop")

ggplot(df_ts_lat, aes(x = hora, y = mediana_rtt, color = af_label)) +
  geom_line(linewidth = 0.7, alpha = 0.8) +
  geom_point(size = 1.2, alpha = 0.6) +
  facet_wrap(~dst, ncol = 1, scales = "free_y") +
  scale_color_manual(values = c("IPv4" = "#2196F3", "IPv6" = "#FF5722")) +
  scale_x_datetime(date_labels = "%d/%m\n%Hh", date_breaks = "3 hours") +
  labs(
    title    = "Latência ao Longo do Tempo",
    subtitle = "Mediana de todas as probes por rodada horária",
    x        = "Horário (UTC)",
    y        = "RTT mínimo (ms)",
    color    = NULL
  ) +
  tema_base

salvar("1_latencia_serie_temporal", largura = 11, altura = 9)

# ── 5.2 Comparação IPv4 vs IPv6 — boxplot por destino ────────────────────────
ggplot(df_ok %>% filter(rtt < quantile(rtt, 0.99)),   # remove outliers extremos
       aes(x = af_label, y = rtt, fill = af_label)) +
  geom_boxplot(outlier.size = 0.8, outlier.alpha = 0.3, alpha = 0.8) +
  stat_summary(fun = median, geom = "text",
               aes(label = sprintf("%.1f ms", after_stat(y))),
               vjust = -0.5, size = 3) +
  facet_wrap(~dst) +
  scale_fill_manual(values = c("IPv4" = "#2196F3", "IPv6" = "#FF5722")) +
  labs(
    title    = "Distribuição de Latência: IPv4 vs IPv6",
    subtitle = "99º percentil filtrado para legibilidade",
    x        = NULL, y = "RTT mínimo (ms)", fill = NULL
  ) +
  tema_base

salvar("2_latencia_ipv4_vs_ipv6")

# ── 5.3 Latência agregada por PAÍS ───────────────────────────────────────────
df_pais_lat <- df_ok %>%
  group_by(dst, country_n, continent, af_label) %>%
  summarise(
    mediana = median(rtt),
    p25     = quantile(rtt, 0.25),
    p75     = quantile(rtt, 0.75),
    .groups = "drop"
  ) %>%
  # Ordena países por continente e depois por mediana IPv4
  arrange(continent, mediana) %>%
  mutate(country_n = fct_inorder(country_n))

ggplot(df_pais_lat, aes(x = country_n, y = mediana, fill = continent)) +
  geom_col(position = "dodge") +
  geom_errorbar(aes(ymin = p25, ymax = p75),
                width = 0.3, linewidth = 0.5, alpha = 0.7) +
  facet_grid(af_label ~ dst) +
  scale_fill_manual(values = CONT_COLORS) +
  labs(
    title    = "Latência Mediana por País",
    subtitle = "Barras de erro: intervalo interquartil (Q1–Q3)",
    x        = NULL, y = "RTT mediano (ms)", fill = "Continente"
  ) +
  tema_base +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8))

salvar("3_latencia_por_pais", largura = 14, altura = 8)

# ── 5.4 Latência agregada por CONTINENTE ─────────────────────────────────────
ggplot(df_ok %>% filter(rtt < quantile(rtt, 0.99)),
       aes(x = continent, y = rtt, fill = continent)) +
  geom_boxplot(outlier.size = 0.7, outlier.alpha = 0.3, alpha = 0.85) +
  facet_grid(af_label ~ dst) +
  scale_fill_manual(values = CONT_COLORS) +
  labs(
    title    = "Distribuição de Latência por Continente",
    subtitle = "IPv4 e IPv6 separados por faixa",
    x        = NULL, y = "RTT mínimo (ms)", fill = "Continente"
  ) +
  tema_base +
  theme(axis.text.x = element_text(angle = 30, hjust = 1, size = 9))

salvar("4_latencia_por_continente", largura = 13, altura = 8)

# =============================================================================
# 6. ANÁLISE 2 — NÚMERO DE SALTOS
# =============================================================================

# ── 6.1 Saltos ao longo do tempo (mediana por rodada, por destino) ────────────
df_ts_hop <- df_ok %>%
  group_by(dst, af_label, hora) %>%
  summarise(mediana_hops = median(n_hops), .groups = "drop")

ggplot(df_ts_hop, aes(x = hora, y = mediana_hops, color = af_label)) +
  geom_line(linewidth = 0.7, alpha = 0.8) +
  geom_point(size = 1.2, alpha = 0.6) +
  facet_wrap(~dst, ncol = 1, scales = "free_y") +
  scale_color_manual(values = c("IPv4" = "#2196F3", "IPv6" = "#FF5722")) +
  scale_x_datetime(date_labels = "%d/%m\n%Hh", date_breaks = "3 hours") +
  scale_y_continuous(breaks = scales::breaks_pretty()) +
  labs(
    title    = "Número de Saltos ao Longo do Tempo",
    subtitle = "Mediana de todas as probes por rodada horária",
    x        = "Horário (UTC)",
    y        = "Número de saltos",
    color    = NULL
  ) +
  tema_base

salvar("5_saltos_serie_temporal", largura = 11, altura = 9)

# ── 6.2 Comparação IPv4 vs IPv6 — boxplot de saltos por destino ───────────────
ggplot(df_ok, aes(x = af_label, y = n_hops, fill = af_label)) +
  geom_boxplot(outlier.size = 0.8, outlier.alpha = 0.3, alpha = 0.8) +
  stat_summary(fun = median, geom = "text",
               aes(label = sprintf("%.0f", after_stat(y))),
               vjust = -0.5, size = 3) +
  facet_wrap(~dst) +
  scale_fill_manual(values = c("IPv4" = "#2196F3", "IPv6" = "#FF5722")) +
  labs(
    title = "Distribuição do Número de Saltos: IPv4 vs IPv6",
    x     = NULL, y = "Número de saltos", fill = NULL
  ) +
  tema_base

salvar("6_saltos_ipv4_vs_ipv6")

# ── 6.3 Saltos agregados por PAÍS ─────────────────────────────────────────────
df_pais_hop <- df_ok %>%
  group_by(dst, country_n, continent, af_label) %>%
  summarise(
    mediana = median(n_hops),
    p25     = quantile(n_hops, 0.25),
    p75     = quantile(n_hops, 0.75),
    .groups = "drop"
  ) %>%
  arrange(continent, mediana) %>%
  mutate(country_n = fct_inorder(country_n))

ggplot(df_pais_hop, aes(x = country_n, y = mediana, fill = continent)) +
  geom_col(position = "dodge") +
  geom_errorbar(aes(ymin = p25, ymax = p75),
                width = 0.3, linewidth = 0.5, alpha = 0.7) +
  facet_grid(af_label ~ dst) +
  scale_fill_manual(values = CONT_COLORS) +
  labs(
    title    = "Número de Saltos Mediano por País",
    subtitle = "Barras de erro: intervalo interquartil (Q1–Q3)",
    x        = NULL, y = "Número de saltos (mediana)", fill = "Continente"
  ) +
  tema_base +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8))

salvar("7_saltos_por_pais", largura = 14, altura = 8)

# ── 6.4 Saltos agregados por CONTINENTE ───────────────────────────────────────
ggplot(df_ok, aes(x = continent, y = n_hops, fill = continent)) +
  geom_boxplot(outlier.size = 0.7, outlier.alpha = 0.3, alpha = 0.85) +
  facet_grid(af_label ~ dst) +
  scale_fill_manual(values = CONT_COLORS) +
  labs(
    title    = "Distribuição do Número de Saltos por Continente",
    subtitle = "IPv4 e IPv6 separados por faixa",
    x        = NULL, y = "Número de saltos", fill = "Continente"
  ) +
  tema_base +
  theme(axis.text.x = element_text(angle = 30, hjust = 1, size = 9))

salvar("8_saltos_por_continente", largura = 13, altura = 8)

# =============================================================================
# 7. BÔNUS — Gráfico de taxa de chegada ao destino (útil para o relatório)
# =============================================================================

df %>%
  group_by(dst, af_label) %>%
  summarise(pct = 100 * mean(reached), .groups = "drop") %>%
  ggplot(aes(x = af_label, y = pct, fill = af_label)) +
  geom_col(alpha = 0.85) +
  geom_text(aes(label = sprintf("%.1f%%", pct)), vjust = -0.4, size = 3.5) +
  facet_wrap(~dst) +
  scale_fill_manual(values = c("IPv4" = "#2196F3", "IPv6" = "#FF5722")) +
  scale_y_continuous(limits = c(0, 105)) +
  labs(
    title    = "Taxa de Medições que Chegaram ao Destino",
    subtitle = "Percentual de traceroutes com destination_ip_responded = TRUE",
    x        = NULL, y = "% de chegada", fill = NULL
  ) +
  tema_base

salvar("9_taxa_chegada_destino")

# =============================================================================
# 8. TABELA RESUMO (para referência no relatório)
# =============================================================================

resumo <- df_ok %>%
  group_by(dst, af_label) %>%
  summarise(
    n          = n(),
    rtt_med    = round(median(rtt), 2),
    rtt_mean   = round(mean(rtt), 2),
    rtt_sd     = round(sd(rtt), 2),
    hops_med   = round(median(n_hops), 1),
    .groups    = "drop"
  )

cat("\n=== RESUMO ESTATÍSTICO ===\n")
print(resumo)

cat("\nTodos os gráficos salvos em:", OUT_DIR, "\n")
