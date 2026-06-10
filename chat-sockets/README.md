# Chat com Sockets TCP

Este projeto implementa um serviço de troca de mensagens usando sockets TCP em Python. O servidor aceita múltiplos clientes, controla os usernames conectados e permite conversas privadas e grupos de usuários.

## Integrantes

- Alex Santos - 169622
- Carlos Mourão - 171075
- Pedro Cardoso - 169618
- Pedro Machado - 169591

## Arquivos

- `serverTCP.py`: servidor TCP responsável por conexões, usuários, mensagens privadas e grupos.
- `clientTCP.py`: cliente com interface gráfica para enviar e receber mensagens.
- `constants.py`: configurações padrão, comandos e textos de ajuda.

## Requisitos

- Python 3.10 ou superior.
- Tkinter disponível no ambiente Python.
- Um terminal para o servidor e um terminal para cada cliente.

## Como executar

Entre na pasta do projeto:

```bash
cd chat-sockets
```

Inicie o servidor:

```bash
python serverTCP.py
```

Em outro terminal, inicie um cliente:

```bash
python clientTCP.py
```

Abra mais terminais e repita o comando do cliente para simular vários usuários conectados.

## Host e porta

Por padrão, o projeto usa `127.0.0.1` e porta `12345`.

Servidor com host e porta definidos manualmente:

```bash
python serverTCP.py --host 127.0.0.1 --port 12345
```

Cliente com host e porta definidos manualmente:

```bash
python clientTCP.py --host 127.0.0.1 --port 12345
```

Para executar em computadores diferentes na mesma rede, use no cliente o endereço de rede em que o servidor estiver disponível.

## Comandos do chat

- `/help`: mostra os comandos disponíveis.
- `/quit`: encerra o cliente e desconecta do servidor.
- `/clear`: limpa a janela do chat.
- `/private`: lista usuários ativos.
- `/private username`: inicia conversa privada com um usuário.
- `/group`: lista os grupos ativos do usuário.
- `/group groupname`: entra em um grupo já criado.
- `/group groupname username1 ...`: cria um grupo com os usuários informados.

## Referências

- <https://www.dio.me/articles/faca-o-seu-proprio-chat-utilizando-python-atraves-de-sockets>
- <https://medium.com/swlh/lets-write-a-chat-app-in-python-f6783a9ac170>
- <https://yangtavaresblog.wordpress.com/2017/12/09/a-simple-chat-with-sockets-using-python/>

## Enunciado

**Grupos com 3 ou 4 alunos, não podendo ter mais de 10 grupos**
**Indicar o grupo [aqui](https://docs.google.com/spreadsheets/d/1PjSvFVNXeOtK8vgSIoLN1WeSLICld2629NXZ4NpsQqk/edit?gid=0#gid=0)!**

O objetivo deste trabalho é familiarizar-se com a programação de aplicações de rede utilizando sockets. Para isso, você deve implementar uma das seguintes aplicações:

- Jogo de batalha naval (2 jogadores por partida, múltiplas partidas);
- Jogo de truco (4 jogadores por partida, múltiplas partidas);
- Serviço de troca de mensagens com possibilidade de criação de grupos (múltiplos usuários, grupos e usuários por grupo);

**O que entregar?** Arquivo compactado com os códigos associados ao trabalho. Os códigos devem ser nomeados de forma sugestiva (por exemplo, cliente.py). O arquivo compactado deverá ser nomeado conforme o padrão **NUM_MATRICULA1_NUMMATRICULA2.formato** (e.g., 39133_39199.tar.gz).

Critérios de avaliação:

- Demonstração (2,0 pontos): o código atende à especificação? Os resultados obtidos estão corretos?
- Documentação (0,5 ponto): o código está bem documentado e possui documentação de uso?
- Conhecimento individual da solução (2,5 pontos): os/as integrantes do grupo demonstram conhecimento do código desenvolvido?

**Observação:** Em caso de cópia ou plágio de código, **a nota do trabalho de todos os alunos envolvidos será zerada**, independentemente de quem efetivamente fez ou de quem copiou. Lembrem: é permitido discutir como resolver o problema; não podem copiar a solução.
