#include <string>
#include <cstdio>

#include <glob.h>
#include <sys/stat.h>
#include <syslog.h>


#include "wherigo.h"
#include "WherigoLib.hpp"
#include "Engine.hpp"

/**
 * Includes for PDK for webOS app
 */

#include <SDL.h>

#ifndef DESKTOP

#endif /* DESKTOP */

using namespace std;

//extern Wherigo *WherigoOpen;

#define EXIT(n) do { fprintf(stderr, "Early exit at %s:%d\n", __FILE__, __LINE__); exit(n); } while (0)

static bool runTests(char * filter){
	glob_t matches;
	int status;
	string pattern = string("tests/").append(filter).append("*");
	
	WherigoLib::WherigoOpen = new Wherigo("testname.gwc");
	
	if (0 == glob(pattern.c_str(), GLOB_BRACE, NULL, &matches)) {
		for (size_t i = 0; i < matches.gl_pathc; ++i) {
			string name = string(matches.gl_pathv[i]);
			struct stat details;
			if (0 != stat(name.c_str(), &details)) {
				// if we can't get file details, go to next one
				continue;
			}

			// output a file entry for regular files
			if (S_ISREG(details.st_mode)) {
				lua_State *L = WherigoLib::openLua(WherigoLib::WherigoOpen);
				if( L == NULL ){
					cerr << "Can't create lua state" << endl;
					return false;
				}
				// output comma separators before all but the first filename
				status = luaL_dofile(L, name.c_str());
				report(L, status);
				cerr << "Test " << name << ": " << (status == 0
#ifdef DESKTOP
					? "\033[1;32mOK\e[m"
					: "\033[1;31mERROR\e[m") << endl;
#else
					? "OK"
					: "ERROR") << endl;
#endif
			}
		}
	}
	delete WherigoLib::WherigoOpen;
	globfree(&matches);
	
	return true;
}



void CommandLineTests(int argc, char **argv){
	// OutputCartridges
	int *refresh = new int;
	*refresh = 1;
	Engine::OutputCartridgesToJS(refresh);
	delete refresh;
	
	char *file;
	if( argc > 1 && strcmp(argv[1], "test") == 0){
		if( argc == 3 ){
			runTests(argv[2]);
		} else {
			runTests("*.lua");
		}
		return;
	} else {
		if( argc > 1 ){
			file = argv[1];
		} else {
			file = (char *) "minimal.gwc";
		}
		
		if( ! Engine::openCartridgeToJS(file) ){
			return;
		}
		
		/*double lon, lat;
		lat = 49.223878820512;
		lon = 16.529799699783;
		Engine::setPosition(&lat, &lon);
		
		
		int i = 56;
		//CallbackFunction("OnClick", &i);
		WherigoLib::CallbackFunction( "OnStartGame", &i );
		WherigoLib::GetInputResponse( "Begin" );
		
		Engine::setPosition(&lat, &lon);*/
		
		//luaL_dostring(WherigoLib::L, "debug.debug()");
		
		//setPosition(&lat, &lon);
		/*int status = luaL_dostring(L, "return Wherigo._getUI()");
		report(L, status);
		cerr << "Lua result: " << lua_tostring(L, 1) << endl;*/
		//cerr << WherigoLib::getUI();
		//updateStateToJS();
		int *s = new int;
		*s = 1;
		Engine::closeCartridge(s);
		delete s;
	}
}



int main (int argc, char **argv) {
	
	Engine::setup(argc, argv);
#ifndef DESKTOP
	if (!PDL_IsPlugin()) {
#endif
		cerr << "call from cmd" << endl;
        CommandLineTests(argc, argv);
        exit(0);
#ifndef DESKTOP
    }
#endif

	// alive UI
	while (1) {
		Engine::loop();
	}
}
