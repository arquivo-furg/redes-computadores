import argparse
import threading
from socket import socket, AF_INET, SOCK_STREAM, _RetAddress

# Referências
# https://www.dio.me/articles/faca-o-seu-proprio-chat-utilizando-python-atraves-de-sockets
# https://medium.com/swlh/lets-write-a-chat-app-in-python-f6783a9ac170


def main(host: str, port: int):
    with socket(AF_INET, SOCK_STREAM) as server:
        try:
            server.bind((host, port))
            server.listen()
            print(f"Servidor TCP escutando em {host}:{port}...")
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


def handle_client(client: socket, addr: _RetAddress):
    username = get_username(client)

    while True:
        if username == "/quit":
            client.sendall(b"/quit")
            client.close()
            break

        data = client.recv(BUFSIZE).decode()

        if data == "/quit":
            rem_user(client, username)
            break

        message = f"<{username}> {data}"
        broadcast(message.encode())

    print("%s:%s desconcetou-se do servidor." % addr)


def broadcast(message: bytes, sender: socket | None = None):
    for client in clients:
        if client != sender:
            client.sendall(message)


def get_username(client: socket):
    client.sendall(b"<SERVIDOR> Bem-vindo ao chat. Insira um username para continuar:")
    username = client.recv(BUFSIZE).decode()

    while username in clients.values():
        message = f"<SERVIDOR> Username {username} em uso. Tente novamente:"
        client.sendall(message.encode())
        username = client.recv(BUFSIZE).decode()

    if username == "/quit":
        return username

    add_user(client, username)

    return username


def add_user(client: socket, username: str):
    clients[client] = username

    greet = f"<SERVIDOR> Olá {username}! Para sair, digite /quit ou feche a janela."
    client.sendall(greet.encode())

    message = f"<SERVIDOR> {username} conectou-se ao chat."
    broadcast(message.encode(), client)


def rem_user(client: socket, username: str):
    client.sendall(b"/quit")
    client.close()

    del clients[client]

    message = f"<SERVIDOR> {username} deixou o chat."
    broadcast(message.encode())


clients: dict[socket, str] = {}

HOST = "127.0.0.1"
PORT = 12345
BUFSIZE = 2048

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default=HOST)
    parser.add_argument("-p", "--port", type=int, default=PORT)

    args = parser.parse_args()

    main(**vars(args))
