# ConvexHull -> libconvexhull.so
sources=Face.cpp FaceList.cpp HalfEdge.cpp Point3d.cpp QuickHull3D.cpp  Vector3d.cpp Vertex.cpp VertexList.cpp Waterman.cpp c_interface.cpp
objs=Face.o FaceList.o HalfEdge.o Point3d.o QuickHull3D.o Vector3d.o Vertex.o VertexList.o Waterman.o c_interface.o
includes=Face.h FaceList.h HalfEdge.h Point3d.h QuickHull3D.h Vector3d.h Vertex.h VertexList.h Waterman.h 

CPP=g++
STDVER=-std=c++17

.SILENT: lib 
lib: $(sources) $(includes)
	$(CPP) -fPIC $(STDVER) -O3 $(sources) -shared -o libwaterman.so

.SILENT: clean
clean:
	rm -f *o libwaterman.so
