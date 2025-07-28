# raw Vec
type Vec*[t] = ptr t
# access data item p + int.size + i*t.size
proc data*[t](p: ptr t, i:int = 0): ptr t = cast[ptr t](cast[int](p) + i*t.sizeof)
# indexers
proc `[]`*[t](p: ptr t, i: int): t = p.data(i)[]
proc `[]=`*[t](p: ptr t, i: int, val: t) = cast[ptr t](cast[int](p) + i*t.sizeof)[] = val
iterator items*[t](v: Vec[t], n:int): t =
  var i = 0
  while i <= n:
      yield v[i]
      inc i
####
