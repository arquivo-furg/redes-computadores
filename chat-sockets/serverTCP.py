import socket
import argparse
import threading

# Referências
# https://www.dio.me/articles/faca-o-seu-proprio-chat-utilizando-python-atraves-de-sockets
# https://medium.com/swlh/lets-write-a-chat-app-in-python-f6783a9ac170


def main(host, port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
        server.bind((host, port))
        server.listen()
        print(f"Servidor TCP escutando em {host}:{port}...")

        while True:
            client, addr = server.accept()
            clients.append(client)
            print(f"Conectado por {addr}")

            thread = threading.Thread(target=handle_client, args=(client,))
            thread.start()


def handle_client(client):
    while True:
        message = client.recv(BUFSIZE)
        broadcast(message, client)


def broadcast(message, sender):
    for client in clients:
        client.sendall(message)


clients = []

HOST = "127.0.0.1"
PORT = 12345
BUFSIZE = 2048

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default=HOST)
    parser.add_argument("-p", "--port", type=int, default=PORT)

    args = parser.parse_args()

    main(**vars(args))
