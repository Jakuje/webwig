/* ========================================================================== */
/*                                                                            */
/*   Wherigo.h                                                                */
/*   (c) 2012 Jakuje                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */
#include <cstdlib>
#include <string>
#include <cstring>
#include <sys/stat.h>
#include <sys/types.h>
#include "filereader.h"

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

	Wherigo( string filename ){
		this->filename = filename;
		this->ids = NULL;
		this->types = NULL;
		this->offsets = NULL;
		files = 0;
	}

	~Wherigo(){
		if( ids != NULL ){
			delete [] ids;
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

	//bool createIcons();
	
	bool createFileById(int id, string path);
	
	bool createFile(int i);
	bool createFile(int i, string path);
	
	bool createFiles();

	string getFilePathById(int i);
	string getFilePath(int i);
	string getFilePath(const char *str_i);
	string getFilePath(int i, string name);
	//int createTmp();

};

