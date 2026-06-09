import socket
import argparse


def server(host, port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((host, port))
        s.listen()
        print(f"Servidor TCP escutando em {host}:{port}...")
        conn, addr = s.accept()
        with conn:
            print(f"Conectado por {addr}")
            while True:
                data = conn.recv(1024)
                if not data:
                    break
                print(f"Recebido: {data.decode()}")
                data2 = b"Ola, Cliente!"
                conn.sendall(data2)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default="127.0.0.1")
    parser.add_argument("-p", "--port", type=int, default=12345)

    args = parser.parse_args()

    server(**vars(args))
