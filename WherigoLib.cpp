#include <ctime>
#include <syslog.h>
#include <SDL.h>
#include "WherigoLib.hpp"
#include "WherigoLib.Save.hpp"
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
int TIME = 0;

/** Lua state with running game*/
lua_State *L;

/** Currently opened Wherigo game in running engine	*/
Wherigo *WherigoOpen;

/** Variables to store showscreen, until UI is updated */
char *show_detail;
char *show_screen;

/** Temporary stored coordinates from last GPS update */
double latitude = 0;
double longitude = 0;
double altitude = 0;
double accuracy = 5;


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
	const char *data;
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
            case LUA_TTABLE: /* tables/objects */
				lua_getfield(l, i, "_classname");
				if( !lua_isnoneornil(l, -1) ){
					data = lua_tostring(l, -1);
				} else {
					data = "(table)";
				}
                printf("object: %s\n", data);
                lua_pop(l, 1);
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
bool sync(){
	WherigoOpen->log("ZCartridge:Sync");
	return WherigoLib::Save::sync();
}

bool restore(){
	WherigoOpen->log("ZCartridge:Restore");
	return WherigoLib::Save::restore();
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
	string *m;
	if( strcmp(media, "") != 0 ){
		m = WherigoOpen->getFilePathById(media);
		//cerr << " >> Media (" << media << "): " << m;
	} else {
		m = new string("");
	}
	//cerr << endl;
	//syslog(LOG_WARNING, "*** MessageBox with message: %s", text);
	WherigoOpen->log( string("MessageBox  Text: ").append(text) );
	
	Engine::MessageBox(text, *m, button1, button2, callback);
	delete m;
	return;
}

/** Show messageBox to user */
void Dialog(const char *text, const char *media) {
	string *m;
	if( strcmp(media, "") != 0 ){
		m = WherigoOpen->getFilePathById(media);
		//cerr << " >> Media (" << media << "): " << m;
	} else {
		m = new string("");
	}
	WherigoOpen->log( string("Dialog  Text: ").append(text) );
	
	Engine::Dialog(text, *m);
	delete m;
	return;
}

/** Ask user, if realy close cartridge */
void close() {
	WherigoOpen->log("Close prompt");
	
	Engine::ClosePrompt();
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
	
	string *m;
	if( strcmp(media, "") != 0 ){
		m = WherigoOpen->getFilePathById(media);
	} else {
		m = new string("");
	}
	Engine::GetInput(type, text, choices, *m);
	delete m;
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

	string *m = WherigoOpen->getFilePathById(media);
    Engine::PlayAudio( *m );
    delete m;
	return;
}


/** Close Lua environment */
void exit_lua(){
	if( L != NULL ){
		lua_close(L);
		L = NULL;
	}
}

void lua_openlib(lua_State *L, lua_CFunction f){
	lua_pushcfunction(L, f);
	lua_pushstring(L, "");
	lua_call(L, 1, 0);
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
	//luaL_openlibs(L); // removed os, io and debug
	lua_openlib(L, luaopen_base);
	lua_openlib(L, luaopen_package);
	lua_openlib(L, luaopen_table);
	lua_openlib(L, luaopen_string);
	lua_openlib(L, luaopen_math);
	lua_openlib(L, luaopen_os); // should disable remove() function 
	lua_openlib(L, luaopen_debug); 
	
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
			.addVariable("LogFolder", &DIR, false)
			.addVariable("_CompletionCode", &w->completionCode, false)
			.addVariable("_Player", &w->player, false)
			.addVariable("_IconId", &w->iconID, false)
			.addVariable("_SplashId", &w->splashID, false)
			.addVariable("_Company", &w->company, false)
			.addVariable("_Activity", &w->type, false)
			.addVariable("Downloaded", &TIME, false)
		.endNamespace();
		
	luabridge::getGlobalNamespace(L)
		.beginNamespace("WIGInternal")
			.addFunction("MessageBox", MessageBox)
			.addFunction("Dialog", Dialog)
			.addFunction("PlayAudio", PlayAudio)
			.addFunction("ShowScreen", ShowScreenLua)
			.addFunction("GetInput", GetInput)
			.addFunction("ShowStatusText", Engine::ShowStatusText)
			.addFunction("escapeJsonString", escapeJsonString)
			.addFunction("RequestSync", Engine::RequestSync)
			.addFunction("close", close)
			.addFunction("addTimer", addTimer)
			.addFunction("removeTimer", removeTimer)
			.addFunction("getTime", getTime)
			.addFunction("LogMessage", log)
			.addFunction("StopSound", Engine::stopSound)
			.addFunction("Alert", Engine::Alert)
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
		Dialog("Error loading cartridge file. See log for more details", "");
		delete WherigoOpen;
		WherigoOpen = NULL;
		return 0;
	}
	
	//stackdump_g(L);
	
	return 1;
} 


