HOST = "127.0.0.1"
PORT = 12345
BUFSIZE = 2048


class CMD:
    HELP = "/help"
    QUIT = "/quit"
    CLEAR = "/clear"
    PRIVATE = "/private"
    GROUP = "/group"
    # GLOBAL = "/global"


HELP_TEXT = [
    f"{CMD.HELP} - Mostrar esta tela de ajuda",
    f"{CMD.QUIT} - Encerrar chat e desconectar-se",
    f"{CMD.CLEAR} - Limpar a janela do chat",
    f"{CMD.PRIVATE} - Listar usuários ativos",
    f"{CMD.PRIVATE} [username] - Iniciar uma conversa privada com um usuário",
    f"{CMD.GROUP} - Listar seus grupos ativos",
    f"{CMD.GROUP} [gropuname] - Iniciar conversa com um de seus grupos",
    f"{CMD.GROUP} [gropuname] [username1] [...] - Criar grupo com usuários",
    # f"{CMD.GLOBAL} - Convesar com todos usuários conectados",
]
