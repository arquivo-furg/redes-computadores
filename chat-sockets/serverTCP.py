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

        data, clients = handle_commands(message, client)

        message = f"{username}: {message}"
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
    username = client.recv(BUFSIZE).decode()

    while username in USERS:
        message = f"SERVIDOR: Username {username} em uso. Tente novamente:"
        client.sendall(message.encode())
        username = client.recv(BUFSIZE).decode()

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

    message = f"SERVIDOR: {username} deixou o chat."
    broadcast(message.encode(), clients=CLIENTS)


def handle_commands(message: str, client: socket):
    command = ""

    if message.startswith("/"):
        command, *rest = message.split(" ")
        if command not in vars(CMD).values():
            return "Comando inválido", [client]

    if command == CMD.QUIT:
        client.sendall(CMD.QUIT.encode())
        client.close()

        if client in CLIENTS:
            rem_user(client)

    if command == CMD.PRIVATE:
        if len(rest) == 0:
            return ", ".join(USERS.keys()), [client]

        username, *rest = rest
        if username in USERS:
            private = USERS[username]
            if client != private:
                PRIVATE[client] = private
                return f"Você está agora conectado a {username}", [client]

    if client in PRIVATE:
        return None, [PRIVATE[client]]

    return None, [client]


CLIENTS: dict[socket, str] = {}
USERS: dict[str, socket] = {}
PRIVATE: dict[socket, socket] = {}

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default=HOST)
    parser.add_argument("-p", "--port", type=int, default=PORT)

    args = parser.parse_args()

    main(**vars(args))
