import argparse
import threading
import re
from socket import socket, AF_INET, SOCK_STREAM, gethostname, gethostbyname
from constants import *


def main(host: str, port: int):
    hostname = gethostname()
    hostaddr = gethostbyname(hostname)
    # Caputura o endereço IPV4 da máquiana e expõe para os clientes poderem se conectar

    with socket(AF_INET, SOCK_STREAM) as server:
        try:
            # Tentativa de abrir o servidor
            server.bind((host, port))
            server.listen()
            print(f"Servidor TCP escutando localmente em {host}:{port}...")
            print(f"Endereço de rede do servidor: {hostaddr}:{port}")
        except:
            return print(f"Não foi possível iniciar o servidor em {host}:{port}.")

        # Permanentemente escuta por conexões de novos usuários
        while True:
            try:
                client, addr = server.accept()
                print("%s:%s conectou-se ao servidor." % addr)
                # Inicia uma thread nova para cada cliente conectado, lidando com suas infos separadamente
                threading.Thread(target=handle_client, args=(client, addr)).start()
            except KeyboardInterrupt:
                # Encerra a conexão com um Ctrl + C no terminal (apenas Linux)
                print("\nEncerrando o servidor de chat...")
                break
    print("Servidor encerrado.")


def handle_client(client: socket, addr):
    username = get_username(client)

    # O username é None no caso específico do comando /quit, em outras situações é um break que para o while True
    while username != None:
        message = client.recv(BUFSIZE).decode()

        if message == CMD.QUIT:
            handle_commands(CMD.QUIT, client)
            break

        # Processa a mensagem para possível comando, recebendo a mensage, destinatários e outras vars
        # resultantes do processamento
        data, clients, *rest = handle_commands(message, client)

        message = f"{username}: {message}"

        # Essa variável que vem a mais é o nome do grupo, usado para prefixar na mensagem quando existem
        if len(rest) == 1:
            (groupname,) = rest
            message = f"{groupname}/{message}"

        # Envia a mensagem em definitivo prefixando grupo (se tiver) e o usuário para os destinatários
        broadcast(message.encode(), clients=clients)

        # Mensagens retornadas dos comandos processados, em sua maioria apenas textos interndos para o usuário
        # informando o processamento do seu comando
        if data is not None:
            broadcast(data.encode(), clients=clients)

    print("%s:%s desconcetou-se do servidor." % addr)


def broadcast(message: bytes, clients: list[socket], sender: socket = None):
    # Itera em cada cliente e envia uma mensagem para cada, se for especificado um sender, ele deixa de
    # enviar para ele para evitar mensagens repetidas
    for client in clients:
        if client != sender:
            client.sendall(message)


def get_username(client: socket):
    # Estabelece uma breve conversa com o cliente para capturar um username único
    client.sendall(b"SERVIDOR: Bem-vindo ao chat. Insira um username para continuar:")
    username = client.recv(BUFSIZE).decode().lower()

    # Valida unicidade do user
    while username in USERS:
        message = f"SERVIDOR: Username {username} em uso. Tente novamente:"
        client.sendall(message.encode())
        username = client.recv(BUFSIZE).decode().lower()

    # Caso o usuário tente fechar a guia nessa etapa, aceita o comando e encerra a conexão
    if username == CMD.QUIT:
        handle_commands(CMD.QUIT, client)
        return None

    # Nega qualquer possível comando e caracteres especiais como nome de usuário
    while re.fullmatch(r"[A-Za-z]*[0-9]*", username) is None:
        message = f"SERVIDOR: Username inválido. Utilize apenas letras e números."
        client.sendall(message.encode())
        username = client.recv(BUFSIZE).decode()

    # Cria registros do usuário nas vars CLIENTS e USERS
    add_user(client, username)

    return username


def add_user(client: socket, username: str):
    # Adiciona entradas do usuário e seu socket nas variáveis globais de controle
    CLIENTS[client] = username
    USERS[username] = client

    # Manda pequena mensagem de boas-vindas com a indicação do comando de ajuda
    greet = f"SERVIDOR: Olá {username}! Digite /help para obter a lista de comandos."
    client.sendall(greet.encode())

    # Avias globalmente que um novo usuário conectou-se ao servidor de chat
    message = f"SERVIDOR: {username} conectou-se ao chat."
    broadcast(message.encode(), clients=CLIENTS, sender=client)


def rem_user(client: socket):
    username = CLIENTS[client]

    # Remove as entradas padrão do usuário na lista de clientes conectados
    del CLIENTS[client]
    del USERS[username]

    if client in PRIVATE:
        del PRIVATE[client]
    # Verifica a existência de um chat privado ou grupo definido para conversa e tira o registro
    if client in GROUP:
        del GROUP[client]

    # Itera sobre todos os grupos que o usuário participava e faz a desvinculação
    if client in USER_GROUPS:
        for group in USER_GROUPS[client]:
            GROUPS[group].remove(client)
        del USER_GROUPS[client]

    # Aviso global de desconexão
    message = f"SERVIDOR: {username} deixou o chat."
    broadcast(message.encode(), clients=CLIENTS)


