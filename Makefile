CC = g++
NVCC = nvcc
CFLAGS = -g -Wall
OPENCV_PKGCONF = `pkg-config --cflags --libs opencv`

ALL: main Lifegame LifegameField
	$(NVCC) -o cvcudalifegame main.o Lifegame.o LifegameField.o $(OPENCV_PKGCONF)
#	$(CC) -o cvcudalifegame main.o Lifegame.o $(OPENCV_PKGCONF) 

main: main.cpp
	$(CC) $(CFLAGS) -o main.o -c main.cpp $(OPENCV_PKGCONF)

Lifegame: Lifegame.cpp Lifegame.h
	$(CC) $(CFLAGS) -o Lifegame.o -c Lifegame.cpp $(OPENCV_PKGCONF)

LifegameField: LifegameField.cu LifegameField.h
	$(NVCC) -o LifegameField.o -c LifegameField.cu $(OPENCV_PKGCONF)



#	$(NVCC) -o gpufunc.o -c gpufunc.cu $(OPENCV_PKGCONF)
