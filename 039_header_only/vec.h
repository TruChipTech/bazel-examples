#ifndef VEC_H_
#define VEC_H_

// A header-only library: all definitions are inline, so there is nothing to
// compile into a .o file.
struct Vec2 {
  double x = 0, y = 0;

  Vec2 operator+(const Vec2& o) const { return Vec2{x + o.x, y + o.y}; }
  double Dot(const Vec2& o) const { return x * o.x + y * o.y; }
};

#endif  // VEC_H_
