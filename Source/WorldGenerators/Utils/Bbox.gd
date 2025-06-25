extends Resource
class_name BBox

var start_pos: Vector3 = Vector3.ZERO
var end_pos: Vector3   = Vector3.ONE

func _init(_start_pos: Vector3 = Vector3.ZERO, _end_pos: Vector3 = Vector3.ONE) -> void:
    start_pos = _start_pos
    end_pos   = _end_pos

func center() -> Vector3:
    return (start_pos + end_pos) * 0.5

func width()  -> float:
    return abs(end_pos.x - start_pos.x)

func height() -> float:
    return abs(end_pos.y - start_pos.y)

func depth()  -> float:
    return abs(end_pos.z - start_pos.z)

func min_x() -> float:
    return min(start_pos.x,end_pos.x)

func min_y() -> float:
    return min(start_pos.y,end_pos.y)

func min_z() -> float:
    return min(start_pos.z,end_pos.z)

func max_x() -> float:
    return max(start_pos.x,end_pos.x)

func max_y() -> float:
    return max(start_pos.y,end_pos.y)

func max_z() -> float:
    return max(start_pos.z,end_pos.z)

func extend(other: BBox) -> void:
    # compute true mins/maxs for this and other
    var amin = Vector3(min(start_pos.x, end_pos.x),
                       min(start_pos.y, end_pos.y),
                       min(start_pos.z, end_pos.z))
    var amax = Vector3(max(start_pos.x, end_pos.x),
                       max(start_pos.y, end_pos.y),
                       max(start_pos.z, end_pos.z))
    var bmin = Vector3(min(other.start_pos.x, other.end_pos.x),
                       min(other.start_pos.y, other.end_pos.y),
                       min(other.start_pos.z, other.end_pos.z))
    var bmax = Vector3(max(other.start_pos.x, other.end_pos.x),
                       max(other.start_pos.y, other.end_pos.y),
                       max(other.start_pos.z, other.end_pos.z))
    # combine
    start_pos = Vector3(min(amin.x, bmin.x),
                        min(amin.y, bmin.y),
                        min(amin.z, bmin.z))
    end_pos   = Vector3(max(amax.x, bmax.x),
                        max(amax.y, bmax.y),
                        max(amax.z, bmax.z))

static func are_intersecting(a: BBox, b: BBox) -> bool:
    var amin = Vector3(min(a.start_pos.x, a.end_pos.x),
                       min(a.start_pos.y, a.end_pos.y),
                       min(a.start_pos.z, a.end_pos.z))
    var amax = Vector3(max(a.start_pos.x, a.end_pos.x),
                       max(a.start_pos.y, a.end_pos.y),
                       max(a.start_pos.z, a.end_pos.z))
    var bmin = Vector3(min(b.start_pos.x, b.end_pos.x),
                       min(b.start_pos.y, b.end_pos.y),
                       min(b.start_pos.z, b.end_pos.z))
    var bmax = Vector3(max(b.start_pos.x, b.end_pos.x),
                       max(b.start_pos.y, b.end_pos.y),
                       max(b.start_pos.z, b.end_pos.z))
    # overlap on all three axes?
    return amin.x <= bmax.x and bmin.x <= amax.x \
       and amin.y <= bmax.y and bmin.y <= amax.y \
       and amin.z <= bmax.z and bmin.z <= amax.z

static func intersect_volume(a: BBox, b: BBox) -> float:
    var amin = Vector3(min(a.start_pos.x, a.end_pos.x),
                       min(a.start_pos.y, a.end_pos.y),
                       min(a.start_pos.z, a.end_pos.z))
    var amax = Vector3(max(a.start_pos.x, a.end_pos.x),
                       max(a.start_pos.y, a.end_pos.y),
                       max(a.start_pos.z, a.end_pos.z))
    var bmin = Vector3(min(b.start_pos.x, b.end_pos.x),
                       min(b.start_pos.y, b.end_pos.y),
                       min(b.start_pos.z, b.end_pos.z))
    var bmax = Vector3(max(b.start_pos.x, b.end_pos.x),
                       max(b.start_pos.y, b.end_pos.y),
                       max(b.start_pos.z, b.end_pos.z))
    # compute per-axis overlap
    var dx = max(0.0, min(amax.x, bmax.x) - max(amin.x, bmin.x))
    var dy = max(0.0, min(amax.y, bmax.y) - max(amin.y, bmin.y))
    var dz = max(0.0, min(amax.z, bmax.z) - max(amin.z, bmin.z))
    return dx * dy * dz

static func _clamp_BBox(bbox:BBox, max_size:Vector3) -> BBox:
    var cl = BBox.new()
    cl.start_pos = bbox.start_pos
    var size = bbox.end_pos - bbox.start_pos
    size.x = min(size.x, max_size.x)
    size.y = min(size.y, max_size.y)
    size.z = min(size.z, max_size.z)
    cl.end_pos = cl.start_pos + size
    return cl