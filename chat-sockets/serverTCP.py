import socket
import argparse
import threading

# Referência: https://www.dio.me/articles/faca-o-seu-proprio-chat-utilizando-python-atraves-de-sockets

clients = []


def main(host, port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
        server.bind((host, port))
        server.listen()
        print(f"Servidor TCP escutando em {host}:{port}...")

        while True:
            client, addr = server.accept()
            clients.append(client)
            print(f"Conectado por {addr}")

            thread = threading.Thread(target=handleMessages, args=(client,))
            thread.start()


def handleMessages(client):
    while True:
        message = client.recv(2048)
        sendMessage(message, client)


def sendMessage(message, sender):
    for client in clients:
        if client != sender:
            client.sendall(message)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default="127.0.0.1")
    parser.add_argument("-p", "--port", type=int, default=12345)

    args = parser.parse_args()

    main(**vars(args))