def handle_commands(message: str, client: socket):
    # Lida com os possíveis comandos vindos das mensagens recebidas
    command, *rest = message.split(" ")  # Isola a primeira palavra

    if command.startswith("/"):
        # Verifica se inicia com /, que define o comando, então verifica se é válido
        if command not in vars(CMD).values():
            return "Comando inválido", [client]
            # [client] indica que apenas o usuário vai ler essa mensagem, é enviado internamente para ele

    if command == CMD.QUIT:
        client.sendall(CMD.QUIT.encode())
        client.close()
        # Encerra todo o programa e remove cada usuário a listagem global de usuários
        if client in CLIENTS:
            rem_user(client)

    if command == CMD.PRIVATE:
        # O formato do comando é /private [usuario]
        # Cada verificação de len(rest) verifica se o usuário passou só o /private
        # Ou se passou /private + username, pois em cada modo a função opera diferente

        if len(rest) == 0:
            # Para apenas /private, ele pega todos os usuários ativos (menos ele mesmo) e lista internamente
            users = [CLIENTS[c] for c in CLIENTS if c != client]
            return ", ".join(users), [client]

        # Se o len de rest for > 0, quer dizer que foi passado um segundo ou mais argumentos (os demais descartados)
        username, *_ = rest
        if username in USERS:
            # Verifica se o username existe no sistema e se não é o próprio usuário
            private = USERS[username]
            if client != private:
                # Adiciona o usuário privado para recebimento direto das mensagens
                PRIVATE[client] = private

                # Troca o envio de mensagens do grupo para o usuário individual
                if client in GROUP:
                    del GROUP[client]

                return f"Você está agora conectado a {username}", [client]

    if command == CMD.GROUP:
        # O comando funciona com /group (apenas listar) /group + nome (conectar ao seu grupo)
        # E /group + nome + user1 + user2 + user3 (cria o grupo com aquele nome e add os usuários listados)
        if len(rest) == 0:
            if client in USER_GROUPS:
                # Itera sobre os grupos que o usuário participa, se tiver
                return ", ".join(USER_GROUPS[client]), [client]
            return None, [client]

        # Caso detecte um segundo argumento passado (groupname)
        # Verifica se o grupo existe, se o usuário faz parte dele, e então se conecta ao grupo
        groupname, *usernames = rest
        # Grupos foram definidos apenas como maiúsculo, users como minúsculo
        groupname = groupname.upper()
        if len(usernames) == 0:
            if groupname in GROUPS:
                if client in GROUPS[groupname]:
                    GROUP[client] = groupname
                    # Muda o envio de mensagens para o grupo selecionado
                    if client in PRIVATE:
                        del PRIVATE[client]

                    return f"Você está agora conectado ao grupo {groupname}", [client]
            return None, [client]  # Não foram encontrados grupos

        # A partir daqui foram passados 3+ parâmetros, iniciando a criação do grupo
        if groupname in GROUPS:
            return "Um grupo com o mesmo nome já foi criado, tente novamente", [client]

        # Cria uma entrada do grupo na lista de grupos existentes
        GROUPS[groupname] = set()

        # Insere o próprio usuário na criação do grupo
        usernames.append(CLIENTS[client])
        for username in usernames:
            if username in USERS:
                # Pra cada usuário, pega seu socket da conexão e coloca na lista de users daquele grupo
                userclient = USERS[username]
                GROUPS[groupname].add(userclient)

                # Cria ou atualiza os grupos que o usuário participa na variável USER_GROUPS
                if userclient not in USER_GROUPS:
                    USER_GROUPS[userclient] = set()
                USER_GROUPS[userclient].add(groupname)

        return f"Grupo {groupname} criado com uscesso!", [client]

    if client in PRIVATE:
        return None, [PRIVATE[client], client]
    # Detecta a existência do usuário no chat privado ou no grupo e determina se irá receber apenas
    # o user e o próprio sender ou se não todos do grupo, fazendo e troca entre chat privado e grupo
    if client in GROUP:
        groupname = GROUP[client]
        return None, GROUPS[groupname], groupname

    return None, [client]


# Dicionário dos clientes conectados que recebe a variável socket do cliente e retorna seu username
CLIENTS: dict[socket, str] = {}

# Dicionário que inverte a lóica e guarda o socket dos usuários concectados a partir do user
USERS: dict[str, socket] = {}

# Guarda, para cada conexão ativa o servidor, um dicionário contendo o chat privado para qual o usuário
# está mandando mensagens, se estiver conectado a um grupou ou globalmente, a entrada fica vazia
PRIVATE: dict[socket, socket] = {}

# Guarda, para cada conexão ativa, o nome do grupo que está conversando, se estiver
GROUP: dict[socket, str] = {}

# Dado o nome único de um grupo, guarda a lista de clientes (usuários) que fazem parte dele
GROUPS: dict[str, set[socket]] = {}

# Dado todos os usuários ativos, para cada um deles guarda uma lista com o nome dos grupos que fazem parte
USER_GROUPS: dict[socket, set[str]] = {}

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default=HOST)
    parser.add_argument("-p", "--port", type=int, default=PORT)
    # Caputa o host e a porta através de flags no arquivo executado e repassada para a função
    args = parser.parse_args()

    main(**vars(args))
