module ColorMap

push!(LOAD_PATH, "./")
using Coords

export color_map, max_color_map

const max_color_map = 25
const Color = Coords.Coord

function color_map(v_::Float32, vmin_::Float32, vmax_::Float32, type_::Int) :: Color
	v = v_
	vmin = vmin_
	vmax = vmax_

	dv = 0.0f0
	vmid = 0.0f0

	c = Color(1.0f0, 1.0f0, 1.0f0)

	c1 = zero(Color)
	c2 = zero(Color)
	c3 = zero(Color)

	ratio = 0.0f0
	if vmax < vmin
		dv = vmin
		vmin = vmax
		vmax = dv
	end
	if vmax - vmin < 1.0f-6
		vmin -= 1.0f0
		vmax += 1.0f0
	end
	if v < vmin
		v = vmin
	end
	if v > vmax
		v = vmax
	end
	dv = vmax - vmin


	if type_ == 1
		if v < (vmin + 0.25f0 * dv)
			c = Color(0.0f0, Float32(4.0f0 * (v - vmin) / dv), 1.0f0)
		elseif v < (vmin + 0.5f0 * dv)
			c = Color(0.0f0, 1.0f0, c.z)
			c.z = 1.0f0 + 4.0f0 * (vmin + 0.25f0 * dv - v) / dv
		elseif v < (vmin + 0.75f0 * dv)
			c = Color(Float32(4.0f0 * (v - vmin - 0.25f0 * dv) / dv), 1.0f0, Float32(1.0f0 + 4.0f0 * (vmin + 0.25f0 * dv - v) / dv))
			c.x = 4.0f0 * (v - vmin - 0.5f0 * dv) / dv
			c.y = 1.0f0
			c.z = 0.0f0
		end
    elseif type_ == 2
			c = Color(Float32((v - vmin) / dv), 0.0f0, Float32((vmax - v) / dv))
    elseif type_ == 3
			val = Float32((v - vmin) / dv)
			c = Color(val, val, val)
    elseif type_ == 4
			if v < (vmin + dv / 6.0f0)
				c = Color(1.0f0, Float32(6.0f0 * (v - vmin) / dv), 0.0f0)
			elseif v < (vmin + 2.0f0 * dv / 6.0f0)
				c = Color(Float32(1.0f0 + 6.0f0 * (vmin + dv / 6.0f0 - v) / dv), 1.0f0, 0.0f0)
			elseif v < (vmin + 3.0f0 * dv / 6.0f0)
				c = Color(0.0f0, 1.0f0, Float32(6.0f0 * (v - vmin - 2.0f0 * dv / 6.0f0) / dv))
			elseif v < (vmin + 4.0f0 * dv / 6.0f0)
				c = Color(1.0f0, Float32(1.0f0 + 4.0f0 * (vmin + 0.5f0 * dv - v) / dv), 0.0f0)
			elseif v < (vmin + 5.0f0 * dv / 6.0f0)
				c.x = 6.0f0 * (v - vmin - 4.0f0 * dv / 6.0f0) / dv
				c.y = 0.0f0
			else
				c.x = 1.0f0
				c.y = 0.0f0
				c.z = 1.0f0 + 6.0f0 * (vmin + 5.0f0 * dv / 6.0f0 - v) / dv
			end
		elseif type_ == 5
			c = Color(Float32((v - vmin) / dv), 1.0f0, 0.0f0)
		elseif type_ == 6
			val = Float32((v - vmin) / (vmax - vmin))
			c = Color(val, Float32((vmax - v) / (vmax - vmin)), val)
		elseif type_ == 7
			if v < (vmin + 0.25f0 * dv)
				val = Float32(4.0f0 * (v - vmin) / dv)
				c = Color(0.0f0, val, 1.0f0 - val)
			elseif v < (vmin + 0.5f0 * dv)
				val = Float32(4.0f0 * (v - vmin - 0.25f0 * dv) / dv)
				c = Color(val, 1.0f0 - val, 0.0f0)
			elseif v < (vmin + 0.75f0 * dv)
				val = Float32(4.0f0 * (v - vmin - 0.5f0 * dv) / dv)
				c = Color(1.0f0 - val, val, 0.0f0)
			else
				c = Color(1.0f0, Float32(4.0f0 * (v - vmin - 0.75f0 * dv) / dv), 0.0f0) - c.z
			end
		elseif type_ == 8
			if v < (vmin + 0.5f0 * dv)
				val = Float32(2.0f0 * (v - vmin) / dv)
				c = Color(val, val, val)
			else
				val = Float32(1.0f0 - 2.0f0 * (v - vmin - 0.5f0 * dv) / dv)
				c = Color(val, val, val)
    			end
		elseif type_ == 9
			if v < (vmin + dv / 3.0f0)
				val = Float32(3.0f0 * (v - vmin) / dv)
				c = Color(1.0f0 - val, 0.0f0, val)
			elseif v < (vmin + 2.0f0 * dv / 3.0f0)
				c = Color(0.0f0, Float32(3.0f0 * (v - vmin - dv / 3.0f0) / dv), 1.0f0)
			else
				val = Float32(3.0f0 * (v - vmin - 2.0f0 * dv / 3.0f0) / dv)
				c = Color(val, 1.0f0 - val, 1.0f0)
			end
		elseif type_ == 10
			if v < (vmin + 0.2f0 * dv)
				c = Color(0.0f0, Float32(5.0f0 * (v - vmin) / dv), 1.0f0)
			elseif v < (vmin + 0.4f0 * dv)
				c = Color(0.0f0, 1.0f0, Float32(1.0f0 + 5.0f0 * (vmin + 0.2f0 * dv - v) / dv))
			elseif v < (vmin + 0.6f0 * dv)
				c = Color(Float32(5.0f0 * (v - vmin - 0.4f0 * dv) / dv), 1.0f0, 0.0f0)
			elseif v < (vmin + 0.8f0 * dv)
				c = Color(1.0f0, Float32(1.0f0 - 5.0f0 * (v - vmin - 0.6f0 * dv) / dv), 0.0f0)
			else
				val = Float32(5.0f0 * (v - vmin - 0.8f0 * dv) / dv)
				c = Color(1.0f0, val, val)
			end
		elseif type_ == 11
			c1 = Color(200.0f0 / 255, 60.0f0 / 255, 0.0f0 / 255)
			c2 = Color(250.0f0 / 255, 160.0f0 / 255, 110.0f0 / 255)
			t = Float32((v - vmin) / dv)
			c = c1 * (1-t) + c2 * t
		elseif type_ == 12
			c1 = Color(55.0f0 / 255, 55.0f0 / 255, 45.0f0 / 255)
			c2 = Color(235.0f0 /255, 90.0f0/255, 30.0f0/255)
			c3 = Color(250.0f0/255, 160.0f0/255, 110.0f0/255)
			ratio = 0.4f0
			vmid = vmin + ratio * dv
			if v < vmid
				t = Float32((v - vmin) / (ratio * dv))
				c = c1 * (1-t) + c2 * t
			else
				t = Float32((v - vmid) / ((1.0f0 - ratio) * dv))
				c = c2 * (1-t) + c3 * t
			end
		elseif type_ == 13
			c1 = Color(0.0f0/255, 255.0f0/255, 0.0f0/255)
			c2 = Color(255.0f0/255, 150.0f0/255, 0.0f0/255)
			c3 = Color(255.0f0/255, 250.0f0/255, 240.0f0/255)
			ratio = 0.3f0
			vmid = vmin + ratio * dv
			if v < vmid
				c.x = (c2.x - c1.x) * (v - vmin) / (ratio * dv) + c1.x
				c.y = (c2.y - c1.y) * (v - vmin) / (ratio * dv) + c1.y
				c.z = (c2.z - c1.z) * (v - vmin) / (ratio * dv) + c1.z
			else
				c.x = (c3.x - c2.x) * (v - vmid) / ((1.0f0 - ratio) * dv) + c2.x
				c.y = (c3.y - c2.y) * (v - vmid) / ((1.0f0 - ratio) * dv) + c2.y
				c.z = (c3.z - c2.z) * (v - vmid) / ((1.0f0 - ratio) * dv) + c2.z
				c.x = (c3.x - c2.x) * (v - vmid) / ((1.0f0 - ratio) * dv) + c2.x
				c.y = (c3.y - c2.y) * (v - vmid) / ((1.0f0 - ratio) * dv) + c2.y
				c.z = (c3.z - c2.z) * (v - vmid) / ((1.0f0 - ratio) * dv) + c2.z
			end
		elseif type_ == 14
			c.x = 1.0f0
			c.y = 1.0f0 - (v - vmin) / dv
			c.z = 0.0f0
		elseif type_ == 15
			if v < (vmin + 0.25f0 * dv)
				c.x = 0.0f0
				c.y = 4.0f0 * (v - vmin) / dv
				c.z = 1.0f0
			elseif v < (vmin + 0.5f0 * dv)
				c.x = 0.0f0
				c.y = 1.0f0
				c.z = 1.0f0 - 4.0f0 * (v - vmin - 0.25f0 * dv) / dv
			elseif v < (vmin + 0.75f0 * dv)
				c.x = 4.0f0 * (v - vmin - 0.5f0 * dv) / dv
				c.y = 1.0f0
				c.z = 0.0f0
			else 
				c.x = 1.0f0
				c.y = 1.0f0
				c.z = 4.0f0 * (v - vmin - 0.75f0 * dv) / dv
            end
		elseif type_ == 16
			if v < (vmin + 0.5f0 * dv)
				c.x = 0.0f0
				c.y = 2.0f0 * (v - vmin) / dv
				c.z = 1.0f0 - 2.0f0 * (v - vmin) / dv
			else
				c.x = 2.0f0 * (v - vmin - 0.5f0 * dv) / dv
				c.y = 1.0f0 - 2.0f0 * (v - vmin - 0.5f0 * dv) / dv
				c.z = 0.0f0
			end
		elseif type_ == 17
			if v < (vmin + 0.5f0 * dv)
				c.x = 1.0f0
				c.y = 1.0f0 - 2.0f0 * (v - vmin) / dv
				c.z = 2.0f0 * (v - vmin) / dv
			else
				c.x = 1.0f0 - 2.0f0 * (v - vmin - 0.5f0 * dv) / dv
				c.y = 2.0f0 * (v - vmin - 0.5f0 * dv) / dv
				c.z = 1.0f0
			end
		elseif type_ == 18
			c.x = 0.0f0
			c.y = (v - vmin) / (vmax - vmin)
			c.z = 1.0f0
		elseif type_ == 19
			c.x = (v - vmin) / (vmax - vmin)
			c.y = c.x
			c.z = 1.0f0
		elseif type_ == 20
			c1.x = 0.0f0
			c1.y = 160.0f0 / 255
			c1.z = 0.0f0
			c2.x = 180.0f0 / 255
			c2.y = 220.0f0 / 255
			c2.z = 0.0f0
			c3.x = 250.0f0 / 255
			c3.y = 220.0f0 / 255
			c3.z = 170.0f0 / 255
			ratio = 0.3f0
			vmid = vmin + ratio * dv
			if v < vmid
				c.x = (c2.x - c1.x) * (v - vmin) / (ratio * dv) + c1.x
				c.y = (c2.y - c1.y) * (v - vmin) / (ratio * dv) + c1.y
				c.z = (c2.z - c1.z) * (v - vmin) / (ratio * dv) + c1.z
			else
				c.x = (c3.x - c2.x) * (v - vmid) / ((1.0f0 - ratio) * dv) + c2.x
				c.y = (c3.y - c2.y) * (v - vmid) / ((1.0f0 - ratio) * dv) + c2.y
				c.z = (c3.z - c2.z) * (v - vmid) / ((1.0f0 - ratio) * dv) + c2.z
			end
		elseif type_ == 21
			c1.x = 255.0f0 / 255
			c1.y = 255.0f0 / 255
			c1.z = 200.0f0 / 255
			c2.x = 150.0f0 / 255
			c2.y = 150.0f0 / 255
			c2.z = 255.0f0 / 255
			c.x = (c2.x - c1.x) * (v - vmin) / dv + c1.x
			c.y = (c2.y - c1.y) * (v - vmin) / dv + c1.y
			c.z = (c2.z - c1.z) * (v - vmin) / dv + c1.z
		elseif type_ == 22
			c.x = 1.0f0 - (v - vmin) / dv
			c.y = 1.0f0 - (v - vmin) / dv
			c.z = (v - vmin) / dv
		elseif type_ == 23
			if v < (vmin + 0.5f0 * dv)
				c.x = 1.0f0
				c.y = 2.0f0 * (v - vmin) / dv
				c.z = c.y
			else
				c.x = 1.0f0 - 2.0f0 * (v - vmin - 0.5f0 * dv) / dv
				c.y = c.x
				c.z = 1.0f0
			end
		elseif type_ == 24
			if v < (vmin + 0.5 * dv)
				c.x = 2.0f0 * (v - vmin) / dv
				c.y = c.x
				c.z = 1.0f0 - c.x
			else
				c.x = 1.0f0
				c.y = 1.0f0 - 2.0f0 * (v - vmin - 0.5f0 * dv) / dv
				c.z = 0.0f0
			end
		elseif type_ == 25
			if v < (vmin + dv / 3)
				c.x = 0.0f0
				c.y = 3.0f0 * (v - vmin) / dv
				c.z = 1.0f0
			elseif v < (vmin + 2 * dv / 3)
				c.x = 3.0f0 * (v - vmin - dv / 3) / dv
				c.y = 1.0f0 - c.x
				c.z = 1.0f0
			else
				c.x = 1.0f0
				c.y = 0.0f0
				c.z = 1.0f0 - 3.0f0 * (v - vmin - 2 * dv / 3) / dv
			end
		end
		return c
end

end