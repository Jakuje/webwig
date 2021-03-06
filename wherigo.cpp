/* ========================================================================== */
/*                                                                            */
/*   Wherigo.cpp                                                              */
/*   (c) 2012 Jakuje                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */

#include "wherigo.h"
#include "WherigoLib.hpp"
#include <syslog.h>
//#include <execinfo.h>
#include <glob.h>

//Wherigo *WherigoOpen;

void my_error(string message){
	//fprintf(stderr, "%s", message);
	cerr << message << endl;
	syslog(LOG_WARNING, "%s", message.c_str());
	if(WherigoLib::WherigoOpen != NULL){
		WherigoLib::WherigoOpen->log(message);
	}
}

/*void print_backtrace(void){

       void *tracePtrs[10];
       size_t count;

       count = backtrace(tracePtrs, 10);

       char** funcNames = backtrace_symbols(tracePtrs, count);

       for (int i = 0; i < count; i++)
           syslog(LOG_INFO,"%s\n", funcNames[i]);

       free(funcNames);

}*/


bool Wherigo::setup(){
	fd.open( filename.c_str(), ios::in | ios::binary);
	if( ! fd.is_open() ){
		my_error("Error opening GWC file!!");
		return false;
	}
	
	if( ! scanHead() ){
		my_error("Wrong file - problem with GWC head");
		return false;
	}

	files = scanOffsets();
	if( files == 0 ){
		my_error("Wrong file - problem with offsets and ids");
		return false;
	}

	if( ! scanHeader() ){
		my_error("Wrong file - problem with GWC header");
		return false;
	}
	
	//getCartDir();
	
	return true;
  
}

/**
 * Scan newly opened file (without offset) for head
 * inspiration in specs at WherUGo: 
 * http://code.google.com/p/wherugo/wiki/GWC
 */ 
bool Wherigo::scanHead (){
	unsigned char CART_ID[] = { 0x02, 0x0a, 0x43, 0x41, 0x52, 0x54, 0x00 };
						// 02 0a CART 00
	int size = sizeof(CART_ID);
	char *data = new char [size];
	fd.read(data, size);
	int i = 0;
	while(i < size ){
		if( CART_ID[i] != data[i] ){
			stringstream t;
			t << i << ": " << CART_ID[i] << "_" << data[i];
			my_error( t.str() );
			delete [] data;
			return false;
		}
		i++;
	}
	delete [] data;
	return true;   
}

/**
 * Scan file for offsets for every bytecode
 */ 
int Wherigo::scanOffsets (){
	files = fd.readUShort();
	
	if(  files > 0 ){
		idsRev = new int[files];
		ids = new int[files];
		types = new int[files];
		offsets = new long[files];
	}
	
	for(int i = 0;i < files; i++){
		ids[i] = fd.readUShort();
		if( ids[i] < files ){ // sometimes there is larger index and I can't handle it
			idsRev[ ids[i] ] = i;
			// sometimes it is not in correct order and we need to aceess some ID
		}
		//cerr << i << ":" << ids[i] << endl;
		offsets[i] = fd.readLong();
		types[i] = UNDEFINED;
	}
	return files;
}

/**
 * Scan file for offsets for every bytecode
 * for now throw data away 
 */ 
bool Wherigo::scanHeader (){
	
	/*int len = */fd.readLong(); // header length
	
	lat = fd.readDouble(); // latitude
	lon = fd.readDouble(); // longitude

	// altitude (by https://github.com/wijnen/python-wherigo/blob/master/wherigo.py)
	alt = fd.readDouble(); 
	
	fd.readLong();
	fd.readLong();// unknown values

	splashID = fd.readShort();
	iconID = fd.readShort();
	
	fd.readASCIIZ(&type);
	fd.readASCIIZ(&player);
	
	fd.readLong();
	fd.readLong();// unknown values
	
	fd.readASCIIZ(&cartridgeName);
	fd.readASCIIZ(&cartridgeGUID);
	fd.readASCIIZ(&cartridgeDescription);
	fd.readASCIIZ(&startingLocationDescription);
	fd.readASCIIZ(&version);
	fd.readASCIIZ(&author);
	fd.readASCIIZ(&company);
	fd.readASCIIZ(&recomandedDevice);
	
	fd.readLong(); // unknown

	fd.readASCIIZ(&completionCode);
	
	return true;
}

bool Wherigo::createBytecode(){
	fd.seekg( offsets[0] );
	int len = fd.readLong();
	char *lua = new char [len];
	fd.read(lua, len);
	
	ofstream f( getCartDir().append("wig.luac").c_str(), ios_base::out | ios_base::binary);
	f.write(lua, len);
	f.close();
	delete [] lua;
  
	return true;
}

/**
 * Creates file by global ID
 */
bool Wherigo::createFileById(int id){
	if( id < files ){
		return this->createFile(idsRev[id]);
	} else {
		for(int i = 1;i < files; i++){
			if( ids[i] == id ){
				return this->createFile(i);
			}
		}
	}
	return false;
}

/**
 * Creates file by internal index
 */
bool Wherigo::createFile(int i){
	if( i < files && i > 0 ){
		fd.seekg( offsets[i] );
		if( fd.readByte() == 0 ){
			return false;
			//my_error("File with ZERO flag generated");
		}
		types[i] = fd.readLong(); // use to export to Javascript
		string *path = getFilePath(i);
		string fp = this->getCartDir();
		fp.append(*path);
		//my_error(string("*** Wherigo.cpp *** Creating File: ").append(path));
		int len = fd.readLong();
		char *data = new char [len];
		fd.read(data, len);
		
		ofstream f( fp.c_str(), ios_base::out | ios_base::binary);
		f.write(data, len);
		f.close();
		delete [] data;
		delete path;
		return true;
	} else {
		//print_backtrace();
		return false;
	}
}