/** Close cartridge and clean all variables */
void closeCartridge(int *save){
	if( *save == 1 ){
		sync();
	}
	
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

void DoCartridgeEvent(const char *event){
	stringstream buffer;
	// move to starting coordinates and call update position
	// only for debug ... in production, it is not desired
	double acc = 5;
	updateLocation(&WherigoOpen->lat, &WherigoOpen->lon, &WherigoOpen->alt, &acc);
	
	
	// run onStart event
	/*status = luaL_dostring(L, "cartridge.OnStart() ");
	report(L, status);*/
	lua_getfield(L, LUA_GLOBALSINDEX, "cartridge");	// [-0, +1, e]
	lua_getfield(L, -1, event);					// [-0, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	// test if there is such method
	int type = lua_type(L, -1);					
	if( type == LUA_TFUNCTION ){
		WherigoOpen->log(string("ZCartridge:") + event + " START");
		// argument self
		lua_getfield(L, LUA_GLOBALSINDEX, "cartridge");	// [-0, +1, e]
		int status = lua_pcall(L, 1, 0, 0);			// [-1, +(0|1), -] [-(nargs + 1), +(nresults|1), -]
		report(L, status);							// [-(0|1), +0, -]
		WherigoOpen->log(string("ZCartridge:") + event + " END__");
	} else {
		lua_remove(L, -1);
	}
}

void OnStartEvent(int *load_game){
	if( *load_game == 1 && WherigoLib::restore() ){
		DoCartridgeEvent("OnRestore");
		return;
	}
	DoCartridgeEvent("OnStart");

}


string getUI(){
	lua_getfield(L, LUA_GLOBALSINDEX, "Wherigo");	// [-0, +1, e]
	lua_getfield(L, -1, "_getUI");					// [-0, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	int status = lua_pcall(L, 0, 1, 0);					// [-1, +1, -] [-(nargs + 1), +(nresults|1), -]
	
	if( status == 0 ){
		string result;
		int type = lua_type(L, -1);					// [-0, +0, -]
		if( type == LUA_TSTRING ){
			result = lua_tostring(L, -1);			// [-0, +0, m]
		}
		lua_pop(L, 1);								// [-1, +0, -]
		return result;
	} else {
		report(L, status);							// [-1, +0, -]
		my_error("Problem getting UI informations");
		return "";
	}
}

void showMap(int *zone_id){
	stringstream ss;
	bool first = true;
	ss << "[";
	lua_getfield(L, LUA_GLOBALSINDEX, "cartridge");	// [-0, +1, e]
	lua_getfield(L, -1, "AllZObjects");				// [-0, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	lua_pushinteger(L, *zone_id);					// [-0, +1, -]
	lua_gettable(L, -2);							// [-1, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	if( !lua_isnoneornil(L, -1) ){
		lua_getfield(L, -1, "Points");				// [-0, +1, -]
		lua_remove(L, -2);							// [-1, +0, -]
		lua_pushnil(L);
		while( lua_next(L, -2) != 0 ){
			if( !first ){
				ss << ", ";
			} else {
				first = false;
			}
			lua_getfield(L, -1, "latitude");		// [-0, +1, -]
			ss << "{\"name\": \"zone\", \"lat\": " << lua_tostring(L, -1);
			lua_pop(L, 1);							// [-1, +0, -]
			lua_getfield(L, -1, "longitude");		// [-0, +1, -]
			ss << ", \"lon\": " << lua_tostring(L, -1) << "}";
			
			lua_pop(L, 2);
		}
	}
	lua_pop(L, 1);
	ss << "]";
	//syslog(LOG_WARNING, "*** showMap action: %s", ss.str().c_str());
	Engine::showMapResponse(ss.str());
}

bool updateLocationInt(){
	int status;
	bool update_all = false;
	time_t t = time(NULL);
	lua_getfield(L, LUA_GLOBALSINDEX, "cartridge"); // [-0, +1, e]
	lua_getfield(L, -1, "_update");					// [-0, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	lua_getfield(L, LUA_GLOBALSINDEX, "Wherigo");	// [-0, +1, e]
	lua_getfield(L, -1, "ZonePoint");				// [-0, +1, e]
	lua_pushnumber(L, latitude);					// [-0, +1, -]
	lua_pushnumber(L, longitude);					// [-0, +1, -]
	lua_getfield(L, -4, "Distance");				// [-0, +1, e] -
	lua_pushinteger(L, 0);							// [-0, +1, -] -
	status = lua_pcall(L, 1, 1, 0);					// [-2, +1, e] -
	report(L, status);
	status = lua_pcall(L, 3, 1, 0);					// [-4, +1, e]
	report(L, status);
	lua_remove(L, -2);								// [-1, +0, -]
	lua_pushinteger(L, t);							// [-0, +1, -]
	lua_pushinteger(L, accuracy);					// [-0, +1, -]
	lua_pushinteger(L, 0);							// [-0, +1, -]
	status = lua_pcall(L, 4, 1, 0);				// [-5, +1, e]
	/*ss << "return cartridge._update(Wherigo.ZonePoint("
		<< *lat << ", " << *lon << ", Distance(" << *alt << ")), "
		<< t << ", " << *acc << ", 0)";
	int status = luaL_dostring(L, ss.str().c_str());*/
	if( status == 0 ){
		update_all = lua_toboolean(L, 1);
		lua_pop(L, 1);
	} else {
		report(L, status);
	}
	return update_all;
}

bool updateLocation(double *lat, double *lon, double *alt, double *acc){
	latitude = *lat;
	longitude = *lon;
	altitude = *alt;
	accuracy = *acc;
	return updateLocationInt();
	
}

bool moveLocation(double *lat, double *lon){
	latitude += *lat;
	longitude += *lon;
	return updateLocationInt();
}

}

