import socket
import argparse
import threading

# Referência: https://www.dio.me/articles/faca-o-seu-proprio-chat-utilizando-python-atraves-de-sockets


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
        message = client.recv(2048)
        print(message.decode())


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default="127.0.0.1")
    parser.add_argument("-p", "--port", type=int, default=12345)

    args = parser.parse_args()

    main(**vars(args))
