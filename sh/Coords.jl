module Coords

export Coord, dot, cross, norm, normalize, zero

struct Coord
    x::Float32
    y::Float32
    z::Float32
end

# Basic arithmetic operations
Base.:+(a::Coord, b::Coord) = Coord(a.x + b.x, a.y + b.y, a.z + b.z)
Base.:-(a::Coord, b::Coord) = Coord(a.x - b.x, a.y - b.y, a.z - b.z)
Base.:-(a::Coord) = Coord(-a.x, -a.y, -a.z)
Base.:*(a::Coord, b::Number) = Coord(a.x * Float32(b), a.y * Float32(b), a.z * Float32(b))
Base.:*(a::Number, b::Coord) = b * a
Base.:/(a::Coord, b::Number) = Coord(a.x / Float32(b), a.y / Float32(b), a.z / Float32(b))
Base.zero(::Type{Coord}) = Coord(0.0f0, 0.0f0, 0.0f0)

# Linear algebra operations
dot(a::Coord, b::Coord) = a.x * b.x + a.y * b.y + a.z * b.z

function cross(a::Coord, b::Coord)
    x = a.y * b.z - a.z * b.y
    y = a.z * b.x - a.x * b.z
    z = a.x * b.y - a.y * b.x
    Coord(x, y, z)
end

norm(a::Coord) = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
normalize(a::Coord) = a / norm(a)
normal(v0::Coord, v1::Coord, v2::Coord) = normalize(cross(v1 - v0, v2 - v0))

# Conversion and display
# Base.convert(::Type{Coord}, x::AbstractVector{<:Number}) = Coord(x[1], x[2], x[3])
Base.show(io::IO, c::Coord) = print(io, "Coord($(c.x), $(c.y), $(c.z))")

end
