import argparse
import threading
import re
from socket import socket, AF_INET, SOCK_STREAM, gethostname, gethostbyname
from constants import *

# Referências
# https://www.dio.me/articles/faca-o-seu-proprio-chat-utilizando-python-atraves-de-sockets
# https://medium.com/swlh/lets-write-a-chat-app-in-python-f6783a9ac170
# https://yangtavaresblog.wordpress.com/2017/12/09/a-simple-chat-with-sockets-using-python/


def main(host: str, port: int):
    hostname = gethostname()
    hostaddr = gethostbyname(hostname)

    with socket(AF_INET, SOCK_STREAM) as server:
        try:
            server.bind((host, port))
            server.listen()
            print(f"Servidor TCP escutando localmente em {host}:{port}...")
            print(f"Endereço de rede do servidor: {hostaddr}:{port}")
        except:
            return print(f"Não foi possível iniciar o servidor em {host}:{port}.")

        while True:
            try:
                client, addr = server.accept()
                print("%s:%s concetou-se ao servidor." % addr)

                threading.Thread(target=handle_client, args=(client, addr)).start()
            except KeyboardInterrupt:
                print("\nEncerrando o servidor de chat...")
                break
    print("Servidor encerrado.")


def handle_client(client: socket, addr):
    username = get_username(client)

    while username != None:
        message = client.recv(BUFSIZE).decode()

        if message == CMD.QUIT:
            handle_commands(CMD.QUIT, client)
            break

        data, clients, *rest = handle_commands(message, client)

        message = f"{username}: {message}"

        if len(rest) == 1:
            (groupname,) = rest
            message = f"{groupname}/{message}"

        broadcast(message.encode(), clients=clients)

        if data is not None:
            broadcast(data.encode(), clients=clients)

    print("%s:%s desconcetou-se do servidor." % addr)


def broadcast(message: bytes, clients: list[socket], sender: socket = None):
    for client in clients:
        if client != sender:
            client.sendall(message)


def get_username(client: socket):
    client.sendall(b"SERVIDOR: Bem-vindo ao chat. Insira um username para continuar:")
    username = client.recv(BUFSIZE).decode().lower()

    while username in USERS:
        message = f"SERVIDOR: Username {username} em uso. Tente novamente:"
        client.sendall(message.encode())
        username = client.recv(BUFSIZE).decode().lower()

    if username == CMD.QUIT:
        handle_commands(CMD.QUIT, client)
        return None

    while re.fullmatch(r"[A-Za-z]*[0-9]*", username) is None:
        message = f"SERVIDOR: Username inválido. Utilize apenas letras e números."
        client.sendall(message.encode())
        username = client.recv(BUFSIZE).decode()

    add_user(client, username)

    return username


def add_user(client: socket, username: str):
    CLIENTS[client] = username
    USERS[username] = client

    greet = f"SERVIDOR: Olá {username}! Digite /help para obter a lista de comandos."
    client.sendall(greet.encode())

    message = f"SERVIDOR: {username} conectou-se ao chat."
    broadcast(message.encode(), clients=CLIENTS, sender=client)


def rem_user(client: socket):
    username = CLIENTS[client]

    del CLIENTS[client]
    del USERS[username]

    if client in PRIVATE:
        del PRIVATE[client]

    if client in GROUP:
        del GROUP[client]

    if client in USER_GROUPS:
        for group in USER_GROUPS[client]:
            GROUPS[group].remove(client)
        del USER_GROUPS[client]

    message = f"SERVIDOR: {username} deixou o chat."
    broadcast(message.encode(), clients=CLIENTS)


def handle_commands(message: str, client: socket):
    command, *rest = message.split(" ")

    if command.startswith("/"):
        if command not in vars(CMD).values():
            return "Comando inválido", [client]

    if command == CMD.QUIT:
        client.sendall(CMD.QUIT.encode())
        client.close()

        if client in CLIENTS:
            rem_user(client)

    if command == CMD.PRIVATE:
        if len(rest) == 0:
            users = [CLIENTS[c] for c in CLIENTS if c != client]
            return ", ".join(users), [client]

        username, *_ = rest
        if username in USERS:
            private = USERS[username]
            if client != private:
                PRIVATE[client] = private

                if client in GROUP:
                    del GROUP[client]

                return f"Você está agora conectado a {username}", [client]

    if command == CMD.GROUP:
        if len(rest) == 0:
            if client in USER_GROUPS:
                return ", ".join(USER_GROUPS[client]), [client]
            return None, [client]

        groupname, *usernames = rest
        groupname = groupname.upper()
        if len(usernames) == 0:
            if groupname in GROUPS:
                if client in GROUPS[groupname]:
                    GROUP[client] = groupname

                    if client in PRIVATE:
                        del PRIVATE[client]

                    return f"Você está agora conectado ao grupo {groupname}", [client]
            return None, [client]

        if groupname in GROUPS:
            return "Um grupo com o mesmo nome já foi criado, tente novamente", [client]

        GROUPS[groupname] = set()

        usernames.append(CLIENTS[client])
        for username in usernames:
            if username in USERS:
                userclient = USERS[username]
                GROUPS[groupname].add(userclient)

                if userclient not in USER_GROUPS:
                    USER_GROUPS[userclient] = set()
                USER_GROUPS[userclient].add(groupname)

        return f"Grupo {groupname} criado com uscesso!", [client]

    if client in PRIVATE:
        return None, [PRIVATE[client]]

    if client in GROUP:
        groupname = GROUP[client]
        return None, GROUPS[groupname], groupname

    return None, [client]


CLIENTS: dict[socket, str] = {}
USERS: dict[str, socket] = {}
PRIVATE: dict[socket, socket] = {}
GROUP: dict[socket, str] = {}
GROUPS: dict[str, set[socket]] = {}
USER_GROUPS: dict[socket, set[str]] = {}

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default=HOST)
    parser.add_argument("-p", "--port", type=int, default=PORT)

    args = parser.parse_args()

    main(**vars(args))
