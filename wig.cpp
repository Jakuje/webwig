#include <map>
#include <string>
#include <cstdio>
#include <syslog.h>

#include <glob.h>
#include <sys/stat.h>

#include "wherigo.h"

/**
 * Includes for PDK for webOS app
 */
#include "SDL.h"
#include "PDL.h"

#include "lua_common.h"

using namespace std;

const string DATA_DIR = "/media/internal/appdata/com.dta3team.app.wherigo/";
const string CONF_DIR = DATA_DIR + ".conf";
const string CONFIG_FILE = "database.json";

enum EVENT_CODES {GET_CARTRIDGES, GET_METADATA};

lua_State *L;

#define EXIT(n) do { fprintf(stderr, "Early exit at %s:%d\n", __FILE__, __LINE__); exit(n); } while (0)

// http://stackoverflow.com/questions/7724448/simple-json-string-escape-for-c
std::string escapeJsonString(const std::string& input) {
    std::ostringstream ss;
    //for (auto iter = input.cbegin(); iter != input.cend(); iter++) {
    //C++98/03:
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

/**
 * @param cartridge (string) Name of file to get cartridges
 */
static PDL_bool getMetadata(PDL_JSParameters *params)
{
    if (PDL_GetNumJSParams(params) != 1) {
        syslog(LOG_INFO, "**** wrong number of parameters for getMetadata");
        PDL_JSException(params, "wrong number of parameters for getMetadata");
        return PDL_FALSE;
    }

    /* parameters are directory, pattern */
    const char *cartridge = PDL_GetJSParamString(params, 0);

    /* since we don't process this in the method thread, instead post a
     * SDL event that will be received in the main thread and used to 
     * launch the code. */
    SDL_Event event;
    event.user.type = SDL_USEREVENT;
    event.user.code = GET_METADATA;
    event.user.data1 = strdup(cartridge);
    
    syslog(LOG_WARNING, "*** sending getMetadata event");
    SDL_PushEvent(&event);
    
    return PDL_TRUE;
}

/**
 * @param refresh (bool) Return 
 */
static PDL_bool getCartridges(PDL_JSParameters *params)
{
    if (PDL_GetNumJSParams(params) != 1) {
        syslog(LOG_INFO, "**** wrong number of parameters for getCartridges");
        PDL_JSException(params, "wrong number of parameters for getCartridges");
        return PDL_FALSE;
    }

    /* parameters are directory, pattern */
    int *refresh = new int;
    *refresh = PDL_GetJSParamInt(params, 0);

    /* since we don't process this in the method thread, instead post a
     * SDL event that will be received in the main thread and used to 
     * launch the code. */
    SDL_Event event;
    event.user.type = SDL_USEREVENT;
    event.user.code = GET_CARTRIDGES;
    event.user.data1 = refresh;
    
    syslog(LOG_WARNING, "*** sending getCartridges event");
    SDL_PushEvent(&event);
    
    return PDL_TRUE;
}

static void setup()
{
    int result = SDL_Init(SDL_INIT_VIDEO);
    if ( result != 0 ) {
        printf("Could not init SDL: %s\n", SDL_GetError());
        exit(1);
    }
	atexit(SDL_Quit);
    
    PDL_Init(0);
    atexit(PDL_Quit);

    /*PDL_Err err;
    char appPath[256];
    err = PDL_GetCallingPath(appPath, sizeof(appPath));
    if (err) EXIT(1);
    chdir(appPath);*/

	/*if (!PDL_IsPlugin()) {
		cerr << "call from cmd" << endl;
        //RunCommandLineTests(argc, argv);
        exit(0);
    }*/
    
	PDL_RegisterJSHandler("getMetadata", getMetadata);
    PDL_RegisterJSHandler("getCartridges", getCartridges);
    PDL_JSRegistrationComplete();

	// call a "ready" callback to let JavaScript know that we're initialized
    PDL_CallJS("ready", NULL, 0);
    syslog(LOG_INFO, "**** Registered");


    /*SDL_EnableUNICODE(1);
    keyString = strdup("");

    gScreen = SDL_SetVideoMode(0, 0, 0, 0);
    
    
    SDL_Surface *logoImage = IMG_Load("logo.png");
    if (!logoImage) EXIT(1);
    gLogo = SDL_DisplayFormat(logoImage);
    if (!gLogo) EXIT(1);
    SDL_FreeSurface(logoImage);
    atexit(freeLogo);

    
    TTF_Init();
    atexit(TTF_Quit);

    gFont = TTF_OpenFont(PRELUDE_FONT_PATH, 20);
    if (!gFont) EXIT(1);
    atexit(freeFont);
    */
    //openlog("com.dta3team.app.simplepdk", 0, LOG_USER);
}

bool gKeyboardVisible = false;

static bool OutputMetadata(stringstream *buf, const char *cartridge, bool first = true){
	string filename( DATA_DIR );
	filename.append(cartridge);
	Wherigo *w = new Wherigo(filename);
	if( w->setup() == EXIT_FAILURE ){
		delete w;
		return false;		
	}
	w->createTmp();
	w->createFiles();
	
	if (!first) {
		*buf << ",\n";
	}
	
	*buf << "{\n"
		<< "\"filename\": \"" << escapeJsonString(string(cartridge)) << "\""
		<< ",\"iconID\": \"" << w->iconID << "\""
		<< ",\"type\": \"" << w->type << "\""
		<< ",\"name\": \"" << escapeJsonString(w->cartridgeName) << "\""
		<< ",\"guid\": \"" << w->cartridgeGUID << "\""
		<< ",\"description\": \"" << escapeJsonString(w->cartridgeDescription) << "\""
		<< ",\"startingLocationDescription\": \"" << escapeJsonString(w->startingLocationDescription) << "\""
		<< ",\"version\": \"" << w->version << "\""
		<< ",\"author\": \"" << escapeJsonString(w->author) << "\""
		<< "\n}";
	if( w->iconID > 0 ){ 
		ostringstream sfile;
		sfile << w->getTmp()
			<< "/" << w->iconID;
		ifstream sf (sfile.str().c_str(), ifstream::binary );
		string dfile(CONF_DIR);
		dfile.append(w->cartridgeGUID);
		dfile.append("_icon.png");
		ofstream df (dfile.c_str(), ifstream::binary | ifstream::trunc);
		df << sf.rdbuf();
	}
	delete w;
	return true;
}

/*static void OutputMetadataToJS(const char *cartridge)
{
    stringstream *buffer = new stringstream(stringstream::in | stringstream::out);
    *buffer << "{"
		<< "\"type\":\"ok\","
		<< "\"data\":[";
	
    if( OutputMetadata(buffer, cartridge, true) == false ){
		buffer->str("");
		*buffer << "{"
			<< "\"type\":\"error\","
			<< "\"message\":\"Error - unable to open cartridge " << cartridge << "\""
			<< "}";
		return;
	}
	*buffer << "]}";
	
	const char *data = buffer->str().c_str();
	
    // send data back to the JavaScript side
    syslog(LOG_WARNING, "*** returning results");
    PDL_Err err;
    err = PDL_CallJS("getMetadataResult", (const char **)&data, 1);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
    
    // now that we're done, free our working memory
    //delete data;
    delete buffer;
}*/

static void OutputCartridges(stringstream *buf, int *refresh){
	string filename( DATA_DIR );
	filename.append( CONFIG_FILE );
	ifstream file(filename.c_str(), ifstream::in | ifstream::binary);
	
	if( (*refresh == 1) || (!file.is_open()) ){
		// obnov ...
		glob_t matches;
		string pattern = string(DATA_DIR).append("*.gwc");
		size_t offset = DATA_DIR.length();
		*buf << "{\"type\": \"ok\", \"data\": [\n";
		if (0 == glob(pattern.c_str(), GLOB_BRACE, NULL, &matches)) {
			bool first = true;
			for (size_t i = 0; i < matches.gl_pathc; ++i) {
				string name = string(matches.gl_pathv[i]);
				struct stat details;
				if (0 != stat(name.c_str(), &details)) {
					// if we can't get file details, go to next one
					continue;
				}

				// output a file entry for regular files
				if (S_ISREG(details.st_mode)) {
					// output comma separators before all but the first filename
					if( OutputMetadata(buf, (name.substr(offset).c_str()), first) == false){
						continue;
					}
					first = false;
					
				}
			}
		}
	    *buf << "]}";
		
		globfree(&matches);
	    
		file.close();
		ofstream f(filename.c_str());
		f << buf->str();
		f.close();
		return;
	}
	
	/*while (file.good()){
		*buf << (char) file.get();
	}*/
	*buf << file.rdbuf();
	file.close();
	return;
}

static void OutputCartridgesToJS(int *refresh)
{
    stringstream *buffer = new stringstream(stringstream::in | stringstream::out);
	OutputCartridges(buffer, refresh);
	
	string str = buffer->str();	
	const char * data = str.c_str();
	//strcpy(data, str.c_str());
	
    // send data back to the JavaScript side
    syslog(LOG_WARNING, "*** returning results");
    PDL_Err err;
    err = PDL_CallJS("getCartridgesResult", (const char **)&data, 1);
    if (err) {
        syslog(LOG_ERR, "*** PDL_CallJS failed, %s", PDL_GetError());
        //SDL_Delay(5);
    }
    
    // now that we're done, free our working memory
    delete buffer;
}

static void loop(){

	SDL_Event event;
    if (SDL_WaitEvent(&event)) {
        if (event.type == SDL_QUIT)
            exit(0);
        else if (event.type == SDL_MOUSEBUTTONDOWN) {
           if (PDL_GetPDKVersion() >= 300) {
                gKeyboardVisible = !gKeyboardVisible;
                PDL_SetKeyboardState(gKeyboardVisible ? PDL_TRUE : PDL_FALSE);
           }
        } else if (event.type == SDL_USEREVENT) {
            syslog(LOG_WARNING, "*** processing * event");
            switch( event.user.code ){
				/*case GET_METADATA:
					// extract our arguments
					char *cartridge = (char *)event.user.data1;
					
					// call our output function
					OutputMetadataToJS(cartridge);

					// free memory since this event is processed now
					free(cartridge);
					break;*/
				case GET_CARTRIDGES:
					int *refresh = (int *)event.user.data1;
					OutputCartridgesToJS(refresh);
					delete refresh;
					break;
			}
        }
    }
}



static void exit_lua(){
    lua_close(L);
}

class ZObject {

};

class Player: ZObject {

};

class ZCartridge: ZObject {
	
	/*bool lua_register(){
		Lunar<ZCartridge>::RegType ZCartridge::methods[] = {
			LUNAR_DECLARE_METHOD(ZCartridge, deposit),
	}*/

};

//const char ZCartridge::className[] = "ZCartrige";


struct Smain {
  int argc;
  char **argv;
  int status;
};

int pmain (lua_State *L) {
	string *file = (string*) lua_touserdata(L, 1);
	lua_gc(L, LUA_GCSTOP, 0);  /* stop collector during initialization */
	luaL_openlibs(L);  /* open libraries */
	lua_gc(L, LUA_GCRESTART, 0);
	
	int status = handle_luainit (L);
	if (status != 0) return 0;

	status = luaL_loadfile(L, file->c_str());
	if (status == 0)
		status = docall(L, 0, 0);
	return report(L, status);
}

static int messageBox(lua_State *L) {
	const char *text = lua_tostring(L, 1);  /* get argument */
	cerr << "Message:" << text << endl;
	return 0;  /* number of results */
}

int main (int argc, char **argv) {
	// SDL setup and graphics display
  setup();
  my_error("*** MAIN Setup");
 
  
  // new Lua state
  int status;
  L = lua_open();  /* create state */
  if (L == NULL) {
    l_message(argv[0], "cannot create state: not enough memory");
    return EXIT_FAILURE;
  }
  luaL_openlibs(L);
  
  atexit( exit_lua );
  my_error("*** MAIN LUA");
 
  // load file
  /*Wherigo *w = new Wherigo("wherigo.lua.gwc");
  w->setup();

  w->createTmp();
  
  lua_register(L, "messageBox", messageBox);
  status = luaL_dostring(L, "package.loaded['Wherigo'] = 1 \
Wherigo = {}\
function Wherigo.MessageBox(text)\
	messageBox(text) \
	end\
Wherigo.ZCartridge = { }\
function Wherigo.ZCartridge.new()\
	local self = {}\
	self.Name = 'Old name'\
	self._mediacount = -1\
	self._store = true\
	return self\
	end \
setmetatable(Wherigo.ZCartridge, {\
	__call = Wherigo.ZCartridge.new\
	}) \
Wherigo.INVALID_ZONEPOINT = 0 \
Wherigo.Distance = 0 \
Wherigo.Player = 0 \
Wherigo.ZonePoint = {} \
function Wherigo.ZonePoint.new(lat, lon, alt)\
	local self = {}\
	local latitude = lat\
	local longitude = lat\
	local altitude = lat\
	return self\
	end \
\
function Wherigo.ZObject.new( cartridge ) --[[ , container = null ]]\
	local self = {}\
	self.Cartridge = cartridge\
	if not cartridge then\
		--[[ assert ]]\
		self.ObjIndex = -1\
		return self\
		end\
	if cartridge._store then\
		--[[ add to cartridge.AllZObjects ]]\
		end\
	return self\
	end\
\
function Wherigo.ZonePoint.new()\
	return Wherigo.ZonePoint.__init( Wherigo.ZObject.new( cartridge ), cartridge )\
	end\
function Wherigo.ZonePoint.__init( self, cartridge )\
	_id = cartridge._mediacount\
	if cartridge._mediacount > 0 then\
		cartridge._mediacount++\
		end\
	return self\
	end\
");
  report(L, status);

  string *bytecode = new string( w->getTmp() );
  bytecode->append("/wg.lua");
  status = lua_cpcall(L, &pmain, bytecode);
  report(L, status);
  status = !status && luaL_dostring(L, "cart = cart.OnStart() debug.debug() ");
  
  delete bytecode;*/
  /* call 'pmain' in protected mode */
  /*s.argc = 2;
  char *arg[] = {"prg", strdup(bytecode->c_str()) };
  s.argv = arg;
  status = lua_cpcall(L, &pmain, &s);*/
  //return (result && status == LUA_OK) ? EXIT_SUCCESS : EXIT_FAILURE;
  
  my_error("Everything ok");

  // alive UI
  while (1) {
    loop();
  }
}
