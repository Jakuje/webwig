PRE=0
PIXI=1
DESKTOP=0
DEBUG=1

ifeq (1,$(DEBUG))
DEVICEOPTS=-g
else
DEVICEOPTS=
endif

ifeq (1,$(PRE))
DEVICEOPTS += -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=softfp
else ifeq (1,$(PIXI))
DEVICEOPTS += -mcpu=arm1136jf-s -mfpu=vfp -mfloat-abi=softfp
else
$(error Must set either PRE or PIXI variable to 1 to build)
endif

INC="-I%PalmPDK%\include" "-I%PalmPDK%\include\SDL" 

#CC=arm-none-linux-gnueabi-gcc
# ../webos_common/libstdc++.so.6
CFLAGS=$(INC) $(DEVICEOPTS) -pedantic -Wall
CPP=arm-none-linux-gnueabi-g++
CPPFLAGS=$(CFLAGS)
LIBS=-lSDL -lSDL_image -lSDL_ttf -lpdl -lGLESv2 
LDFLAGS="-L%PalmPDK%\device\lib" $(LIBS) -Wl,--allow-shlib-undefined
              
PLUGIN=wig
LIB="lua\liblua.a"

all: $(PLUGIN) package

#.cpp.o::
#	$(CPP) $(CPPFLAGS) -c $<

#.c.o::
#	$(CC) $(CFLAGS) -c $<

liblua.a: lua/lua.c
	make -C lua a
	copy $(LIB) liblua.a

$(PLUGIN): $(PLUGIN).cpp lua_common.o liblua.a lua_common.h \
 lua/lua.h lua/luaconf.h lua/lauxlib.h lua/lua.h lua/lualib.h \
 wherigo.o filereader.h
	$(CPP) $(CPPFLAGS) $(LDFLAGS) -o $@ $^ $(LIBS)

package: $(PLUGIN) appinfo.json logo.png
	-rd /S /Q STAGING
	mkdir STAGING
	copy $(PLUGIN) STAGING
#	copy $(LIB) STAGING
	copy appinfo.json STAGING
	copy framework_config.js STAGING
	copy Wig.js STAGING
	copy wherigo_plugin_appinfo.json STAGING
	copy depends.js STAGING
	copy index.html STAGING
	copy logo.png STAGING
	mkdir STAGING\images
	copy images STAGING\images
	mkdir STAGING\enyo
	copy enyo STAGING\enyo
#sources
	copy wig.cpp STAGING
	copy wherigo.cpp STAGING
	echo filemode.755=$(PLUGIN) > STAGING\package.properties
#	palm-package STAGING
#	palm-install com.dta3team.app.simplepdk_1.0.0_all.ipk
	palm-run STAGING

clean:
	-rd /S /Q STAGING
	-del $(PLUGIN)
	-del liblua.a
	-del *.o
	-del $(LIB)

depend:
	@$(CC) $(CFLAGS) -MM lua_common.c *.cpp

lua_common.o: lua_common.c lua/lua.hpp lua/lua.h lua/luaconf.h lua/lauxlib.h lua/lualib.h
	$(CPP) $(CPPFLAGS) -c -o $@ $<
	
#main : $(PLUGIN).cpp lua_common.h lua/lua.h lua/lualib.h
#	$(CPP) $(CPPFLAGS) -c -o $@ $^ $(LIBS)

wherigo.o: wherigo.cpp wherigo.h
	$(CPP) $(CPPFLAGS) -c -o $@ $<

