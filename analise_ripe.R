# Análise de Medições RIPE Atlas — Trabalho de Redes de Computadores
# Destinos: YouTube Music, Apple Music, Spotify
# Período: 29/06/2026 08:30 BRT a 30/06/2026 08:30 BRT (24 horas)
# Protocolo: Traceroute ICMP — IPv4 e IPv6

library(jsonlite)
library(dplyr)
library(tidyr)
library(ggplot2)

# Configurações Iniciais

pasta_dados <- "results"
pasta_graficos <- "graficos"
dir.create(pasta_graficos, showWarnings = FALSE)

lista_medicoes <- list(
  list(
    arquivo = file.path(pasta_dados, "youtube_ipv4.json"),
    destino = "YouTube Music",
    versao_ip = 4
  ),
  list(
    arquivo = file.path(pasta_dados, "youtube_ipv6.json"),
    destino = "YouTube Music",
    versao_ip = 6
  ),
  list(
    arquivo = file.path(pasta_dados, "apple_ipv4.json"),
    destino = "Apple Music",
    versao_ip = 4
  ),
  list(
    arquivo = file.path(pasta_dados, "apple_ipv6.json"),
    destino = "Apple Music",
    versao_ip = 6
  ),
  list(
    arquivo = file.path(pasta_dados, "spotify_ipv4.json"),
    destino = "Spotify",
    versao_ip = 4
  ),
  list(
    arquivo = file.path(pasta_dados, "spotify_ipv6.json"),
    destino = "Spotify",
    versao_ip = 6
  )
)

# Mapeamento de Probes para Países e Continentes

probe_pais <- c(
  "3483" = "US", "6882" = "KE", "7018" = "NC", "7623" = "NG",
  "7634" = "KE", "7653" = "NG", "17797" = "US", "22878" = "NZ",
  "25182" = "MX", "28898" = "FR", "33516" = "MX", "33674" = "NC",
  "34005" = "DE", "34665" = "JP", "50383" = "DE", "54716" = "AU",
  "60109" = "IN", "60396" = "ZA", "61770" = "FR", "62730" = "FI",
  "62796" = "NG", "63050" = "NC", "1003582" = "FI", "1004065" = "SG",
  "1004598" = "MX", "1005929" = "KE", "1006482" = "AU", "1008741" = "SG",
  "1009257" = "DE", "1009342" = "NZ", "1009598" = "BR", "1010284" = "NZ",
  "1010568" = "FI", "1010884" = "IN", "1011068" = "IN", "1012985" = "ZA",
  "1013071" = "BR", "1014022" = "SG", "1014295" = "ZA", "1014593" = "US",
  "1014959" = "JP", "1015188" = "FR", "1015550" = "AU", "1015749" = "JP"
)

pais_nome <- c(
  US = "EUA", MX = "México", BR = "Brasil",
  DE = "Alemanha", FR = "França", FI = "Finlândia",
  JP = "Japão", IN = "Índia", SG = "Singapura",
  NG = "Nigéria", ZA = "África do Sul", KE = "Quênia",
  AU = "Austrália", NZ = "Nova Zelândia", NC = "Nova Caledônia"
)

pais_continente <- c(
  US = "Américas", MX = "Américas", BR = "Américas",
  DE = "Europa", FR = "Europa", FI = "Europa",
  JP = "Ásia", IN = "Ásia", SG = "Ásia",
  NG = "África", ZA = "África", KE = "África",
  AU = "Oceania", NZ = "Oceania", NC = "Oceania"
)

ordem_continentes <- c("Américas", "Europa", "Ásia", "África", "Oceania")

cores_continentes <- c(
  "Américas" = "#E74C3C",
  "Europa" = "#3498DB",
  "Ásia" = "#F39C12",
  "África" = "#27AE60",
  "Oceania" = "#9B59B6"
)

# Extração de Dados do Traceroute

