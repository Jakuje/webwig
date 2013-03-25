/* ========================================================================== */
/*                                                                            */
/*   WherigoLib.hpp                                                           */
/*   (c) 2013 Jakuje                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */
#ifndef WHERIGO_LIB_HPP
#define WHERIGO_LIB_HPP

#include "lua_common.h"

#include <string>
#include <map>
#include "wherigo.h"
#include <SDL.h>

namespace WherigoLib
{
	/*static void GetInput(const char *type, const char *text, const char* choices, const char* media);
	static void MessageBox(const char *text, const char *media,
		const char *button1, const char *button2, const char *callback);
	static void ShowScreenLua(const char *screen, const char *detail);
	static long addTimer(int remaining, int ObjId);
	static void exit_lua();
	static long getTime();
	static bool removeTimer(int ObjId);
	static void saveState();
	static void PlayAudio(const char *media);*/
	
	/** To test Lua stack after modification "by hand" */
	extern void stackdump_g(lua_State* l);
	
	/** Running timers and their connection to game */
	extern map<int,SDL_TimerID> timers;
	extern map<int,int*> timers_ids;

	/** Env variables*/
	extern std::string DEVICE;
	extern std::string DIR;
	extern std::string VERSION;
	extern std::string SLASH;
	extern int TIME;

	/** Lua state with running game*/
	extern lua_State *L;

	/** Currently opened Wherigo game in running engine	*/
	extern Wherigo *WherigoOpen;

	/** Variables to store showscreen, until UI is updated */
	extern char *show_detail;
	extern char *show_screen;

	/** Cached last position to logfile and others */
	extern double latitude, longitude, altitude, accuracy;
	
	extern std::string escapeJsonString(const std::string& input);
	
	extern void log(std::string message);

	extern void MessageBoxResponse(const char *value);
	extern void GetInputResponse(const char *value);
	extern void CallbackFunction(const char *event, int * id);
	extern void timerTick(int *ObjId);
	
	extern void OnStartEvent();
		
	extern int openCartridge(char *filename);
	extern void closeCartridge(int * save);
	
	extern lua_State * openLua(Wherigo *w);
	
	extern bool sync();
	
	extern std::string getUI();
	
	extern bool updateLocation(double *lat, double *lon, double *alt, double *accuracy);
	
}

#endif

