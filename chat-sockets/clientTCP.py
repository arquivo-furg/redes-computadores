import socket
import argparse
import threading

# Referências
# https://www.dio.me/articles/faca-o-seu-proprio-chat-utilizando-python-atraves-de-sockets
# https://medium.com/swlh/lets-write-a-chat-app-in-python-f6783a9ac170


def main(host, port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
        client.connect((host, port))

        thread_send = threading.Thread(target=sendMessages, args=(client,))
        thread_recv = threading.Thread(target=recvMessages, args=(client,))

        thread_send.start()
        thread_recv.start()

        thread_send.join()
        thread_recv.join()


def sendMessages(client):
    while True:
        message = input("\nMensagem: ")
        client.sendall(message.encode())


def recvMessages(client):
    while True:
        message = client.recv(BUFSIZE)
        print(message.decode())


HOST = "127.0.0.1"
PORT = 12345
BUFSIZE = 2048

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default=HOST)
    parser.add_argument("-p", "--port", type=int, default=PORT)

    args = parser.parse_args()

    main(**vars(args))
