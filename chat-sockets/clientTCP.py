import socket
import argparse


def client(host, port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((host, port))

        while True:
            message = input("Mensagem: ")
            s.sendall(message.encode())
            data = s.recv(1024)
            print(f"Resposta do servidor: {data.decode()}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default="127.0.0.1")
    parser.add_argument("-p", "--port", type=int, default=12345)

    args = parser.parse_args()

    client(**vars(args))
