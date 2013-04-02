DESKTOP=0
PRE=0
PIXI=1
DEBUG=1

ifeq (1,$(DEBUG))
DEVICEOPTS=-g
else
DEVICEOPTS=-s
endif

PDL=-lpdl -lSDL
LIBS= 
INC="-I%PalmPDK%\include" "-I%PalmPDK%\include\SDL" 
LDFLAGS="-L%PalmPDK%\device\lib" $(PDL) $(LIBS) -Wl,--allow-shlib-undefined
RMDIR = -rd /S /Q
RM = -del
COPY = xcopy
PACKAGE = package
RECURSIVE = /S

PLUGIN=wig
LIB="lua\liblua.a"

ifeq (1,$(DESKTOP))
DEVICEOPTS += -DDESKTOP
PDL= -lSDL
INC= -I/usr/include/SDL/
PACKAGE = 
LDFLAGS=$(LIBS) -Wl,--allow-shlib-undefined
RMDIR = rm -rf
RM = rm -f
COPY = cp
LIB="lua/liblua.a"
RECURSIVE = -r
else ifeq (1,$(PRE))
DEVICEOPTS += -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=softfp
else ifeq (1,$(PIXI))
DEVICEOPTS += -mcpu=arm1136jf-s -mfpu=vfp -mfloat-abi=softfp
else
$(error Must set either PRE or PIXI variable to 1 to build)
endif

CFLAGS=$(INC) $(DEVICEOPTS) -pedantic -Wall

ifeq (1,$(DESKTOP))
CPP=g++
else
CPP=arm-none-linux-gnueabi-g++
endif

CPPFLAGS=$(CFLAGS)
              
.PHONY: all package clean depend

all: $(PLUGIN) $(PACKAGE)

#.cpp.o::
#	$(CPP) $(CPPFLAGS) -c $<

#.c.o::
#	$(CC) $(CFLAGS) -c $<

liblua.a: lua/lua.c
	make -C lua a
	$(COPY) $(LIB) liblua.a

$(PLUGIN): $(PLUGIN).cpp lua_common.o liblua.a lua_common.h \
 lua/lua.h lua/luaconf.h lua/lauxlib.h lua/lua.h lua/lualib.h \
 wherigo.o WherigoLib.o WherigoLib.Save.o Engine.o \
 filewriter.h filereader.h 
	$(CPP) $(CPPFLAGS) $(LDFLAGS) -o $@ $^ $(PDL) $(LIBS)

package: $(PLUGIN) appinfo.json logo.png
	$(RMDIR) STAGING
	mkdir STAGING
	$(COPY) $(PLUGIN) STAGING
#	$(COPY) $(LIB) STAGING
	$(COPY) appinfo.json STAGING
	$(COPY) framework_config.js STAGING
	$(COPY) Wig.js STAGING
	$(COPY) wherigo_plugin_appinfo.json STAGING
	$(COPY) depends.js STAGING
	$(COPY) index.html STAGING
	$(COPY) logo.png STAGING
	mkdir STAGING\images
	$(COPY) images STAGING\images $(RECURSIVE)
	mkdir STAGING\enyo
	$(COPY) enyo STAGING\enyo
	mkdir STAGING\tests
	$(COPY) tests STAGING\tests
	$(COPY) wherigo.lua STAGING
	echo filemode.755=$(PLUGIN) > STAGING\package.properties
	palm-package STAGING

install:
	echo "Installing version 1.0.4 !!!"
	palm-install com.dta3team.app.wherigo_1.0.4_all.ipk

run:
	palm-run STAGING

clean:
	$(RMDIR) STAGING
	$(RM) $(PLUGIN)
	make -C lua clean
	$(RM) *.o
	$(RM) $(LIB)

depend:
	@$(CC) $(CFLAGS) -MM lua_common.c *.cpp

lua_common.o: lua_common.c lua/lua.hpp lua/lua.h lua/luaconf.h lua/lauxlib.h lua/lualib.h
	$(CPP) $(CPPFLAGS) -c -o $@ $<
	
#main : $(PLUGIN).cpp lua_common.h lua/lua.h lua/lualib.h
#	$(CPP) $(CPPFLAGS) -c -o $@ $^ $(LIBS)

wherigo.o: wherigo.cpp wherigo.h filereader.h
	$(CPP) $(CPPFLAGS) -c -o $@ $<

WherigoLib.Save.o: WherigoLib.Save.cpp WherigoLib.Save.hpp filewriter.h filereader.h
	$(CPP) $(CPPFLAGS) -c -o $@ $<

WherigoLib.o: WherigoLib.cpp WherigoLib.hpp Engine.hpp
	$(CPP) $(CPPFLAGS) -c -o $@ $<

Engine.o: Engine.cpp WherigoLib.hpp Engine.hpp
	$(CPP) $(CPPFLAGS) -c -o $@ $<
