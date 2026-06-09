import socket
import argparse


def client(host, port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((host, port))
        s.sendall(b"Hello, servidor TCP!")
        data = s.recv(1024)
    print(f"Resposta do servidor: {data.decode()}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, required=True)
    parser.add_argument("-p", "--port", type=int, required=True)

    args = parser.parse_args()

    client(**vars(args))
