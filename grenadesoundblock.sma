// *************************************************************************************//
// www.neugomon.ru									//
// Neygomon  [ https://neugomon.ru/members/1/ ]						//
// https://neugomon.ru/threads/191/ 							//
// www.neugomon.ru              							//
// *************************************************************************************//

#include <amxmodx>
 
new const g_sFireInTheHole[] = "#Fire_in_the_hole", g_sFireInTheHoleSound[] = "%!MRAD_FIREINHOLE";
new sound[sizeof(g_sFireInTheHoleSound)], text[sizeof(g_sFireInTheHole)];
 
public plugin_init()
{
   register_plugin("Block grande info", "1.0", "neygomon");
   register_message(get_user_msgid("TextMsg"),"msgTextMsg");
   register_message(get_user_msgid("SendAudio"),"msgSendAudio");
}   
 
public msgTextMsg()
{
   if(get_msg_args() == 5 && get_msg_argtype(5) == ARG_STRING) 
   {
      get_msg_arg_string(5, text, sizeof text - 1);
      if(equali(text, g_sFireInTheHole)) return PLUGIN_HANDLED
   }
   return PLUGIN_CONTINUE
}
public msgSendAudio() 
{
   get_msg_arg_string(2, sound, sizeof sound - 1);
   return equali(sound, g_sFireInTheHoleSound);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1038\\ f0\\ fs16 \n\\ par }
*/
