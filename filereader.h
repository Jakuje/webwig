/* ========================================================================== */
/*                                                                            */
/*   FileReader.h                                                             */
/*   (c) 2012 Jakuje                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */
#ifndef _FILEREARED_H_
#define _FILEREARED_H_
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>

using namespace std;

class fileReader: public ifstream {
	short spom;
	unsigned short uspom;

	public:
		int readByte(){
			char pom;
			this->read( &pom, 1 );
			return (int) pom;
		}

		int readShort(){
			spom = 0;
			this->read( (char*)&spom, 2 );
			return (int) spom;
		}

		int readUShort(){
			uspom = 0;
			this->read( (char*)&uspom, 2 );
			return (int) uspom;
		}

		long readLong(){
			long pom = 0;
			this->read( (char*)&pom, 4 );
			return pom;
		}

		double readDouble(){
			double pom = 0;
			this->read((char*)&pom, 8);
			return pom;
		}

		void readASCIIZ(string *data){
			std::getline( *this, *data, '\0' );
		}
		
		void readASCII(string *data, streamsize num){
			data->clear();
			if( num > 0 ){
				char *buffer = new char [num+1];
				this->read( buffer, num );
				buffer[num] = '\0';
				data->append(buffer);
				delete [] buffer;
			}
		}

};

#endif
