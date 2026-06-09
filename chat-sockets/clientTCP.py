import socket
import argparse
import threading
import tkinter
from functools import partial

# Referências
# https://www.dio.me/articles/faca-o-seu-proprio-chat-utilizando-python-atraves-de-sockets
# https://medium.com/swlh/lets-write-a-chat-app-in-python-f6783a9ac170


def main(host, port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
        try:
            client.connect((host, port))
        except:
            return print(f"Não foi possível conectar-se a {host}:{port}.")

        entry_field = tkinter.Entry(window, textvariable=input)
        entry_field.bind("<Return>", partial(send_message, client))
        entry_field.pack()
        send_button = tkinter.Button(
            window, text="Enviar", command=partial(send_message, client)
        )
        send_button.pack()

        window.protocol("WM_DELETE_WINDOW", partial(on_closing, client))

        threading.Thread(target=recv_messages, args=(client,)).start()

        tkinter.mainloop()


def recv_messages(client):
    while True:
        try:
            message = client.recv(BUFSIZE).decode()

            if message == "/quit":
                close(client)
                break

            messages.insert(tkinter.END, message)
        except OSError:
            break


def send_message(client, event=None):
    message = input.get()
    input.set("")
    client.sendall(message.encode())


def close(client):
    client.close()
    window.quit()


def on_closing(client, event=None):
    input.set("/quit")
    send_message(client)


window = tkinter.Tk()
window.title("Chat")

messages_frame = tkinter.Frame(window)
messages_frame.pack()

input = tkinter.StringVar()

scrollbar = tkinter.Scrollbar(messages_frame)
scrollbar.pack(side=tkinter.RIGHT, fill=tkinter.Y)

messages = tkinter.Listbox(
    messages_frame, height=20, width=75, yscrollcommand=scrollbar.set
)
messages.pack(side=tkinter.LEFT, fill=tkinter.BOTH)
messages.pack()


HOST = "127.0.0.1"
PORT = 12345
BUFSIZE = 2048

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default=HOST)
    parser.add_argument("-p", "--port", type=int, default=PORT)

    args = parser.parse_args()

    main(**vars(args))
