#include "WherigoLib.Save.hpp"
#include "WherigoLib.Save.hpp"
#include "WherigoLib.hpp"

namespace WherigoLib {
	namespace Save {

/** GWS header */
unsigned char GWS_SIG[] = { 0x02, 0x0a, 0x53, 0x59, 0x4e, 0x43, 0x00 };

string dump_buffer;
long dump_length = 0;

using namespace std;

/** Lua_Writer called by lua_dump for functions */
int writeLuaDump(lua_State *L, const void * p, size_t sz, void * ud){
	dump_buffer.append( (const char *)p, sz);
	dump_length += sz;
	return 0;
}

void writeBoolField(fileWriter *sf, const char* field){
	lua_pushstring(L, field);				// [-0, +1, m]
	lua_gettable(L, -3);					// [-1, +1, e]
	if( lua_isnoneornil(L, -1) ){
		lua_pop(L, 1);						// [-1, +0, -]
		return;
	}
	
	sf->writeByte(0x03);
	sf->writeLong( strlen(field) );
	sf->writeASCII( field, strlen(field) );
	sf->writeByte(0x01);
	sf->writeByte( lua_toboolean(L, -1) );
	lua_pop(L, 1);							// [-1, +0, -]
}

void serialize_table(fileWriter *sf, bool all);

/** Requested stack state:
 *	-2	Table to traverse
 *  -1	Classname if it is known class
 */
void writeTable(fileWriter *sf, const char* field){
	lua_pushstring(L, field);				// [-0, +1, m]
	lua_gettable(L, -3);					// [-1, +1, e]
	if( lua_isnoneornil(L, -1) ){
		lua_pop(L, 1);						// [-1, +0, -]
		return;
	}
	sf->writeByte(0x03);
	sf->writeLong( strlen(field) );
	sf->writeASCII( field, strlen(field) );
	lua_getfield(L, -1, "_classname");		// [-0, +1, e]
	if( ! lua_isnoneornil(L, -1) ){
		sf->writeByte(0x08);
		const char *name = lua_tostring(L, -1);
		int size = lua_objlen(L, -1);
		sf->writeLong(size);
		sf->writeASCII(name, size);
	}
	serialize_table(sf, false);
	lua_pop(L, 2);							// [-2, +0, -]
}

	
/** Serialize table to file
 * Requested stack state:
 *	-2	Table to traverse
 *  -1	Classname if it is known class
 */
void serialize_table(fileWriter *sf, bool all){
	int i;
	size_t size;
	const char *name;
	bool skip;
	sf->writeByte(0x05); // start of table
	
	writeBoolField(sf, "Active");										// [-0, +0, -]
	writeBoolField(sf, "Complete");										// [-0, +0, -]
	writeBoolField(sf, "CorrectState");									// [-0, +0, -]
	writeBoolField(sf, "Enabled");										// [-0, +0, -]
	
	// todo maybe Visible ???
	// CommandsArray
	writeTable(sf, "CommandsArray");									// [-0, +0, -]
	writeTable(sf, "Inventory");										// [-0, +0, -]
	writeTable(sf, "ClosestPoint");									// [-0, +0, -]
	
	const char *classname;
	if( lua_isstring(L, -1) ){
		classname = lua_tostring(L, -1);
		cerr <<  " <<<<<< " << classname << " <<<<<< " << endl;
	} else {
		classname = "";
	}
	bool next_all;
	lua_pushnil(L);														// [-0, +1, -]
	while (lua_next(L, -3) != 0) {										// [-1, +(2|0), e]
		skip = false;
		for(i = -2; i <= -1; i++){
			if( skip ){
				break; // key was excludes, so don't include value
			}
			switch( lua_type(L, i) ){
				case LUA_TBOOLEAN:
					sf->writeByte(0x01);
					sf->writeByte( lua_toboolean(L, i) );
					break;
				case LUA_TNUMBER:
					sf->writeByte(0x02);
					sf->writeDouble( lua_tonumber(L, i) );
					name = "";
					break;
				case LUA_TSTRING:
					name = lua_tostring(L, i);
					// look at key if we want it save
					if( ! all && i == -2 && (
						name[0] == '_'
						|| ( strcmp(classname, "ZTimer") == 0 && (
							strcmp(name, "Start") == 0
							|| strcmp(name, "Stop") == 0
							|| strcmp(name, "Tick") == 0 ))
						|| ( strcmp(classname, "ZCartridge") == 0 && (
							strcmp(name, "RequestSync") == 0
							|| strcmp(name, "GetAllOfType") == 0
							|| strcmp(name, "CompletionCode") == 0
							|| string(name).compare(0, 4, "AllZ") == 0))
						|| ( strcmp(classname, "ZMedia") == 0 &&
							strcmp(name, "Resources") == 0
							)
						|| ( strcmp(classname, "Distance") == 0 &&
							strcmp(name, "GetValue") == 0
							)
						|| ( strcmp(classname, "ZCharacter") == 0 &&
							strcmp(name, "RefreshLocation") == 0
							)
						|| ( strcmp(classname, "Zone") == 0 &&
							strcmp(name, "Inside") == 0
							)
							|| strcmp(name, "ObjIndex") == 0 
							|| strcmp(name, "Cartridge") == 0 
							|| string(name).compare(0, 7, "Current") == 0
							|| strcmp(name, "Contains") == 0
							|| strcmp(name, "Commands") == 0 // ignored, because we store CommandsArray
							|| strcmp(name, "MoveTo") == 0
						) ){
						skip = true;
						break;
					}
					size = lua_objlen(L, i);
					sf->writeByte(0x03);
					sf->writeLong(size);
					sf->writeASCII(name, size);
					break;
				case LUA_TFUNCTION: // i should be -1
					if( i == -2 ){
						cerr << "Function can't be key!!!" << endl;
					}
					sf->writeByte(0x04);
					dump_length = 0;
					dump_buffer.clear();
					lua_dump(L, (lua_Writer)writeLuaDump, NULL);
					sf->writeLong(dump_length);
					sf->writeASCII(dump_buffer.c_str(), dump_length);
					break;
				case LUA_TTABLE: // i should be -1 => table as key is useless
					lua_getfield(L, i, "ObjIndex");						// [-0, +1, e]
					if( !lua_isnoneornil(L, -1) ){
						sf->writeByte(0x07); // Reference
						sf->writeUShort( lua_tointeger(L, -1) );
						lua_pop(L, 1);									// [-1, +0, e]
						break;
					}
					lua_pop(L, 1);										// [-1, +0, e]
					lua_getfield(L, i, "_classname");					// [-0, +1, e]
					if( ! lua_isnoneornil(L, -1) ){
						sf->writeByte(0x08); // Object
						name = lua_tostring(L, -1);
						size = lua_objlen(L, -1);
						sf->writeLong(size);
						sf->writeASCII(name, size);
						next_all = false;
					} else if( strcmp(name, "ZVariables") == 0 ){
						cerr << "ZVariables all" << endl;
						next_all = true;
					}
					serialize_table(sf, next_all); // Table
					lua_pop(L, 1);										// [-1, +0, e]
					break;
				default:
					sf->writeASCIIZ("UNKNOWN", 7);
					cerr << "Unknown data to serialize" << lua_typename(L, lua_type(L, -2)) << endl;
			}
		}
		lua_pop(L, 1);								// [-1, +0, -]
	}
	sf->writeByte(0x06);
	
}

/** Save Game */
bool sync(){
	WherigoOpen->log("ZCartridge:Sync");
	
	string save_filename = WherigoOpen->getSaveFilename();
	fileWriter sf;
	sf.open(save_filename.c_str() , ios::out | ios::binary);
	
	sf.writeASCII( (char *) &GWS_SIG, 7 );
	long header_length = WherigoOpen->cartridgeName.length()+1 + 8 +
		WherigoOpen->player.length()+1 + WherigoOpen->recomandedDevice.length()+1 +
		5+1 + 8 + 17+1 + 8 + 8 + 8;
	sf.writeLong(header_length);
	sf.writeASCIIZ( WherigoOpen->cartridgeName.c_str(), WherigoOpen->cartridgeName.length() );
	sf.writeLong( 0 ); // date of creation 8 byte ???
	sf.writeLong( 0 );
	sf.writeASCIIZ( WherigoOpen->player.c_str(), WherigoOpen->player.length() );
	sf.writeASCIIZ( "WebOS", 5 ); // device
	sf.writeASCIIZ( "WebOS", 5 ); // device ID
	sf.writeLong( 0 ); // date of save 8 byte
	sf.writeLong( 0 );
	sf.writeASCIIZ( "UI initiated sync", 17 ); // Name of save
	sf.writeDouble( WherigoLib::latitude );
	sf.writeDouble( WherigoLib::longitude );
	sf.writeDouble( WherigoLib::altitude );
	
	// store ZVariables from global namespace
	lua_getfield(L, LUA_GLOBALSINDEX, "cartridge");						// [-0, +1, e]
	lua_getfield(L, -1, "ZVariables");									// [-0, +1, e]
	if( ! lua_isnoneornil(L, -1) ){
		lua_pushnil(L);													// [-0, +1, m]
		while( lua_next(L, -2) != 0 ){									// [-1, +(2|0), e]
			lua_pop(L, 1);												// [-1, +0, -]
			lua_pushvalue(L, -1);										// [-0, +1, m]
			lua_getfield(L, LUA_GLOBALSINDEX, lua_tostring(L, -1) );	// [-0, +1, e]
			lua_settable(L, -4);										// [-2, +0, e]
		}
	}
	lua_pop(L, 1);
	
	
	lua_getfield(L, -1, "AllZObjects");									// [-0, +1, e]
	lua_remove(L, -2);													// [-1, +0, -]
	size_t size;
	const char *name;
	
	int allz = lua_objlen(L, -1);
	sf.writeLong( allz+1 ); // num of ZObjects ???
	
	// write types of AllZObjects
	lua_pushnil(L);														// [-0, +1, -]
	while (lua_next(L, -2) != 0) {										// [-1, +(2|0), e]
		if( lua_tointeger(L, -2) == 0 ) { // do not write cartridge object?
			lua_pop(L,1);
			continue;
		}
		/*printf("%s - %s\n",
			lua_typename(L, lua_type(L, -2)),
			lua_typename(L, lua_type(L, -1)));*/
		lua_getfield(L, -1, "_classname");			// [-0, +1, e]
		
		name = lua_tostring(L, -1);
		size = lua_objlen(L, -1);
		sf.writeLong( size );
		sf.writeASCII( name, size );
		lua_pop(L, 2);								// [-2, +0, -]
	}
	// do not remove cartridge. It will be traversed once again to write out details
	
	// dump Player object
	sf.writeLong(10);
	sf.writeASCII("ZCharacter", 10);
	lua_getfield(L, LUA_GLOBALSINDEX, "Wherigo");	// [-0, +1, e]
	lua_getfield(L, -1, "Player");					// [-0, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	lua_getfield(L, -1, "_classname");				// [-0, +1, e]
	
	serialize_table(&sf, false);
	lua_pop(L, 2);									// [-2, +0, -]
	
	// write details of AllZObjects
	
	for( int i = 0; i <= allz; i++){
		lua_pushnumber(L, i);
		lua_gettable(L, -2);
	//lua_pushnil(L);
	//while (lua_next(L, -2) != 0) {					// [-1, +(2|0), e]
		lua_getfield(L, -1, "_classname");			// [-0, +1, e]
		
		name = lua_tostring(L, -1);
		size = lua_objlen(L, -1);
		sf.writeLong( size );
		sf.writeASCII( name, size );

		serialize_table(&sf, false);
		
		lua_pop(L, 2);								// [-2, +0, -]
	}
	lua_pop(L, 1);									// [-1, +0, -]
	
	stackdump_g(L); // check if is empty at the end
	
	sf.close();
	return true;
}


/** num objects in restore */
int num_objects;

bool read_object(fileReader *fd, string name, bool create_objects);

/**
 * Read from open GWS file table
 * Expected stack state before call:
 *  -3	table
 *  -2	key of table
 *  -1	value at key in table
 * 
 * Before function return, last two values on stack will be removed
 */
bool read_table(fileReader *fd, bool set_field = false){				// [-2, +0, e]
	int code = fd->readByte();
	if(code != 0x05){ // start table
		cerr << "Expected 0x05 as start of table, got " << code << endl;
		return false;
	}
	
	if( ! set_field  && ! lua_istable(L, -1) ){
		lua_pop(L, 1);													// [-1, +0, -]
		lua_newtable(L);												// [-0, +1, m]
		set_field = true;
	}
	
	bool key = true;
	int status, len;
	string text, key_value;
	double number;
	while( (code = fd->readByte()) != 0x06 ){ // end table
		switch(code){
			case 0x01: // boolean
				if( key ){
					cerr << "Boolean can't be key" << endl;
					return false;
				} else {
					len = fd->readByte();
					lua_pushboolean(L, len);							// [-0, +1, -]
					lua_settable(L, -3);								// [-2, +0, e]
					//cerr << "      -======= " << key_value << " = " << len << " (" << (bool)len << ") =======- " << endl;
				}
				break;
			case 0x02: // number
				number = fd->readDouble();
				if( key ){
					lua_pushnumber(L, number);							// [-0, +1, -]
				} else {
					//cerr << "      -======= " << key_value << " =======- " << endl;
					lua_pushnumber(L, number);							// [-0, +1, -]
					lua_settable(L, -3);								// [-2, +0, e]
				}
				break;
			case 0x03: // string
				len = fd->readLong();
				fd->readASCII(&text, len);
				//cerr << "      -======= " << text << " =======- " << endl;
				if( key ) {
					lua_pushstring(L, text.c_str());					// [-0, +1, -]
					key_value = text; // for debug only!!!
				} else {
					//cerr << "      -======= " << key_value << " = " << text << " =======- " << endl;
					lua_pushstring(L, text.c_str());					// [-0, +1, -]
					lua_settable(L, -3);								// [-2, +0, e]
				}
				break;
			case 0x04: // function
				if( key ){
					cerr << "Function can't be key" << endl;
					return false;
				} else {
					//cerr << "      -======= " << key_value << " =======- " << endl;
					len = fd->readLong();
					fd->readASCII(&text, len);
					status = 0;//luaL_loadbuffer(L, text.c_str(), len, "Sync load chunk");	// [-0, +1, -]
					if( status == 0){
						//lua_settable(L, -3);							// [-2, +0, e]
						lua_pop(L, 1);
					} else {
						cerr << text << endl;
						report(L, status);								// [-1, +0, e]
						lua_pop(L, 3);									// [-1, +0, -]
						return false;
					}
				}
				break;
			case 0x05: // start table
				if( key ){
					cerr << "Table can't be key" << endl;
					return false;
				} else {
					//cerr << "      -======= " << key_value << " (Table Start) =======- " << endl;
					fd->unget();
					lua_pushvalue(L, -1);
					lua_gettable(L, -3);								// [-1, +1, -]
					// stack : 	-3 is table
					// 			-2 is key of table (will be pop-ed)
					//			-1 is its value
					if( !read_table(fd, false) ){
						lua_pop(L, 2);
						return false;
					}
					//cerr << "      -======= " << key_value << " (Table End) =======- " << endl;
					//lua_pop(L, 1);
				}
				break;
			case 0x07: // reference
				if( key ){
					cerr << "Reference can't be key" << endl;
					return false;
				} else {
					len = fd->readUShort();
					cerr << "      -======= " << key_value << " refs " << len << " =======- " << endl;
					if( len <= num_objects ){
						lua_getglobal(L, "cartridge");		// +1
						lua_getfield(L, -1, "AllZObjects");	// +1
						lua_remove(L, -2);					// -1
						lua_pushnumber(L, len);				// +1
						lua_gettable(L, -2);				// +0
						lua_remove(L, -2);					// -1
						lua_settable(L, -3);				// -2
					} else if (len == 0xabcd) { // player 
						lua_getglobal(L, "Wherigo");		// +1
						lua_getfield(L, -1, "Player");		// +1
						lua_remove(L, -2);					// -1
						lua_settable(L, -3);				// -2
					} else { //unknown object ...
						cerr << "Unknown object to reference" << endl;
						lua_pop(L, 1);
					}
				}
				break;
			case 0x08: // object
				if( key ){
					cerr << "Object can't be key" << endl;
					return false;
				} else {
					//cerr << "      -======= " << key_value << " (Object Start) =======- " << endl;
					lua_pushvalue(L, -1);
					lua_gettable(L, -3);
					// stack : 	-3 is table
					// 			-2 is key of table (will be pop-ed)
					//			-1 is its value
					if( !read_object(fd, key_value, true) ){
						lua_pop(L, 2);
						return false;
					}
					//cerr << "      -======= " << key_value << " (Object End) =======- " << endl;
					//lua_pop(L, 1);
				}
				break;
			case 0x06:
			default:
				cerr << "Unexpected input code: " << code << endl;
				break;
		}
		key = !key;
	}
	
	if( set_field ){
		lua_settable(L, -3);											// [-2, +0, e]
	} else {
		lua_pop(L, 2);													// [-2, +0, e]
	}
		
	return true;
}

/**
 * Read from open GWS file object
 * Expected stack state before call:
 *  -3	table
 *  -2	key of table
 *  -1	value at key in table
 * 
 * After function return, last two values on stack will be removed
 */
bool read_object(fileReader *fd, string key_name, bool create_objects = false){	// [-2, +0, e]
	string objname;
	long len = fd->readLong();
	fd->readASCII(&objname, len);
	
	bool set_field = false;
	if( ! lua_istable(L, -1) ){
		if( create_objects ){
			lua_pop(L, 1);												// [-1, +0, -]
			int status = luaL_dostring(L,
				(string("return Wherigo.") + objname + ".new(cartridge)").c_str()
				);														// [-0, +1, e]
			report(L, status);
			set_field = true;
			cerr << " -============ creating " << objname << " ============- " << endl;
		} else {
			cerr << "Object " << key_name << " doesn't exists and is denied to create" << endl;
			return false;
		}
	} else {
		cerr << " -============ " << objname << " ============- " << endl;
	}
	lua_getfield(L, -1, "_classname");									// [-0, +1, e]
	const char* name = lua_tostring(L, -1);
	
	if( objname.compare(name) != 0 ){
		lua_pop(L, 3);													// [-2, +0, -]
		cerr << "Unexpected object at input. Expected " << name << ", got " << objname << endl;
		return false;
	}
	lua_pop(L, 1);														// [-1, +0, -]
	
	bool res = read_table(fd, set_field);								// [-2, +0, e]
	return res;
}

bool restore(){
	string save_filename = WherigoOpen->getSaveFilename();
	fileReader fd;
	fd.open(save_filename.c_str() , ios::in | ios::binary);
	if( ! fd.good() ){
		cerr << "savefile doesn't exists" << endl;
		return false;
	}
	
	// check header
	int size = sizeof(GWS_SIG);
	char *data = new char [size];
	fd.read(data, size);
	int i = 0;
	while(i < size ){
		if( GWS_SIG[i] != data[i] ){
			stringstream t;
			t << i << ": " << GWS_SIG[i] << "_" << data[i];
			my_error( t.str() );
			delete [] data;
			fd.close();
			cerr << "restore failed" << endl;
			return false;
		}
		i++;
	}
	delete [] data;
	
	string pom;
	int header_length = fd.readLong();
	fd.readASCIIZ( &pom );
	if( pom.compare(WherigoOpen->cartridgeName) != 0 ){
		fd.close();
		cerr << "Savegame is made for other cartridge name. Got " << pom
			<< ", expected " << WherigoOpen->cartridgeName << endl;
		return false;
	}
	fd.readLong();
	fd.readLong(); // date of creation???
	fd.readASCIIZ( &pom );
	if( pom.compare(WherigoOpen->player) != 0 ){
		fd.close();
		cerr << "Savegame is made for other player then cartridge. Got " << pom
			<< ", expected " << WherigoOpen->player << endl;
		return false;
	}
	fd.readASCIIZ( &pom );
	// device name
	fd.readASCIIZ( &pom );
	// device doesn't matter
	fd.readLong();
	fd.readLong(); // date of save
	string message;
	fd.readASCIIZ( &message );
	fd.readDouble(); // lat
	fd.readDouble(); // lon
	fd.readDouble(); // alt
	
	num_objects = fd.readLong();
	//string objects[num_objects];
	
	long len;
	string obj;
	//objects[0] = "ZCartridge";
	for(int i = 1; i < num_objects; i++){
		len = fd.readLong();
		//fd.readASCII(&objects[i], len);
		fd.readASCII(&obj, len);
	}
	
	// read Player data
	lua_getfield(L, LUA_GLOBALSINDEX, "Wherigo");	// [-0, +1, e]
	lua_getfield(L, -1, "Player");					// [-0, +1, e]
	lua_remove(L, -2);								// [-1, +0, -]
	lua_pushvalue(L, -1);							// [-0, +1, -]
	if( ! read_object(&fd, "Player", false) ){		// [-2, +0, e]
		lua_pop(L, 2);
		fd.close();
		return false;
	}
	
	lua_getfield(L, LUA_GLOBALSINDEX, "cartridge");						// [-0, +1, e]
	lua_getfield(L, -1, "AllZObjects");									// [-0, +1, e]
	
	//lua_pushnil(L);
	for(int i = 0; i < num_objects; i++){
		//if( lua_next(L, -2) == 0) {										// [-1, +(2|0), e]
		//	lua_pushnil(L);
			/*fd.close();
			cerr << "Expected more objects in environment ..." << endl;
			return false;*/
		//	break;// ignore more objects 
		//}
		lua_pushnumber(L, i);											// [-0, +1, -]
		lua_pushvalue(L, -1);											// [-0, +1, -]
		lua_gettable(L, -3);											// [-1, +1, e]
		if( ! read_object(&fd, "", false) ){							// [-2, +0, e]
			fd.close();
			lua_pop(L, 2);
			return false;
		}
		
		//lua_pop(L, 1); // included in read_object
	}
	// if ended ok, there is AllZObjects on stack
	lua_pop(L, 1);														// [-2, +0, -]
	
	
	// renew ZVariables to global namespace
	lua_getfield(L, -1, "ZVariables");
	lua_remove(L, -2);
	if( ! lua_isnoneornil(L, -1) ){
		lua_pushnil(L);
		while( lua_next(L, -2) != 0 ){
			lua_setfield(L, LUA_GLOBALSINDEX, lua_tostring(L, -2) );
		}
	}
	lua_pop(L, 1);
	fd.close();

	stackdump_g(L); // check if is empty at the end

	return true;
}

}
}

