# Trabalho - Medições com RIPE Atlas

## Informações gerais do trabalho

**Vencimento:** quarta-feira, 1 jul. 2026, 23:59

O trabalho pode ser realizado de forma **individual** ou em **grupos de até 4 alunos**.

A turma não deve exceder **10 grupos**.

Os grupos e os destinos escolhidos devem ser indicados na planilha/link disponibilizado pelo professor, para evitar repetição de temas entre os grupos.

---

## Objetivo

O objetivo deste trabalho é realizar uma série de medições para analisar o desempenho da rede ao alcançar um conjunto de destinos na Internet.

Para isso, deve-se utilizar a plataforma **RIPE Atlas**, selecionando um conjunto de **45 probes** e realizando medições **IPv4 e IPv6** com **traceroute** para a lista de destinos escolhida pelo grupo.

Os destinos devem ser relacionados de alguma forma e a lista deve conter, no mínimo, **3 destinos**.

Neste trabalho, foram escolhidos destinos relacionados a serviços de streaming de música.

---

## Destinos escolhidos

Os destinos utilizados nas medições foram:

- `music.youtube.com`
- `music.apple.com`
- `open.spotify.com`

Esses destinos foram escolhidos por pertencerem à mesma categoria de serviço: plataformas de streaming de música.

Antes da criação das medições, foi verificado que os três destinos respondiam tanto em IPv4 quanto em IPv6.

---

## Requisitos das medições

De acordo com o enunciado, as medições devem atender aos seguintes requisitos:

- Utilizar a plataforma **RIPE Atlas**.
- Selecionar um conjunto de **45 probes**.
- Realizar medições **IPv4** e **IPv6**.
- Utilizar **traceroute**.
- Medir uma lista de pelo menos **3 destinos** relacionados.
- Realizar as medições por um período mínimo de **24 horas**.
- Repetir as medições a cada **60 minutos**.
- Escolher as probes conforme os critérios de cobertura definidos no trabalho.

---

## Critérios de cobertura das probes

As probes devem ser escolhidas de forma a atender aos seguintes critérios:

- **5 continentes**
- **3 países por continente**
- **3 probes por país**

Assim, o total esperado é:

```text
5 continentes × 3 países por continente × 3 probes por país = 45 probes
```

Neste trabalho, foi considerada a divisão em que **América** é tratada como um único continente.

---

## Distribuição geográfica utilizada

| Continente | Países                                                  |
| ---------- | ------------------------------------------------------- |
| América    | Brasil (BR), México (MX), Estados Unidos (US)           |
| Ásia       | Japão (JP), Índia (IN), Singapura (SG)                  |
| Europa     | Alemanha (DE), França (FR), Finlândia (FI)              |
| África     | Quênia (KE), Nigéria (NG), África do Sul (ZA)           |
| Oceania    | Austrália (AU), Nova Zelândia (NZ), Nova Caledônia (NC) |

---

## Probes utilizadas

As medições foram configuradas para utilizar **45 probes**, distribuídas em 5 continentes, 3 países por continente e 3 probes por país.

Entretanto, uma das probes selecionadas no Brasil, a probe **16721**, localizada em **Porto Alegre (POA)**, não respondeu corretamente durante a coleta. Por isso, o conjunto efetivo de resultados retornados ficou com **44 probes**.

Assim, a configuração planejada atende ao critério de **45 probes**, mas a análise final considera os dados efetivamente recebidos de **44 probes**.

---

### América

| País                | Probes selecionadas     | Observação                                        |
| ------------------- | ----------------------- | ------------------------------------------------- |
| Brasil (BR)         | 16721, 1009598, 1013071 | A probe 16721, de POA, não respondeu corretamente |
| México (MX)         | 25182, 33516, 1004598   | 3 probes válidas                                  |
| Estados Unidos (US) | 3483, 17797, 1014593    | 3 probes válidas                                  |

---

### Ásia

| País           | Probes selecionadas       | Observação       |
| -------------- | ------------------------- | ---------------- |
| Japão (JP)     | 34665, 1014959, 1015749   | 3 probes válidas |
| Índia (IN)     | 60109, 1010884, 1011068   | 3 probes válidas |
| Singapura (SG) | 1004065, 1008741, 1014022 | 3 probes válidas |

---

### Europa

| País           | Probes selecionadas     | Observação       |
| -------------- | ----------------------- | ---------------- |
| Alemanha (DE)  | 34005, 50383, 1009257   | 3 probes válidas |
| França (FR)    | 28898, 61770, 1015188   | 3 probes válidas |
| Finlândia (FI) | 62730, 1003582, 1010568 | 3 probes válidas |

---

### África

| País               | Probes selecionadas     | Observação       |
| ------------------ | ----------------------- | ---------------- |
| Quênia (KE)        | 6882, 7634, 1005929     | 3 probes válidas |
| Nigéria (NG)       | 7623, 7653, 62796       | 3 probes válidas |
| África do Sul (ZA) | 60396, 1012985, 1014295 | 3 probes válidas |

---

### Oceania

