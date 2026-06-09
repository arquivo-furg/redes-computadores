import argparse
import threading
import tkinter as tk
from socket import socket, AF_INET, SOCK_STREAM
from functools import partial

# Referências
# https://www.dio.me/articles/faca-o-seu-proprio-chat-utilizando-python-atraves-de-sockets
# https://medium.com/swlh/lets-write-a-chat-app-in-python-f6783a9ac170


def main(host: str, port: int):
    with socket(AF_INET, SOCK_STREAM) as client:
        try:
            client.connect((host, port))
        except:
            return print(f"Não foi possível conectar-se a {host}:{port}.")

        field = tk.Entry(input_frame, textvariable=input, width=40)
        field.bind("<Return>", partial(send_message, client))
        field.pack(side=tk.LEFT, padx=(0, 5))

        send = tk.Button(
            input_frame, text="Enviar", command=partial(send_message, client)
        )
        send.pack(side=tk.LEFT)

        window.protocol("WM_DELETE_WINDOW", partial(on_closing, client))

        threading.Thread(target=recv_messages, args=(client,)).start()

        tk.mainloop()


def recv_messages(client: socket):
    while True:
        try:
            message = client.recv(BUFSIZE).decode()

            if message == "/quit":
                close(client)
                break

            if message.startswith("/add"):
                username = message.split(" ")[1]
                add_user(username)

            if message.startswith("/remove"):
                username = message.split(" ")[1]
                rem_user(username)

            messages.insert(tk.END, message)
        except OSError:
            break


def send_message(client: socket, event=None):
    message = input.get()
    input.set("")
    client.sendall(message.encode())


def close(client: socket):
    client.close()
    window.quit()


def on_closing(client: socket, event=None):
    input.set("/quit")
    send_message(client)


def add_user(username: str):
    chats.add(username)
    update_chats()


def rem_user(username: str):
    chats.remove(username)
    update_chats()


def update_chats():
    chat_list.delete(0, tk.END)
    for chat in chats:
        chat_list.insert(tk.END, chat)


window = tk.Tk()
window.title("Chat")
window.geometry("600x400")

panel = tk.PanedWindow(window, orient=tk.HORIZONTAL)
panel.pack(fill=tk.BOTH, expand=True)

chats_frame = tk.Frame(panel, bg="lightgray", width=200)
panel.add(chats_frame)
chat_list = tk.Listbox(chats_frame)
chat_list.pack(fill=tk.BOTH, expand=True)

messages_frame = tk.Frame(panel)
panel.add(messages_frame)
scrollbar = tk.Scrollbar(messages_frame)
scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
messages = tk.Listbox(messages_frame, yscrollcommand=scrollbar.set)
messages.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
scrollbar.config(command=messages.yview)

input_frame = tk.Frame(window)
input_frame.pack(pady=5)
input = tk.StringVar()

chats: set[str] = set()

HOST = "127.0.0.1"
PORT = 12345
BUFSIZE = 2048

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default=HOST)
    parser.add_argument("-p", "--port", type=int, default=PORT)

    args = parser.parse_args()

    main(**vars(args))
