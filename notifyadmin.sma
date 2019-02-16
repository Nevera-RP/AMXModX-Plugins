#include <amxmodx>
#include <sockets>

new g_sckweb //socket "id"

#define SCRIPT_NAME "/myplugin/parser.php"
#define REMOTE_HOST "myserver.com" //port d.80

public plugin_init()
{
    register_plugin("Socket sample", "??" ,"Darksnow")
    set_task(5.0,"connect_web") 
}

stock ExplodeString( p_szOutput[][], p_nMax, p_nSize, p_szInput[], p_szDelimiter ) { // Function by xeroblood
    new nIdx = 0, l = strlen(p_szInput)
    new nLen = (1 + copyc( p_szOutput[nIdx], p_nSize, p_szInput, p_szDelimiter ))
    while( (nLen < l) && (++nIdx < p_nMax) )
        nLen += (1 + copyc( p_szOutput[nIdx], p_nSize, p_szInput[nLen], p_szDelimiter ))
    return nIdx
}

public write_web(text[512])
{
    socket_send(g_sckweb, text, 511)
}

public disconnect_web()
{
    server_print("Socket disconnected")
}

public read_web(){
	const SIZE = 63
	new line_variable[SIZE + 1], line_value[SIZE + 1]
	if (socket_change(g_sckweb, 100)){
		new buf[512], lines[30][100], count = 0
		socket_recv(g_sckweb, buf, 511)
		count = ExplodeString(lines, 50, 119, buf, 13)
		for(new i=0;i<count;i++){
			parse(lines[i], line_variable, SIZE, line_value, SIZE)
			if (equal(line_variable, "some_value")){
				server_print("Value is %s", line_value)
			}
		}   
		if (g_sckweb != 0)
		set_task(0.5, "read_web")
		else
		disconnect_web()
	}
}

public connect_web(){
	new error = 0
	new constring[512]

	g_sckweb = socket_open(REMOTE_HOST, 80, SOCKET_TCP, error)
	if (g_sckweb > 0){
		format(constring,511,"GET %s HTTP/1.1^nHost: %s^n^n",SCRIPT_NAME,REMOTE_HOST)
		write_web(constring)
		read_web()
	}else{
		switch (error){
			case 1: { server_print("Error creating socket"); }
			case 2: { server_print("Error resolving remote hostname"); }
			case 3: { server_print("Error connecting socket"); }
		}
	}
	return PLUGIN_CONTINUE
}