| País                | Probes selecionadas     | Observação       |
| ------------------- | ----------------------- | ---------------- |
| Austrália (AU)      | 54716, 1006482, 1015550 | 3 probes válidas |
| Nova Zelândia (NZ)  | 22878, 1009342, 1010284 | 3 probes válidas |
| Nova Caledônia (NC) | 7018, 33674, 63050      | 3 probes válidas |

---

## Resumo quantitativo das probes

| Continente | Países        | Quantidade de probes |
| ---------- | ------------- | -------------------- |
| América    | BR, MX, US    | 9                    |
| Ásia       | JP, IN, SG    | 9                    |
| Europa     | DE, FR, FI    | 9                    |
| África     | KE, NG, ZA    | 9                    |
| Oceania    | AU, NZ, NC    | 9                    |
| **Total**  | **15 países** | **45 probes**        |

---

## Configuração das medições

As medições foram configuradas com os seguintes parâmetros:

| Parâmetro              | Valor         |
| ---------------------- | ------------- |
| Tipo de medição        | Traceroute    |
| Protocolo              | ICMP          |
| Versões IP             | IPv4 e IPv6   |
| Pacotes por traceroute | 3             |
| Tamanho do pacote      | 48 bytes      |
| Primeiro salto         | 1             |
| Máximo de saltos       | 32            |
| Paris traceroute       | 16            |
| Intervalo              | 3600 segundos |
| Intervalo em minutos   | 60 minutos    |
| Duração                | 24 horas      |
| Auto top-up            | Desabilitado  |

Foram criadas **6 medições** no total:

- `music.youtube.com` IPv4
- `music.youtube.com` IPv6
- `music.apple.com` IPv4
- `music.apple.com` IPv6
- `open.spotify.com` IPv4
- `open.spotify.com` IPv6

---

## Período das medições

As medições foram configuradas para executar durante 24 horas.

| Início               | Fim                  |
| -------------------- | -------------------- |
| 2026-06-29 11:30 UTC | 2026-06-30 11:30 UTC |

---

## IDs das medições realizadas

| Destino             | IPv4      | IPv6      |
| ------------------- | --------- | --------- |
| `music.youtube.com` | 184876336 | 184876337 |
| `music.apple.com`   | 184876339 | 184876340 |
| `open.spotify.com`  | 184876341 | 184876342 |

---

## Criação das medições

As medições foram criadas utilizando a API do RIPE Atlas via `curl`.

A seleção das probes foi solicitada por país, com 3 probes por país:

```json
"probes": [
  {"type": "country", "value": "BR", "requested": 3},
  {"type": "country", "value": "MX", "requested": 3},
  {"type": "country", "value": "US", "requested": 3},

  {"type": "country", "value": "JP", "requested": 3},
  {"type": "country", "value": "IN", "requested": 3},
  {"type": "country", "value": "SG", "requested": 3},

  {"type": "country", "value": "DE", "requested": 3},
  {"type": "country", "value": "FR", "requested": 3},
  {"type": "country", "value": "FI", "requested": 3},

  {"type": "country", "value": "KE", "requested": 3},
  {"type": "country", "value": "NG", "requested": 3},
  {"type": "country", "value": "ZA", "requested": 3},

  {"type": "country", "value": "AU", "requested": 3},
  {"type": "country", "value": "NZ", "requested": 3},
  {"type": "country", "value": "NC", "requested": 3}
]
```

Após a criação das medições, a lista efetiva de probes utilizadas foi registrada neste README.

---

## Verificação dos destinos

O enunciado destaca que é importante verificar se as medições chegaram ao destino.

Alguns servidores podem estar configurados para não responder às medições ou podem não funcionar corretamente com IPv6. Nesse caso, seria necessário escolher outros destinos.

Antes da criação das medições, os destinos escolhidos foram testados com IPv4 e IPv6, e todos responderam.

Durante a análise dos dados, ainda assim será necessário verificar se cada traceroute alcançou o destino final.

---

## Análises solicitadas

Após a realização das medições, devem ser feitas análises em forma de gráficos.

As análises devem considerar dois aspectos principais:

1. Latência
2. Quantidade de saltos

---

## Análise de latência

Devem ser produzidos gráficos mostrando a variação da latência ao longo do tempo.

Também devem ser produzidos gráficos comparando as latências entre IPv4 e IPv6 para o mesmo destino.

Além disso, devem ser feitas versões agregadas por:

- país;
- continente.

A latência pode ser extraída a partir do RTT observado no salto final do traceroute, quando o destino é alcançado.

Exemplos de gráficos esperados:

- Latência ao longo do tempo para cada destino.
- Comparação IPv4 versus IPv6 para `music.youtube.com`.
- Comparação IPv4 versus IPv6 para `music.apple.com`.
- Comparação IPv4 versus IPv6 para `open.spotify.com`.
- Latência média agregada por país.
- Latência média agregada por continente.

---

## Análise da quantidade de saltos

Devem ser produzidos gráficos mostrando a variação do número de saltos até o destino ao longo do tempo.

Também devem ser produzidos gráficos comparando a quantidade de saltos entre IPv4 e IPv6 para o mesmo destino.

