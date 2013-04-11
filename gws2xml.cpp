#include "filereader.h"

/** GWS header */
unsigned char GWS_SIG[] = { 0x02, 0x0a, 0x53, 0x59, 0x4e, 0x43, 0x00 };

/** num objects in restore */
int num_objects;

bool read_object(fileReader *fd, string name);

/**
 * Read from open GWS file table
 * Expected stack state before call:
 *  -3	table
 *  -2	key of table
 *  -1	value at key in table
 * 
 * After function return, last two values on stack will be removed
 */
bool read_table(fileReader *fd){
	int code = fd->readByte();
	if(code != 0x05){ // start table
		cerr << "Expected 0x05 as start of table, got " << code << endl;
		return false;
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
					cout << "<" << key_value << ">" << (bool)len << "</" << key_value << ">" << endl;
				}
				break;
			case 0x02: // number
				number = fd->readDouble();
				if( key ){
					stringstream ss;
					ss << "id" << number;
					key_value = ss.str();
				} else {
					cout << "<" << key_value << ">" << number << "</" << key_value << ">" << endl;
				}
				break;
			case 0x03: // string
				len = fd->readLong();
				fd->readASCII(&text, len);
				if( key ) {
					key_value = text;
				} else {
					cout << "<" << key_value << ">" << text << "</" << key_value << ">" << endl;
				}
				break;
			case 0x04: // function
				if( key ){
					cerr << "Function can't be key" << endl;
					return false;
				} else {
					len = fd->readLong();
					fd->readASCII(&text, len);
					cout << "<" << key_value << ">function</" << key_value << ">" << endl;
				}
				break;
			case 0x05: // start table
				if( key ){
					cerr << "Table can't be key" << endl;
					return false;
				} else {
					fd->unget();
					cout << "<" << key_value << ">" << endl;
					read_table(fd);
					cout << "</" << key_value << ">" << endl;
				}
				break;
			case 0x07: // reference
				if( key ){
					cerr << "Reference can't be key" << endl;
					return false;
				} else {
					len = fd->readUShort();
					cout << "<" << key_value << " ref=\"" << len << "\"></" << key_value << ">" << endl;
					if( len <= num_objects || len == 0xabcd){
					} else { //unknown object ...
						cerr << "Unknown object to reference" << endl;
					}
				}
				break;
			case 0x08: // object
				if( key ){
					cerr << "Object can't be key" << endl;
					return false;
				} else {
					cout << "<" << key_value << ">" << endl;
					read_object(fd, key_value);
					cout << "</" << key_value << ">" << endl;
				}
				break;
			case 0x06:
			default:
				cerr << "Unexpected input code: " << code << endl;
				break;
		}
		key = !key;
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
bool read_object(fileReader *fd, string key_name){
	string objname;
	long len = fd->readLong();
	fd->readASCII(&objname, len);
	
	cout << "<" << objname << ">" << endl;
	
	bool res = read_table(fd);
	
	cout << "</" << objname << ">" << endl;
	
	return res;
}

int main(int argc, char *argv[]){
	if( argc < 1 ){
		cerr << "There must be at least one parametr with filename";
		return -1;
	}
	char *filename = argv[1];
	fileReader fd;
	fd.open(filename , ios::in | ios::binary);
	if( ! fd.good() ){
		cerr << "savefile doesn't exists" << endl;
		return -1;
	}
	
	// check header
	int size = sizeof(GWS_SIG);
	char *data = new char [size];
	fd.read(data, size);
	int i = 0;
	while(i < size ){
		if( GWS_SIG[i] != data[i] ){
			cerr << i << ": " << GWS_SIG[i] << "_" << data[i];
			delete [] data;
			fd.close();
			cerr << "Wrong GWS header" << endl;
			return false;
		}
		i++;
	}
	delete [] data;
	
	cout << "<?xml version=\"1.0\" ?>" << endl;
	string pom;
	int header_length = fd.readLong();
	cout << "<gws><header length=\"" << header_length << "\">" << endl;
	fd.readASCIIZ( &pom );
	cout << "<cartridge>" << pom << "</cartridge>" << endl;
	fd.readLong(); // readLongLong()  - 8 byte
	fd.readLong(); // date of creation???
	fd.readASCIIZ( &pom );
	cout << "<player>" << pom << "</player>" << endl;
	fd.readASCIIZ( &pom );
	cout << "<device>" << pom << "</device>" << endl;
	fd.readASCIIZ( &pom );
	cout << "<deviceId>" << pom << "</deviceId>" << endl;
	fd.readLong(); // readLongLong()  - 8 byte
	fd.readLong(); // date of save
	string message;
	fd.readASCIIZ( &message );
	cout << "<name>" << pom << "</name>" << endl;
	double lat = fd.readDouble(); // lat
	double lon = fd.readDouble(); // lon
	double alt = fd.readDouble(); // alt
	cout << "<location latitude=\"" << lat << "\" longitude=\"" << lon << "\" altitude=\"" << alt << "\"></location>" << endl;
	
	num_objects = fd.readLong();
	//string objects[num_objects];
	
	cout << "<objects>" << endl;
	long len;
	string obj;
	//objects[0] = "ZCartridge";
	for(int i = 1; i < num_objects; i++){
		len = fd.readLong();
		//fd.readASCII(&objects[i], len);
		fd.readASCII(&obj, len);
		cout << "<" << obj << " id=\"" << i << "\"></" << obj << ">" << endl;
	}
	cout << "</objects>" << endl;
	cout << "</header>" << endl;
	
	//cout << "<Player>" << endl;
	// read Player data
	read_object(&fd, "Player");
	//cout << "</Player>" << endl;
	
	for(int i = 0; i < num_objects; i++){
		read_object(&fd, "");
	}
	cout << "</gws>" << endl;
	
	return 0;
}
