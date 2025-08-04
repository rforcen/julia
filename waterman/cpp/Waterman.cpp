#include "Waterman.h"


// 3d waterman polygon generator -> vec3* and 'ntc', radius: change from 1..
// after must generate the convex hull
vector<double> genPoly(double radius) {
  double x, y, z, a, b, c, xra, xrb, yra, yrb, zra, zrb, R, Ry, s, radius2;

  vector<double> coords;

  a = b = c = 0;  // center

  s = radius;
  radius2 = radius;  // * radius;
  xra = ceil(a - s);
  xrb = floor(a + s);

  for (x = xra; x <= xrb; x++) {
    R = radius2 - (x - a) * (x - a);
    if (R < 0) continue;
    s = sqrt(R);
    yra = ceil(b - s);
    yrb = floor(b + s);

    for (y = yra; y <= yrb; y++) {
      Ry = R - (y - b) * (y - b);
      if (Ry < 0) continue;            // case Ry < 0
      if (Ry == 0 && c == floor(c)) {  // case Ry=0
        if (fmod((x + y + c), 2) != 0)
          continue;
        else {
          zra = c;
          zrb = c;
        }
      } else {  // case Ry > 0
        s = sqrt(Ry);
        zra = ceil(c - s);
        zrb = floor(c + s);
        if (fmod((x + y), 2) == 0) {  // (x+y)mod2=0
          if (fmod(zra, 2) != 0) {
            if (zra <= c)
              zra = zra + 1;
            else
              zra = zra - 1;
          }
        } else {  // (x+y) mod 2 <> 0
          if (fmod(zra, 2) == 0) {
            if (zra <= c)
              zra = zra + 1;
            else
              zra = zra - 1;
          }
        }
      }

      for (z = zra; z <= zrb; z += 2) {  // save vertex x,y,z
        coords.push_back(x);
        coords.push_back(y);
        coords.push_back(z);
      }
    }
  }

  return coords;
}

