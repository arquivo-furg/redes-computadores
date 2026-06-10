HOST = "127.0.0.1"
PORT = 12345
BUFSIZE = 2048


class CMD:
    HELP = "/help"
    QUIT = "/quit"
    CLEAR = "/clear"
    PRIVATE = "/private"
    GROUP = "/group"


HELP_TEXT = f"""
{CMD.HELP} - Mostrar esta tela de ajuda
{CMD.QUIT} - Encerrar chat e desconectar-se
{CMD.CLEAR} - Limpar a janela do chat
{CMD.PRIVATE} - Listar usuários ativos
{CMD.PRIVATE} [username] - Iniciar uma conversa privada com um usuário
{CMD.GROUP} - Listar seus grupos ativos
{CMD.GROUP} [gropuname] - Iniciar conversa com um de seus grupos
{CMD.GROUP} [gropuname] [username1] [...] - Criar grupo com usuários
"""
