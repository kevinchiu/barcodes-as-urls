CC=			arm-apple-darwin-gcc
CFLAGS=		-Wall
LD=			$(CC) -macosx_version_min=10.4u

LDFLAGS=	-Wl \
			-lobjc \
			-framework CoreFoundation \
			-framework Foundation \
			-framework CoreGraphics \
			-framework UIKit \
			-framework LayerKit \
			-framework PhotoLibrary \
			-framework Camera
			
ReaderApp:	data/QRCodeImage.o \
			data/QRCodeSymbol.o \
			ecc/BCH15_5.o \
			ecc/ReedSolomon.o \
			Exceptions.o \
			geom/Axis.o \
			geom/IntPointHelper.o \
			geom/Line.o \
			geom/SamplingGrid.o \
			main.o \
			QRCodeDecoder.o \
			reader/pattern/AlignmentPattern.o \
			reader/pattern/FinderPattern.o \
			reader/pattern/LogicalSeed.o \
			reader/QRCodeDataBlockReader.o \
			reader/QRCodeImageReader.o \
			ReaderApplication.o \
			ValueMatrix.o

	$(LD) $(LDFLAGS) -o $@ $^
	
%.o:	%.m
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@
	
clean:
	rm *.o*/*.o*/*/*.o
	rm -rf Reader.app
	
all:	ReaderApp
	mkdir -p Reader.app
	cp ReaderApp Reader.app
	cp Info.plist Reader.app