# Extrai o RTT (tempo de resposta) mínimo e o número de saltos de um registro
extrair_rtt_e_saltos <- function(registro) {
  lista_hops <- registro$result

  if (is.null(lista_hops) || length(lista_hops) == 0) {
    return(NULL)
  }

  ultimo_hop <- lista_hops[[length(lista_hops)]]
  rtt_minimo <- NA_real_
  numero_saltos <- NA_integer_

  # O hop 255 é o padrão do RIPE Atlas indicando que chegou ao destino
  if (!is.null(ultimo_hop$hop) && ultimo_hop$hop == 255) {
    # Pega os RTTs válidos deste último salto
    rtts <- sapply(ultimo_hop$result, function(p) {
      if (is.null(p$rtt)) {
        return(NA_real_)
      }
      p$rtt
    })
    rtts <- rtts[!is.na(rtts)]

    if (length(rtts) > 0) {
      rtt_minimo <- min(rtts)
    }

    # O número de saltos reais é o salto antes do 255
    if (length(lista_hops) >= 2) {
      numero_saltos <- as.integer(lista_hops[[length(lista_hops) - 1]]$hop)
    } else {
      numero_saltos <- 1L
    }
  } else {
    # Se não chegou no destino, procura o último salto que teve resposta
    for (i in rev(seq_along(lista_hops))) {
      hop <- lista_hops[[i]]
      rtts <- sapply(hop$result, function(p) {
        if (is.null(p$rtt)) {
          return(NA_real_)
        }
        p$rtt
      })
      rtts <- rtts[!is.na(rtts)]

      if (length(rtts) > 0) {
        rtt_minimo <- min(rtts)
        numero_saltos <- as.integer(hop$hop)
        break
      }
    }
  }

  list(rtt = rtt_minimo, saltos = numero_saltos)
}

# Lê e converte um arquivo JSON de medição para uma tabela
ler_arquivo_medicao <- function(caminho_arquivo, nome_destino, versao_ip) {
  cat("Lendo arquivo:", basename(caminho_arquivo), "\n")
  dados_brutos <- fromJSON(
    caminho_arquivo,
    flatten = FALSE,
    simplifyVector = FALSE
  )

  lista_linhas <- lapply(dados_brutos, function(registro) {
    resultado <- extrair_rtt_e_saltos(registro)
    if (is.null(resultado)) {
      return(NULL)
    }

    data.frame(
      probe_id = as.character(registro$prb_id),
      momento_medicao = as.POSIXct(
        registro$timestamp,
        origin = "1970-01-01",
        tz = "UTC"
      ),
      versao_ip = versao_ip,
      destino = nome_destino,
      chegou_destino = isTRUE(registro$destination_ip_responded),
      rtt_minimo_ms = resultado$rtt,
      numero_saltos = resultado$saltos,
      stringsAsFactors = FALSE
    )
  })

  # Junta as linhas em uma única tabela, removendo os valores vazios (NULL)
  do.call(rbind, Filter(Negate(is.null), lista_linhas))
}

# Processamento dos Dados

# Carrega e junta todos os arquivos JSON
todos_registros <- do.call(rbind, lapply(lista_medicoes, function(m) {
  ler_arquivo_medicao(m$arquivo, m$destino, m$versao_ip)
}))

# Adiciona informações de país e continente a cada registro
dados_completos <- todos_registros |>
  mutate(
    sigla_pais = probe_pais[probe_id],
    nome_pais = pais_nome[sigla_pais],
    continente = factor(
      pais_continente[sigla_pais],
      levels = ordem_continentes
    ),
    rotulo_ip = paste0("IPv", versao_ip),
    hora_rodada = as.POSIXct(trunc(momento_medicao, units = "hours"))
  ) |>
  filter(!is.na(sigla_pais))

cat("\nTotal de registros carregados:", nrow(dados_completos), "\n")
cat(
  "Período:", format(min(dados_completos$momento_medicao)),
  "a", format(max(dados_completos$momento_medicao)), "\n\n"
)

# Analisa a taxa de sucesso (quantas medições chegaram ao destino)
resumo_chegada <- dados_completos |>
  group_by(destino, rotulo_ip) |>
  summarise(
    total_medicoes = n(),
    medicoes_chegaram = sum(chegou_destino),
    percentual_chegada = round(100 * mean(chegou_destino), 1),
    .groups = "drop"
  )

cat("=== Resumo de chegada ao destino ===\n")
print(resumo_chegada)

# Filtra latência e saltos apenas quando o pacote chegou ao destino
dados_chegaram <- dados_completos |>
  filter(chegou_destino, !is.na(rtt_minimo_ms), !is.na(numero_saltos))


# Geração de Gráficos

tema_graficos <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "gray40"),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold")
  )

