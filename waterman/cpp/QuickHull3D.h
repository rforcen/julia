
/**
 * Computes the convex hull of a set of three dimensional points.
 *
 * <p>The algorithm is a three dimensional implementation of Quickhull, as
 * described in Barber, Dobkin, and Huhdanpaa, <a
 * href=http://citeseer.ist.psu.edu/barber96quickhull.html> ``The Quickhull
 * Algorithm for Convex Hulls''</a> (ACM Transactions on Mathematical Software,
 * Vol. 22, No. 4, December 1996), and has a complexity of O(n log(n)) with
 * respect to the number of points. A well-known C implementation of Quickhull
 * that works for arbitrary dimensions is provided by <a
 * href=http://www.qhull.org>qhull</a>.
 *
 * @author John E. Lloyd, Fall 2004 */

#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <vector>

using std::vector;

class Vertex;
class Face;
class FaceList;
class Vertex;
class VertexList;
class Point3d;
class HalfEdge;

typedef vector<Face *> FaceVector;
typedef vector<HalfEdge *> HalfEdgeVector;

class QuickHull3D {
#define null NULL

 public:
  /**
   * Specifies that (on output) vertex indices for a face should be
   * listed in clockwise order.
   */
  static const int CLOCKWISE = 0x1, CCW = 0;

  /**
   * Specifies that (on output) the vertex indices for a face should be
   * numbered starting from 1.
   */
  static const int INDEXED_FROM_ONE = 0x2;

  /**
   * Specifies that (on output) the vertex indices for a face should be
   * numbered starting from 0.
   */
  static const int INDEXED_FROM_ZERO = 0x4;

  /**
   * Specifies that (on output) the vertex indices for a face should be
   * numbered with respect to the original input points.
   */
  static const int POINT_RELATIVE = 0x8;

  /**
   * Specifies that the distance tolerance should be
   * computed automatically from the input point data.
   */
  static constexpr double AUTOMATIC_TOLERANCE = -1;

  int findIndex = -1;

  // estimated size of the point set
  double charLength;

  vector<Vertex *> pointBuffer;
  vector<int> vertexPointIndices;
  vector<Face *> discardedFaces;

  vector<Vertex *> maxVtxs;
  vector<Vertex *> minVtxs;

  FaceVector faces;
  HalfEdgeVector horizon;

  FaceList *newFaces;
  VertexList *unclaimed;
  VertexList *claimed;

  int numVertices = 0;
  int numFaces = 0;
  int numPoints = 0;

  double explicitTolerance = AUTOMATIC_TOLERANCE;
  double tolerance;

  

  void initPrt();  // init pointers that can't be init here
  /**
   * Precision of a double.
   */
  double DOUBLE_PREC = 2.2204460492503131e-16;

  double getDistanceTolerance();
  void setExplicitDistanceTolerance(double tol);
  double getExplicitDistanceTolerance();
  void addPointToFace(Vertex *vtx, Face *face);
  void removePointFromFace(Vertex *vtx, Face *face);
  Vertex *removeAllPointsFromFace(Face *face);

  QuickHull3D();
  QuickHull3D(vector<double> coords);
  QuickHull3D(vector<Point3d *> points);
  QuickHull3D(double *points, size_t n_points);
  ~QuickHull3D();
  void cleanup();

  HalfEdge *findHalfEdge(Vertex *tail, Vertex *head);
  void setHull(vector<double> coords, int nump,
               vector<vector<int>> &faceIndices, int numf);

  void build(vector<double> coords);
  void build(vector<double> coords, int nump);
  void build(vector<Point3d *> points);
  void build(vector<Point3d *> points, int nump);
  void build(double *coords, int nump);
  void triangulate();
  void initBuffers(int nump);
  void setPoints(vector<double> coords, int nump);
  void setPoints(vector<Point3d *> pnts, int nump);
  void setPoints(double *coords, int nump);
  void computeMaxAndMin();
  void createInitialSimplex();
  int getNumVertices();
  vector<Point3d *> getVertices();
  vector<double> getVertex();
  vector<double> getScaledVertex();
  int getVertices(vector<double> coords);
  vector<int> getVertexPointIndices();
  int getNumFaces();
  vector<vector<int>> getFaces();
  vector<vector<int>> getFaces(int indexFlags);
  void getFaceIndices(vector<int> &indices, Face *face, int flags);
  void resolveUnclaimedPoints(FaceList *newFaces);
  void deleteFacePoints(Face *face, Face *absorbingFace);

  static const int NONCONVEX_WRT_LARGER_FACE = 1;
  static const int NONCONVEX = 2;

  double oppFaceDistance(HalfEdge *he);
  bool doAdjacentMerge(Face *face, int mergeType);
  void calculateHorizon(Point3d *eyePnt, HalfEdge *edge0, Face *face,
                        HalfEdgeVector &horizon);
  HalfEdge *addAdjoiningFace(Vertex *eyeVtx, HalfEdge *he);
  void addNewFaces(FaceList *newFaces, Vertex *eyeVtx, HalfEdgeVector horizon);
  Vertex *nextPointToAdd();
  void addPointToHull(Vertex *eyeVtx);
  void buildHull();
  void markFaceVertices(Face *face, int mark);
  void reindexFacesAndVertices();
  bool checkFaceConvexity(Face *face, double tol);
  bool checkFaces(double tol);
  bool check();
  bool check(double tol);
};