Além disso, devem ser feitas versões agregadas por:

- país;
- continente.

A quantidade de saltos pode ser calculada a partir do número do último hop quando o destino é alcançado.

Exemplos de gráficos esperados:

- Quantidade de saltos ao longo do tempo para cada destino.
- Comparação IPv4 versus IPv6 para `music.youtube.com`.
- Comparação IPv4 versus IPv6 para `music.apple.com`.
- Comparação IPv4 versus IPv6 para `open.spotify.com`.
- Quantidade média de saltos agregada por país.
- Quantidade média de saltos agregada por continente.

---

## Exemplo de arquivo de saída

O enunciado informa que há um exemplo de arquivo de saída das medições disponibilizado pelo professor.

Esse exemplo pode ser utilizado como referência para entender a estrutura dos dados retornados pelo RIPE Atlas.

Os resultados das medições em traceroute normalmente incluem informações como:

- ID da medição;
- ID da probe;
- timestamp;
- destino;
- endereço de destino;
- versão IP;
- protocolo;
- saltos do traceroute;
- RTTs observados;
- respostas ausentes ou timeouts;
- indicação de chegada ou não ao destino.

---

## Pipeline do trabalho

O pipeline desenvolvido para o trabalho deve realizar, em alto nível, as seguintes etapas:

1. Baixar os resultados das medições do RIPE Atlas.
2. Ler os arquivos JSON de saída.
3. Extrair os dados relevantes:
   - ID da medição;
   - ID da probe;
   - país da probe;
   - continente da probe;
   - destino medido;
   - versão IP;
   - timestamp da medição;
   - RTT até o destino;
   - quantidade de saltos até o destino;
   - indicação se o destino foi alcançado.
4. Verificar se cada medição chegou ao destino.
5. Organizar os dados em formato tabular.
6. Gerar gráficos de latência.
7. Gerar gráficos de quantidade de saltos.
8. Comparar IPv4 e IPv6.
9. Agregar os resultados por país.
10. Agregar os resultados por continente.
11. Elaborar conclusões a partir dos resultados obtidos.

---

## O que apresentar no vídeo

A apresentação deve conter:

- descrição das probes utilizadas;
- descrição dos alvos medidos;
- período em que as medições foram realizadas;
- visão de alto nível do pipeline desenvolvido para a realização dos experimentos e análises;
- análises realizadas;
- gráficos produzidos;
- conclusões.

---

## Tempo de apresentação

O tempo de apresentação é de:

```text
15 minutos
```

---

## O que entregar

A entrega deve conter:

- códigos utilizados para realizar as medições;
- códigos utilizados para realizar as análises;
- códigos documentados e comentados;
- lista de IDs das medições realizadas;
- conjunto de slides apresentado;
- link para o vídeo da apresentação.

---

## Nome do arquivo de entrega

O arquivo compactado deve seguir o padrão:

```text
NUM_MATRICULA1_NUMMATRICULA2.formato
```

Exemplo:

```text
39133_39199.tar.gz
```

Caso o grupo tenha mais integrantes, os números de matrícula devem ser adaptados conforme a orientação do professor.

---

## Critérios de avaliação

| Critério                            | Pontuação  | Descrição                                                                                                |
| ----------------------------------- | ---------- | -------------------------------------------------------------------------------------------------------- |
| Apresentação                        | 2,5 pontos | O conteúdo solicitado está presente? Os resultados foram bem explicados? O conteúdo está bem organizado? |
| Clareza das explicações individuais | 1,5 ponto  | O aluno demonstra conhecimento sobre o trabalho?                                                         |
| Códigos e documentação              | 0,5 ponto  | O código está documentado e de fácil entendimento?                                                       |
| Adequação ao tempo                  | 0,5 ponto  | O tempo da apresentação foi bem aproveitado?                                                             |

---

## Observação sobre plágio

Em caso de códigos copiados ou plagiados, a nota do trabalho de todos os alunos envolvidos será zerada, independentemente de quem efetivamente fez o código e de quem copiou.

É permitido discutir estratégias, ideias e formas de resolver o problema, mas não é permitido copiar a solução de outro grupo.

---

## Instruções de uso da plataforma RIPE Atlas

As instruções fornecidas no enunciado para uso da plataforma são:

1. Criar conta no RIPE Atlas:
   - https://access.ripe.net/registration

2. Informar o ID na planilha de grupos para que os créditos possam ser fornecidos.

3. Acessar a área do usuário:
   - https://atlas.ripe.net/my/

4. Acessar a documentação e recursos da plataforma:
   - https://atlas.ripe.net/landing/resources/

---

## Conclusões esperadas

Ao final do trabalho, espera-se comparar o desempenho dos caminhos de rede até os destinos escolhidos, observando diferenças entre:

- IPv4 e IPv6;
- diferentes países;
- diferentes continentes;
- diferentes serviços de streaming;
- latência ao longo do tempo;
- quantidade de saltos ao longo do tempo.

As conclusões devem ser baseadas nos gráficos e nos dados coletados durante as 24 horas de medição.