salvar_grafico <- function(nome_arquivo, largura = 10, altura = 6) {
  caminho_completo <- file.path(pasta_graficos, paste0(nome_arquivo, ".pdf"))
  ggsave(caminho_completo, width = largura, height = altura, device = "pdf")
  cat("Gráfico salvo:", caminho_completo, "\n")
}

cores_ipv4_ipv6 <- c("IPv4" = "#2196F3", "IPv6" = "#FF5722")


# 1. Latência ao longo do tempo (média)
latencia_hora <- dados_chegaram |>
  group_by(destino, rotulo_ip, hora_rodada) |>
  summarise(rtt_medio = mean(rtt_minimo_ms), .groups = "drop")

ggplot(latencia_hora, aes(
  x = hora_rodada,
  y = rtt_medio,
  color = rotulo_ip
)) +
  geom_line() +
  geom_point(size = 1) +
  facet_wrap(~destino, ncol = 1, scales = "free_y") +
  scale_color_manual(values = cores_ipv4_ipv6) +
  labs(
    title = "Latência ao Longo do Tempo",
    subtitle = "Média do RTT mínimo por rodada horária",
    x = "Horário (UTC)",
    y = "RTT médio (ms)",
    color = NULL
  ) +
  tema_graficos

salvar_grafico("1_latencia_serie_temporal", largura = 11, altura = 9)


# 2. Comparação da latência média: IPv4 vs IPv6
latencia_ipv4_v6 <- dados_chegaram |>
  group_by(destino, rotulo_ip) |>
  summarise(rtt_medio = mean(rtt_minimo_ms), .groups = "drop")

ggplot(latencia_ipv4_v6, aes(
  x = rotulo_ip,
  y = rtt_medio,
  fill = rotulo_ip
)) +
  geom_col() +
  facet_wrap(~destino) +
  scale_fill_manual(values = cores_ipv4_ipv6) +
  labs(
    title = "Latência Média: IPv4 vs IPv6",
    x = NULL,
    y = "RTT médio (ms)",
    fill = NULL
  ) +
  tema_graficos

salvar_grafico("2_latencia_ipv4_vs_ipv6")


# 3. Latência por país
latencia_pais <- dados_chegaram |>
  group_by(destino, nome_pais, continente, rotulo_ip) |>
  summarise(rtt_medio = mean(rtt_minimo_ms), .groups = "drop")

ggplot(latencia_pais, aes(
  x = reorder(nome_pais, rtt_medio),
  y = rtt_medio,
  fill = continente
)) +
  geom_col() +
  facet_grid(rotulo_ip ~ destino) +
  scale_fill_manual(values = cores_continentes) +
  labs(
    title = "Latência Média por País",
    x = NULL,
    y = "RTT médio (ms)",
    fill = "Continente"
  ) +
  tema_graficos +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8))

salvar_grafico("3_latencia_por_pais", largura = 14, altura = 8)


# 4. Latência média por continente
latencia_continente <- dados_chegaram |>
  group_by(destino, continente, rotulo_ip) |>
  summarise(rtt_medio = mean(rtt_minimo_ms), .groups = "drop")

ggplot(latencia_continente, aes(
  x = continente,
  y = rtt_medio,
  fill = continente
)) +
  geom_col() +
  facet_grid(rotulo_ip ~ destino) +
  scale_fill_manual(values = cores_continentes) +
  labs(
    title = "Latência Média por Continente",
    x = NULL,
    y = "RTT médio (ms)",
    fill = "Continente"
  ) +
  tema_graficos +
  theme(axis.text.x = element_text(angle = 30, hjust = 1, size = 9))

salvar_grafico("4_latencia_por_continente", largura = 13, altura = 8)


# 5. Saltos ao longo do tempo (média)
saltos_hora <- dados_chegaram |>
  group_by(destino, rotulo_ip, hora_rodada) |>
  summarise(saltos_medios = mean(numero_saltos), .groups = "drop")

ggplot(saltos_hora, aes(
  x = hora_rodada,
  y = saltos_medios,
  color = rotulo_ip
)) +
  geom_line() +
  geom_point(size = 1) +
  facet_wrap(~destino, ncol = 1, scales = "free_y") +
  scale_color_manual(values = cores_ipv4_ipv6) +
  labs(
    title = "Número Médio de Saltos ao Longo do Tempo",
    subtitle = "Média por rodada horária",
    x = "Horário (UTC)",
    y = "Número médio de saltos",
    color = NULL
  ) +
  tema_graficos

