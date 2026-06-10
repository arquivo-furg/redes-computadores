import argparse
import threading
import tkinter as tk
from socket import socket, AF_INET, SOCK_STREAM
from functools import partial
from constants import *


def main(host: str, port: int):
    with socket(AF_INET, SOCK_STREAM) as client:
        # Tenta uma conexão ao servidor socket no endereço definido
        try:
            client.connect((host, port))
        except:
            return print(f"Não foi possível conectar-se a {host}:{port}.")

        # Desenha o input da mensagem e o botão de enviar
        field = tk.Entry(window, textvariable=input, width=50)
        field.bind("<Return>", partial(send_message, client))
        field.pack()
        # O uso de partial é para bindar o socket do cliente com as funções de envio
        send = tk.Button(window, text="Enviar", command=partial(send_message, client))
        send.pack()
        # Evento acionado quando a janela é fechada pela GUI
        window.protocol("WM_DELETE_WINDOW", partial(on_closing, client))

        # Cria e inicia uma nova thread para lidar com o recebimento das mensagens
        threading.Thread(target=recv_messages, args=(client,)).start()

        tk.mainloop()  # Inicia a GUI


def recv_messages(client: socket):
    while True:
        try:
            message = client.recv(BUFSIZE).decode()

            if message == CMD.QUIT:
                close(client)
                break

            messages.insert(tk.END, message)
        except OSError:
            break


def send_message(client: socket, event=None):
    message = input.get()
    input.set("")

    if message == CMD.HELP:
        handle_command(CMD.HELP)
        return

    if message == CMD.CLEAR:
        handle_command(CMD.CLEAR)
        return

    client.sendall(message.encode())


def close(client: socket):
    client.close()
    window.quit()


def on_closing(client: socket, event=None):
    input.set(CMD.QUIT)
    send_message(client)


def handle_command(command: str, client: socket | None = None, event=None):
    if command == CMD.HELP:
        for cmd in HELP_TEXT:
            messages.insert(tk.END, cmd)

    if command == CMD.CLEAR:
        messages.delete(0, tk.END)


# Cria uma janela do Tkinter para desenhar a lista de mensagens, input e botão
window = tk.Tk()
window.title("Chat")

messages_frame = tk.Frame(window)
messages_frame.pack()

input = tk.StringVar()  # Variável que guarda o texto da mensagem escrita

scrollbar = tk.Scrollbar(messages_frame)
scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

# Lista de mensagens onde serão escritas as mensagens recebidas
messages = tk.Listbox(messages_frame, height=20, width=75, yscrollcommand=scrollbar.set)
messages.pack(side=tk.LEFT, fill=tk.BOTH)


if __name__ == "__main__":
    # Admite argumentos passados ao executável através de flags --host e --port
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default=HOST)
    parser.add_argument("-p", "--port", type=int, default=PORT)

    args = parser.parse_args()

    # Incilializa o código do cliente repassando o host e port definidos
    main(**vars(args))
