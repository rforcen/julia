void new_polygonizer_nim(float bounds, int idiv, float (*fnc)(float, float, float),
                     int *n_vertexes, int *n_triangles, void **p_vertexes,
                     void **p_triangles);

void free_polygonizer_nim(void *pvertexes, void *ptriangles);