// c interface

#include "QuickHull3D.h"
#include "Waterman.h"

typedef struct _Mesh {
  int n_faces, n_coords;
  int *faces;
  double *coords;
} Mesh;

extern "C" {

Mesh *watermanMesh(double radius) {
  QuickHull3D hull(genPoly(radius));

  auto faces = hull.getFaces(); // faces & vertexes
  auto coords = hull.getScaledVertex();

  Mesh *mesh = (Mesh *)malloc(sizeof(Mesh));
  mesh->n_faces = 0; // count # item in face + len(1)
  for (auto face : faces) {
    mesh->n_faces += face.size() + 1;
  }
  mesh->n_coords = coords.size();

  // alloc faces/vertexes
  mesh->faces = (int *)malloc(mesh->n_faces * sizeof(int));
  mesh->coords = (double *)malloc(mesh->n_coords * sizeof(double));

  int iface = 0; // line up faces
  for (auto face : faces) {
    mesh->faces[iface++] = (int)face.size();
    std::copy(face.begin(), face.end(), mesh->faces + iface);
    iface += face.size();
  }

  // copy vertexes
  std::copy(coords.begin(), coords.end(), mesh->coords);

  return mesh;
}

void watermanPoly(double radius, int *_nfaces, int *_nvertexes, int **_faces,
                  double **_vertexes) {
  QuickHull3D hull(genPoly(radius));

  auto faces = hull.getFaces(); // faces & vertexes
  auto coords = hull.getScaledVertex();

  *_nfaces = 0; // count # item in face + len(1)
  for (auto face : faces) {
    *_nfaces += face.size() + 1;
  }
  *_nvertexes = coords.size();

  // alloc faces/vertexes
  *_faces = (int *)malloc(*_nfaces * sizeof(int));
  *_vertexes = (double *)malloc(coords.size() * sizeof(double));

  int iface = 0; // line up faces
  for (auto face : faces) {
    (*_faces)[iface++] = (int)face.size();
    std::copy(face.begin(), face.end(), (*_faces) + iface);
    iface += face.size();
  }

  // copy vertexes
  std::copy(coords.begin(), coords.end(), *_vertexes);
}

void freeCH(int *_faces, double *_vertexes) {
  free(_faces);
  free(_vertexes);
}
void freeMesh(Mesh *mesh) {
  free(mesh->faces);
  free(mesh->coords);
  free(mesh);
}
}