string *Wherigo::getFilePathById(int id){
	if( id > 0 && id < files ){
		// -1 means no file for icon/splash
		// 0 is cartridge
		return this->getFilePath(idsRev[id]);
	} else if( id >= files ){
		// file exists, but is not in idsRev array (out of bounds)
		for(int i = 1;i < files; i++){
			if( ids[i] == id ){
				return this->getFilePath(i);
			}
		}
	}
	return new string("");
}
string *Wherigo::getFilePathById(const char *str_i){
	stringstream ss;
	ss << str_i;
	int i;
	ss >> i;
	return getFilePathById(i);
}
string *Wherigo::getFilePath(int i){
	stringstream ss;
	ss << ids[i];
	if( i < files && i > 0 ){
		if( types[i] == UNDEFINED ){
			createFile(i);
		}
		string *path = new string(/*this->getCartDir()*/);
		path->append(ss.str());
		switch (types[i]){
			case BMP:
				path->append(".bmp");
				break;
			case PNG:
				path->append(".png");
				break;
			case JPG:
				path->append(".jpg");
				break;
			case GIF:
				path->append(".gif");
				break;
			case WAV:
				path->append(".wav");
				break;
			case MP3:
				path->append(".mp3");
				break;
			case FDL:
				path->append(".fdl");
				break;
			default:
				// log missing file extension ... and learn it ...
				stringstream message;
				message << "Unknown file type ID: " << types[i] << ", file ID: " << i;
				my_error(message.str());
				delete path;
				return new string("");
				break;
		}
		return path;
	} else {
		my_error(string("Unknown file (id out of bounds)").append(ss.str()));
		return new string("");
	}
}

bool Wherigo::createFiles(){
	ostringstream str;
	for(int i = 1;i < files; i++){
		createFile(i);
	}
	return true;
}

string Wherigo::getCartDir(){
	if( cartDir.empty() ){
		cartDir = string(DATA_DIR);
		cartDir.append(".").append( cartridgeGUID ).append("/");
		struct stat st;
		bool is_dir = false;
		if(stat(cartDir.c_str(), &st) == 0){
			if( (st.st_mode & S_IFDIR) != 0){
				is_dir = true;
			}
		}
		if( !is_dir ){
			if( mkdir(cartDir.c_str(), 0777) != 0){
				my_error("Can't create directory");
				return "";
			}
		}
	}
	return cartDir;
}

void Wherigo::openLog(){
	int pos = filename.find(".gwc");
	string logFileName = filename.substr(0, pos).append(".gwl");
	logFile.open( logFileName.c_str(), ios_base::app );
	logFile << "-------------------" << endl
		<< "Engine WebWIG Alpha, Player: " << player << " Cartridge: " << cartridgeName << endl
		<< "-------------------" << endl;
}

void Wherigo::log(string message){
	cerr << message << endl;
	time_t t = time(NULL);
	tm *ltm = localtime(&t);
	char ts[15]; // 14 + \0
	strftime(ts, 15, "%Y%m%d%H%M%S", ltm);
	ts[14] = '\0';
	if( logFile.is_open() ){
		logFile << ts << "|" << WherigoLib::latitude << "|" << WherigoLib::longitude
			<< "|" << WherigoLib::altitude << "|" << WherigoLib::accuracy << "|" << message << endl;
	} else {
		cerr << ts << "|" << WherigoLib::latitude << "|" << WherigoLib::longitude
			<< "|" << WherigoLib::altitude << "|" << WherigoLib::accuracy << "|" << message << endl;
	}
}

void Wherigo::closeLog(){
	logFile.close();
}

string Wherigo::getSaveFilename(){
	string name = this->filename.substr(0, this->filename.length() - 1);
	name.append("s");
	return name;
}

bool Wherigo::cleanFiles(){
	setup();
	fd.close();
	
	bool ok = true;
	glob_t matches;
	string pattern;
	const char *name;
	
	// remove cartridge directory files
	//system( (string("rm -rf") + getCartDir()).c_str() );
	pattern = getCartDir() + "*";
	if (0 == glob(pattern.c_str(), GLOB_BRACE, NULL, &matches)) {
		for (size_t i = 0; i < matches.gl_pathc; ++i) {
			name = matches.gl_pathv[i];
			struct stat details;
			if (0 != stat(name, &details)) {
				// if we can't get file details, go to next one
				continue;
			}
			if (S_ISREG(details.st_mode)) {
				ok = (remove(name) == 0) && ok;
			}
		}
	}
	globfree(&matches);
	// delete dir itself (if previous deletion ok);
	ok = ok && (rmdir(getCartDir().c_str()) == 0);
	
	// remove cartridge and all other data with same name: gw* = gwc, gwl, gws
	//system( (string("rm -f") + this->filename.substr(0, this->filename.length() - 1) + "*").c_str() );
	pattern = this->filename.substr(0, this->filename.length() - 1) + "*";
	if (0 == glob(pattern.c_str(), GLOB_BRACE, NULL, &matches)) {
		for (size_t i = 0; i < matches.gl_pathc; ++i) {
			name = matches.gl_pathv[i];
			struct stat details;
			if (0 != stat(name, &details)) {
				// if we can't get file details, go to next one
				continue;
			}
			if (S_ISREG(details.st_mode)) {
				ok = ok && (remove(name) == 0);
			}
		}
	}
	globfree(&matches);

	return ok;
}


void Wherigo::setComplete( ){
	my_error("Set complete invoked");
	ofstream f( getCartDir().append("complete").c_str(), ios_base::out);
	f << "true" << endl;
	f.close();
}
