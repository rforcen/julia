/**
 * A three-element spatial point.
 */

#pragma once

#include "Vector3d.h"

class Point3d : public Vector3d {
 public:
  const int __mark = 0x77777777;
  Point3d();
  Point3d(Vector3d *v);
  Point3d(double x, double y, double z);
};
