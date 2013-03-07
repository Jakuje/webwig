/* ========================================================================== */
/*                                                                            */
/*   Wherigo.cpp                                                              */
/*   (c) 2012 Jakuje                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */

#include "wherigo.h"
#include <syslog.h>
#include <execinfo.h>

void my_error(string message){
	//fprintf(stderr, "%s", message);
	cerr << message << endl;
	syslog(LOG_WARNING, message.c_str());
}

void print_backtrace(void){

       void *tracePtrs[10];
       size_t count;

       count = backtrace(tracePtrs, 10);

       char** funcNames = backtrace_symbols(tracePtrs, count);

       for (int i = 0; i < count; i++)
           syslog(LOG_INFO,"%s\n", funcNames[i]);

       free(funcNames);

}


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
	
	ids = new int[files];
	types = new int[files];
	offsets = new long[files];
	
	for(int i = 0;i < files; i++){
		ids[i] = fd.readUShort();
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
	
	type = fd.readASCIIZ();
	player = fd.readASCIIZ();
	
	fd.readLong();
	fd.readLong();// unknown values
	
	cartridgeName = fd.readASCIIZ();
	cartridgeGUID = fd.readASCIIZ();
	cartridgeDescription = fd.readASCIIZ();
	startingLocationDescription = fd.readASCIIZ();
	version = fd.readASCIIZ();
	author = fd.readASCIIZ();
	company = fd.readASCIIZ();
	recomandedDevice = fd.readASCIIZ();
	
	fd.readLong(); // unknown

	completionCode = fd.readASCIIZ();
	
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

/*bool Wherigo::createIcons(){
	bool ok = this->createFileById(this->iconID, "icon");
	ok = this->createFileById(this->splashID, "splash") && ok;
	return ok;
}*/

/**
 * Creates file by global ID
 */
bool Wherigo::createFileById(int id, string name){
	for(int i = 1;i < files; i++){ // 0 is cartridge
		if( ids[i] == id ){
			this->createFile(i, name);
			return true;
		}
	}
	return false;
}

/**
 * Creates file by internal index
 */
bool Wherigo::createFile(int i){
	stringstream ss;
	ss << i;
	return createFile(i, ss.str());
}
bool Wherigo::createFile(int i, string name){
	
	if( i < files && i > 0 ){
		fd.seekg( offsets[i] );
		if( fd.readByte() == 0 ){
			return false;
		}
		types[i] = fd.readLong(); // use to export to Javascript
		string path = getFilePath(i, name);
		//my_error(string("*** Wherigo.cpp *** Creating File: ").append(path));
		int len = fd.readLong();
		char *data = new char [len];
		fd.read(data, len);
		
		ofstream f( path.c_str(), ios_base::out | ios_base::binary);
		f.write(data, len);
		f.close();
		delete [] data;
		return true;
	} else {
		print_backtrace();
		return false;
	}
}

string Wherigo::getFilePathById(int id){
	for(int i = 1;i < files; i++){ // 0 is cartridge
		if( ids[i] == id ){
			return this->getFilePath(i);
		}
	}
	return "";
}
string Wherigo::getFilePath(int i){
	stringstream ss;
	ss << i;
	return getFilePath(i, ss.str());
}
string Wherigo::getFilePath(const char *str_i){
	stringstream ss;
	ss << str_i;
	int i;
	ss >> i;
	return getFilePath(i, str_i);
}
string Wherigo::getFilePath(int i, string name){
	if( i < files && i > 0 ){
		if( types[i] == UNDEFINED ){
			createFile(i);
		}
		string path = this->getCartDir().append(name);
		switch (types[i]){
			case BMP:
				path = path.append(".bmp");
				break;
			case PNG:
				path = path.append(".png");
				break;
			case JPG:
				path = path.append(".jpg");
				break;
			case GIF:
				path = path.append(".gif");
				break;
			case WAV:
				path = path.append(".wav");
				break;
			case MP3:
				path = path.append(".mp3");
				break;
			case FDL:
				path = path.append(".fdl");
				break;
			default:
				// log missing file extension ... and learn it ...
				stringstream message;
				message << "Unknown file type ID: " << types[i];
				my_error(message.str());
				break;
		}
		return path;
	} else {
		my_error(string("Unknown file (id out of bounds)").append(name));
		return "";
	}
}

bool Wherigo::createFiles(){
	ostringstream str;
	//string path = this.getCartDir();
	for(int i = 1;i < files; i++){
		str.str("");
		str << ids[i];
		createFile(i);
	}
	return true;
}

string Wherigo::getCartDir(){
	if( cartDir.empty() ){
		cartDir = string(DATA_DIR);
		cartDir.append( cartridgeGUID ).append("/");
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
			} else {
				/*createBytecode();
				createFiles();*/
			}
		}
	}
	return cartDir;
}
/*int Wherigo::createTmp(){
	tmpdir = strdup("/tmp/wig.lua.XXXXXX");
	tmpdir = mkdtemp(tmpdir);
	if( tmpdir == NULL ){
		my_error("Failed to init tmp dir");
		return EXIT_FAILURE;
	}
	string file_bytecode = string(tmpdir);
	file_bytecode.append("/wg.lua");
	this->createBytecode(file_bytecode);
	this->createFiles( );
	return EXIT_SUCCESS;
}*/
