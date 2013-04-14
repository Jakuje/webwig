/* ========================================================================== */
/*                                                                            */
/*   Wherigo.h                                                                */
/*   (c) 2012 Jakuje                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */
#ifndef WHERIGO_H
#define WHERIGO_H 1

#include <cstdlib>
#include <string>
#include <cstring>
#include <sys/stat.h>
#include <sys/types.h>
#include "filereader.h"
#include <ctime>
#include <cstdlib>

#ifndef DESKTOP
const string DATA_DIR = "/media/internal/appdata/com.dta3team.app.wherigo/";
#else
const string DATA_DIR = "data/";
#endif

const string CONF_DIR = DATA_DIR;
const string CONFIG_FILE = "database.json";

using namespace std;

void my_error(string message);

class Wherigo {
	enum FileTypes { UNDEFINED = -1, BMP = 1, PNG = 2, JPG = 3, GIF = 4, WAV = 17, MP3 = 18, FDL = 19};
public:
	string filename;
	fileReader fd;
	string cartDir;

	int *ids; 
	int *idsRev;
	long *offsets;
	int *types;
	int files;

	double lat;
	double lon;
	double alt;

	int splashID;
	int iconID;

	string type;
	string player;

	string cartridgeName;
	string cartridgeGUID;
	string cartridgeDescription;
	string startingLocationDescription;
	string version;
	string author;
	string company;
	string recomandedDevice;
	
	string completionCode;

	ofstream logFile;

	Wherigo( string filename ){
		this->filename = filename;
		this->ids = NULL;
		this->idsRev = NULL;
		this->types = NULL;
		this->offsets = NULL;
		files = 0;
	}

	~Wherigo(){
		if( ids != NULL ){
			delete [] ids;
		}
		if( idsRev != NULL ){
			delete [] idsRev;
		}
		if( types != NULL ){
			delete [] types;
		}
		if( offsets != NULL ){
			delete [] offsets;
		}
		fd.close();
	}

	bool setup();

	bool scanHead ();

	int scanOffsets ();

	bool scanHeader ();

	string getCartDir();

	bool createBytecode();

	bool createFileById(int id);
	
	bool createFile(int i);
	
	bool createFiles();

	string *getFilePathById(int i);
	string *getFilePathById(const char *str_i);
	string *getFilePath(int i);
	
	bool cleanFiles();

	void openLog();
	void log(string message);
	void closeLog();

	string getSaveFilename();
};

#endif

