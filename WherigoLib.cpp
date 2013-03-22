#include <ctime>
#include <syslog.h>
#include <SDL.h>
#include "WherigoLib.hpp"
#include "Engine.hpp"
#include "LuaBridge.h"

namespace WherigoLib {

/** Running timers and their connection to game */
map<int,SDL_TimerID> timers;
map<int,int*> timers_ids;

/** Env variables*/
std::string DEVICE = "WebOS";
std::string DIR = "./";
std::string VERSION = "2.11";
std::string SLASH = "/";

/** Lua state with running game*/
lua_State *L;

/** Currently opened Wherigo game in running engine	*/
Wherigo *WherigoOpen;

/** Variables to store showscreen, until UI is updated */
char *show_detail;
char *show_screen;



/** Log message */
void log(string message){
	WherigoOpen->log(message);
}

/** Escape characters that cant be inside JSON strings
 *  From: http://stackoverflow.com/questions/7724448/simple-json-string-escape-for-c
 */
std::string escapeJsonString(const std::string& input) {
    std::ostringstream ss;
    for (std::string::const_iterator iter = input.begin(); iter != input.end(); iter++) {
        switch (*iter) {
            case '\\': ss << "\\\\"; break;
            case '"': ss << "\\\""; break;
            case '/': ss << "\\/"; break;
            case '\b': ss << "\\b"; break;
            case '\f': ss << "\\f"; break;
            case '\n': ss << "\\n"; break;
            case '\r': ss << "\\r"; break;
            case '\t': ss << "\\t"; break;
            default: ss << *iter; break;
        }
    }
    return ss.str();
}

/** For testing purpose: Lua stack
 *  From: http://cc.byexamples.com/2008/11/19/lua-stack-dump-for-c/
 */
void stackdump_g(lua_State* l)
{
    int i;
    int top = lua_gettop(l);
 
    printf("total in stack %d\n",top);
 
    for (i = 1; i <= top; i++)
    {  /* repeat for each level */
        int t = lua_type(l, i);
        switch (t) {
            case LUA_TSTRING:  /* strings */
                printf("string: '%s'\n", lua_tostring(l, i));
                break;
            case LUA_TBOOLEAN:  /* booleans */
                printf("boolean %s\n",lua_toboolean(l, i) ? "true" : "false");
                break;
            case LUA_TNUMBER:  /* numbers */
                printf("number: %g\n", lua_tonumber(l, i));
                break;
            default:  /* other values */
                printf("%s\n", lua_typename(l, t));
                break;
        }
        printf("  ");  /* put a separator */
    }
    printf("\n");  /* end the listing */
}

/** Store what screen is going to be shown.
 *  If set, replace it (show last requested screen)
 */
void ShowScreenLua(const char *screen, const char *detail) {
	syslog(LOG_WARNING, "*** ShowScreen %s %s", screen, detail);
	if( show_screen != NULL ){
		free(show_screen);
	}
	if( show_detail != NULL ){
		free(show_detail);
	}
	show_screen = strdup(screen);
	show_detail = strdup(detail);
}

/** Save Game */
void saveState(){
	WherigoOpen->log("ZCartridge:Sync");
	// save ... @todo
}

/** get current timestamp */
long getTime(){
	time_t t = std::time(NULL);
	return t;
}

/** Add timer countdown/interval */
long addTimer(int remaining, int ObjId){
	int *id = new int; 		// new
	*id = ObjId;
	/*stringstream ss;
	ss << ":::NEW:::: Creating timer id:" << *id << ", address:" << (void*)id << " Remaining: " << remaining << ")";
	my_error(ss.str());*/
	//timer_ids[*id] = id;
	// test if is defined == should never happend! Condition in Lua ...
	if( timers[ObjId] == NULL ){
		timers[*id] = SDL_AddTimer(remaining*1000, Engine::addTimerEvent, id);
		timers_ids[*id] = id;
	} else {
		stringstream ss;
		ss << "Adding yet esisting timer id:" << ObjId;
		my_error(ss.str());
	}
	return getTime() + remaining;
}

/** Remove timer running timer */
bool removeTimer(int ObjId){
	if( timers[ObjId] != NULL ){
		SDL_bool res = SDL_RemoveTimer( timers[ObjId] );
		timers_ids.erase( ObjId );
		timers.erase(ObjId);
		return (bool)res;
	} else {
		stringstream ss;
		ss << "Timer to remove doesn't exists id:" << ObjId << " value: " << timers[ObjId];
		my_error(ss.str());
		return false;
	}
}

/** Timer expired => Call event in Lua */
void timerTick(int *ObjId){
	if( timers[*ObjId] != NULL ){
		/*bool ok = */removeTimer(*ObjId);
		/*timers.erase(*ObjId);
		timers_ids.erase(*ObjId);*/
		lua_getfield(L, LUA_GLOBALSINDEX, "Wherigo");	// [-0, +1, e]
		lua_getfield(L, -1, "ZTimer");					// [-0, +1, e]
		lua_remove(L, -2);								// [-1, +0, -]
		lua_getfield(L, -1, "_Tick");					// [-0, +1, e]
		lua_remove(L, -2);								// [-1, +0, -]
		lua_pushinteger(L, *ObjId);						// [-0, +1, e]
		int status = lua_pcall(L, 1, 0, 0);				// [-2, +(0|1), -] [-(nargs + 1), +(nresults|1), -]
		report(L, status);								// [-(0|1), +0, -]
		
		Engine::updateState(); // ??
		/*stringstream ss;
		ss << "::DELETE:: Cleaning timer (" << ok << ") id:" << *ObjId << ", address:" << (void*)ObjId;
		my_error(ss.str());*/
		delete ObjId; // delete
	} else {
		stringstream ss;
		ss << "Timer from nowhere id:" << *ObjId << ", address:" << (void*)ObjId;
		my_error(ss.str());
	}
}

/** Show messageBox to user */
void MessageBox(const char *text, const char *media,
		const char *button1, const char *button2, const char *callback) {
	/*cerr << "MessageBox:" << text;
	if( strcmp(button1, "") != 0 || strcmp(button2, "") != 0 ){
		cerr << " >> Options: " << button1 << " | " << button2;
	}*/
	string m;
	if( strcmp(media, "") != 0 ){
		m = WherigoOpen->getFilePathById(media);
		//cerr << " >> Media (" << media << "): " << m;
	}
	//cerr << endl;
	//syslog(LOG_WARNING, "*** MessageBox with message: %s", text);
	WherigoOpen->log( string("MessageBox  Text: ").append(text) );
	
	Engine::MessageBox(text, m, button1, button2, callback);
	return;
}

/** Response to user click on button on MessageBox */
void MessageBoxResponse(const char *value){
	lua_getfield(L, LUA_GLOBALSINDEX, "Wherigo");	// [-0, +1, e]
	lua_getfield(L, -1, "_MessageBoxResponse");		// [-0, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	lua_pushstring(L, value);						// [-0, +1, e]
	int status = lua_pcall(L, 1, 0, 0);				// [-2, +(0|1), -] [-(nargs + 1), +(nresults|1), -]
	report(L, status);								// [-(0|1), +0, -]
	Engine::updateState();
}

/** Get user input */
void GetInput(const char *type, const char *text, const char* choices, const char* media) {
	//syslog(LOG_WARNING, "*** GetInput");
	
	string m;
	if( strcmp(media, "") != 0 ){
		m = WherigoOpen->getFilePathById(media);
	}
	Engine::GetInput(type, text, choices, m);
}

/** Response to user input */
void GetInputResponse(const char *value){
	lua_getfield(L, LUA_GLOBALSINDEX, "Wherigo");	// [-0, +1, e]
	lua_getfield(L, -1, "_GetInputResponse");		// [-0, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	lua_pushstring(L, value);						// [-0, +1, e]
	int status = lua_pcall(L, 1, 0, 0);				// [-2, +(0|1), -] [-(nargs + 1), +(nresults|1), -]
	report(L, status);								// [-(0|1), +0, -]
	//my_error(string("GetInputResponse value:").append(value));
	Engine::updateState();
}

/** Call function as response to user action */
void CallbackFunction(const char *event, int * id){
	/*stringstream ss;
	ss << "Wherigo._callback(\""
		<< event << "\", " << *id << ")";
	int status = luaL_dostring(L, ss.str().c_str());
	report(L, status);*/
	
	lua_getfield(L, LUA_GLOBALSINDEX, "Wherigo");	// [-0, +1, e]
	lua_getfield(L, -1, "_callback");				// [-0, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	lua_pushstring(L, event);						// [-0, +1, m]
	lua_pushinteger(L, *id);						// [-0, +1, m]
	int status = lua_pcall(L, 2, 0, 0);				// [-3, +(0|1), -] [-(nargs + 1), +(nresults|1), -]
	report(L, status);								// [-(0|1), +0, -]
	
	//SDL_Delay(5);
	// push updates to JS side
	Engine::updateState();

}

/** Play audio */
void PlayAudio(const char *media) {
	syslog(LOG_WARNING, "*** PlayAudio");

    Engine::PlayAudio( WherigoOpen->getFilePathById(media) );
	return;
}


/** Close Lua environment */
void exit_lua(){
	if( L != NULL ){
		lua_close(L);
		L = NULL;
	}
}

/** Open new Lua environment and init Wherigo library */
lua_State * openLua(Wherigo *w){
	// new Lua state
	if( L != NULL ){
		exit_lua();
	}
	
	int status;
	L = lua_open();  /* create state */
	if (L == NULL) {
		my_error("cannot create state: not enough memory");
		return NULL;
	}
	luaL_openlibs(L);

	atexit( exit_lua );
	//my_error("*** MAIN LUA");

	// messageBox as CFunction
	//lua_register(L, "messageBox", messageBox);
	
	// Env and other variables
	
	luabridge::getGlobalNamespace(L)
		.beginNamespace("Env")
			.addVariable("CartFilename", &w->filename, true)
			.addVariable("Device", &w->recomandedDevice, false)
			.addVariable("Platform", &DEVICE, false)
			.addVariable("CartFolder", &w->cartDir, false)
			.addVariable("SyncFolder", &DIR, false)
			.addVariable("PathSep", &SLASH, false)
			.addVariable("DeviceID", &DEVICE, false)
			.addVariable("Version", &VERSION, false)
			.addVariable("LogFolfer", &DIR)
			.addVariable("_CompletionCode", &w->completionCode)
			.addVariable("_Player", &w->player)
			.addVariable("_IconId", &w->iconID)
			.addVariable("_SplashId", &w->splashID)
			//.addVariable("Downloaded", &0, false)
		.endNamespace();
		
	luabridge::getGlobalNamespace(L)
		.beginNamespace("WIGInternal")
			.addFunction("MessageBox", MessageBox)
			.addFunction("PlayAudio", PlayAudio)
			.addFunction("ShowScreen", ShowScreenLua)
			.addFunction("GetInput", GetInput)
			.addFunction("ShowStatusText", Engine::ShowStatusText)
			.addFunction("escapeJsonString", escapeJsonString)
			.addFunction("save", saveState)
			.addFunction("addTimer", addTimer)
			.addFunction("removeTimer", removeTimer)
			.addFunction("getTime", getTime)
			.addFunction("LogMessage", log)
		.endNamespace();
			
	// library in Lua
	status = luaL_dofile(L, "wherigo.lua");
	report(L, status);
	if( status != 0 ){
		my_error("Failed to load wherigo library");
		return NULL;
	}
	return L;
}

/** Open file with cartridge and run in new environment */
int openCartridge(char *filename){
	WherigoOpen = new Wherigo( string(DATA_DIR).append(filename) );
	if( ! WherigoOpen->setup() ){
		delete WherigoOpen;
		WherigoOpen = NULL;
		return 0;
	}
	WherigoOpen->createFiles(); // files
	WherigoOpen->createBytecode();
	WherigoOpen->openLog();
	
	int status;
	L = openLua(WherigoOpen);
	if( L == NULL ){
		/*if( PDL_IsPlugin() ){
			// send error to UI
		}*/
		return 0;
	}
	
	// do bytecode from cartridge
	string bytecode = WherigoOpen->getCartDir();
	bytecode.append("wig.luac");
	
	//status = lua_cpcall(L, &pmain, &bytecode);
	status = luaL_dofile(L, bytecode.c_str());
	report(L, status);
	// create global Lua variable
	if( status == 0 ){
		lua_setglobal(L, "cartridge"); // by http://wherigobuilder.wikispaces.com/Globals
	} else {
		MessageBox("Error loading cartridge file. See log for more details", "", "", "", "");
		delete WherigoOpen;
		WherigoOpen = NULL;
		return 0;
	}
	
	//stackdump_g(L);
	
	return 1;
} 


/** Close cartridge and clean all variables */
void closeCartridge(int *save){
	// @todo save
	
	std::map<int,SDL_TimerID>::iterator it;
	for (it=timers.begin(); it!=timers.end(); ++it){
		removeTimer( it->first );
	}
	if( !timers.empty() || !timers_ids.empty() ){
		my_error("ERR: Timers array should be now empty ...");
	}
	timers.clear(); // should be empty
	
	WherigoOpen->closeLog();
	delete WherigoOpen;
    
	exit_lua();
}

void OnStartEvent(){
	stringstream buffer;
	// move to starting coordinates and call update position
	// only for debug ... in production, it is not desired
	cerr << "Updating position" << endl;
	buffer << "cartridge._update( Wherigo.ZonePoint("
		<< WherigoOpen->lat << ", " << WherigoOpen->lon << ", "
		<< WherigoOpen->alt << "), 1000 )";
	int status = luaL_dostring(L, buffer.str().c_str());
	report(L, status);
	
	
	// run onStart event
	/*status = luaL_dostring(L, "cartridge.OnStart() ");
	report(L, status);*/
	lua_getfield(L, LUA_GLOBALSINDEX, "cartridge");	// [-0, +1, e]
	lua_getfield(L, -1, "OnStart");					// [-0, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	// test if there is such method
	int type = lua_type(L, -1);					
	if( type == LUA_TFUNCTION ){
		WherigoOpen->log("ZCartridge:OnStart START");
		status = lua_pcall(L, 0, 0, 0);					// [-1, +(0|1), -] [-(nargs + 1), +(nresults|1), -]
		report(L, status);								// [-(0|1), +0, -]
		WherigoOpen->log("ZCartridge:OnStart END__");
	} else {
		lua_remove(L, -1);
	}
}


string getUI(){
	lua_getfield(L, LUA_GLOBALSINDEX, "Wherigo");	// [-0, +1, e]
	lua_getfield(L, -1, "_getUI");					// [-0, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	int status = lua_pcall(L, 0, 1, 0);					// [-1, +1, -] [-(nargs + 1), +(nresults|1), -]
	
	if( status == 0 ){
		string result;
		int type = lua_type(L, 1);					// [-0, +0, -]
		if( type == LUA_TSTRING ){
			result = lua_tostring(L, 1);			// [-0, +0, m]
		}
		lua_remove(L, 1);							// [-1, +0, -]
		return result;
	} else {
		report(L, status);							// [-1, +0, -]
		my_error("Problem getting UI informations");
		return "";
	}
}

bool updateLocation(double *lat, double *lon, double *alt, double *accuracy){
	bool update_all = false;
	stringstream ss;
	time_t t = time(NULL);
	ss << "return cartridge._update(Wherigo.ZonePoint("
		<< *lat << ", " << *lon << ", Distance(" << *alt << ")), "
		<< t << ", " << *accuracy << ", 0)";
	int status = luaL_dostring(L, ss.str().c_str());
	if( status == 0 ){
		update_all = lua_toboolean(L, 1);
		stackdump_g(L);
		lua_pop(L, 1);
	} else {
		report(L, status);
	}
	return update_all;
	
}

}