salvar_grafico("5_saltos_serie_temporal", largura = 11, altura = 9)


# 6. Comparação do número médio de saltos: IPv4 vs IPv6
saltos_ipv4_v6 <- dados_chegaram |>
  group_by(destino, rotulo_ip) |>
  summarise(saltos_medios = mean(numero_saltos), .groups = "drop")

ggplot(saltos_ipv4_v6, aes(
  x = rotulo_ip,
  y = saltos_medios,
  fill = rotulo_ip
)) +
  geom_col() +
  facet_wrap(~destino) +
  scale_fill_manual(values = cores_ipv4_ipv6) +
  labs(
    title = "Número Médio de Saltos: IPv4 vs IPv6",
    x = NULL,
    y = "Número médio de saltos",
    fill = NULL
  ) +
  tema_graficos

salvar_grafico("6_saltos_ipv4_vs_ipv6")


# 7. Saltos por país
saltos_pais <- dados_chegaram |>
  group_by(destino, nome_pais, continente, rotulo_ip) |>
  summarise(saltos_medios = mean(numero_saltos), .groups = "drop")

ggplot(saltos_pais, aes(
  x = reorder(nome_pais, saltos_medios),
  y = saltos_medios,
  fill = continente
)) +
  geom_col() +
  facet_grid(rotulo_ip ~ destino) +
  scale_fill_manual(values = cores_continentes) +
  labs(
    title = "Número Médio de Saltos por País",
    x = NULL,
    y = "Número médio de saltos",
    fill = "Continente"
  ) +
  tema_graficos +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8))

salvar_grafico("7_saltos_por_pais", largura = 14, altura = 8)


# 8. Saltos médios por continente
saltos_continente <- dados_chegaram |>
  group_by(destino, continente, rotulo_ip) |>
  summarise(saltos_medios = mean(numero_saltos), .groups = "drop")

ggplot(saltos_continente, aes(
  x = continente,
  y = saltos_medios,
  fill = continente
)) +
  geom_col() +
  facet_grid(rotulo_ip ~ destino) +
  scale_fill_manual(values = cores_continentes) +
  labs(
    title = "Número Médio de Saltos por Continente",
    x = NULL,
    y = "Número médio de saltos",
    fill = "Continente"
  ) +
  tema_graficos +
  theme(axis.text.x = element_text(angle = 30, hjust = 1, size = 9))

salvar_grafico("8_saltos_por_continente", largura = 13, altura = 8)


# 9. Gráfico da taxa de chegada ao destino
taxa_chegada <- dados_completos |>
  group_by(destino, rotulo_ip) |>
  summarise(percentual = 100 * mean(chegou_destino), .groups = "drop")

ggplot(taxa_chegada, aes(
  x = rotulo_ip,
  y = percentual,
  fill = rotulo_ip
)) +
  geom_col() +
  geom_text(
    aes(label = sprintf("%.1f%%", percentual)),
    vjust = -0.4,
    size = 3.5
  ) +
  facet_wrap(~destino) +
  scale_fill_manual(values = cores_ipv4_ipv6) +
  scale_y_continuous(limits = c(0, 105)) +
  labs(
    title = "Taxa de Medições que Chegaram ao Destino",
    subtitle = "Percentual de traceroutes com resposta do destino",
    x = NULL,
    y = "% de chegada",
    fill = NULL
  ) +
  tema_graficos

salvar_grafico("9_taxa_chegada_destino")


# Resumo Estatístico

tabela_resumo <- dados_chegaram |>
  group_by(destino, rotulo_ip) |>
  summarise(
    total_medicoes = n(),
    rtt_medio = round(mean(rtt_minimo_ms), 2),
    rtt_mediano = round(median(rtt_minimo_ms), 2),
    rtt_desvio = round(sd(rtt_minimo_ms), 2),
    saltos_medios = round(mean(numero_saltos), 1),
    .groups = "drop"
  )

cat("\n=== RESUMO ESTATÍSTICO ===\n")
print(tabela_resumo)
cat("\nTodos os gráficos foram salvos em:", pasta_graficos, "\n")
