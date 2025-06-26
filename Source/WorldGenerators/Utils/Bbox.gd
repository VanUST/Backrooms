# res://Source/WorldGenerators/Utils/Bbox.gd
extends RefCounted
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

# Clamp this BBox so it lies entirely within `other`.
func clamp(other: BBox) -> void:
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

    var new_start = Vector3(
        max(amin.x, bmin.x),
        max(amin.y, bmin.y),
        max(amin.z, bmin.z)
    )
    var new_end = Vector3(
        min(amax.x, bmax.x),
        min(amax.y, bmax.y),
        min(amax.z, bmax.z)
    )

    # Ensure no inverted dimensions
    if new_end.x < new_start.x:
        new_end.x = new_start.x
    if new_end.y < new_start.y:
        new_end.y = new_start.y
    if new_end.z < new_start.z:
        new_end.z = new_start.z

    start_pos = new_start
    end_pos   = new_end

# Helper: carve `block` out of `avail`, but preserve `must_contain` entirely.
# We choose the best single‐axis cut (smallest resulting volume loss).
static func shrink_around(avail: BBox, block: BBox, must_contain: BBox) -> void:
    # Compute 6 candidates: move each face of avail inwards to just outside block
    var candidates := []
    var faces = [
        {"axis":"x","dir":1}, {"axis":"x","dir":-1},
        {"axis":"y","dir":1}, {"axis":"y","dir":-1},
        {"axis":"z","dir":1}, {"axis":"z","dir":-1},
    ]
    for f in faces:
        var c = BBox.new(avail.start_pos, avail.end_pos)
        var a_min = Vector3(c.min_x(), c.min_y(), c.min_z())
        var a_max = Vector3(c.max_x(), c.max_y(), c.max_z())
        var b_min = Vector3(block.min_x(), block.min_y(), block.min_z())
        var b_max = Vector3(block.max_x(), block.max_y(), block.max_z())
        var m_min = Vector3(must_contain.min_x(), must_contain.min_y(), must_contain.min_z())
        var m_max = Vector3(must_contain.max_x(), must_contain.max_y(), must_contain.max_z())
        match f["axis"]:
            "x":
                if f["dir"] > 0 and b_min.x <= a_max.x:
                    # push the max X face in to just before block.min_x
                    var new_max_x = min(a_max.x, b_min.x)
                    # but ensure we still include connector
                    if new_max_x >= m_max.x:
                        c.end_pos.x = new_max_x
                    else:
                        continue
                elif f["dir"] < 0 and b_max.x >= a_min.x:
                    var new_min_x = max(a_min.x, b_max.x)
                    if new_min_x <= m_min.x:
                        c.start_pos.x = new_min_x
                    else:
                        continue
            "y":
                if f["dir"] > 0 and b_min.y <= a_max.y:
                    var new_max_y = min(a_max.y, b_min.y)
                    if new_max_y >= m_max.y:
                        c.end_pos.y = new_max_y
                    else:
                        continue
                elif f["dir"] < 0 and b_max.y >= a_min.y:
                    var new_min_y = max(a_min.y, b_max.y)
                    if new_min_y <= m_min.y:
                        c.start_pos.y = new_min_y
                    else:
                        continue
            "z":
                if f["dir"] > 0 and b_min.z <= a_max.z:
                    var new_max_z = min(a_max.z, b_min.z)
                    if new_max_z >= m_max.z:
                        c.end_pos.z = new_max_z
                    else:
                        continue
                elif f["dir"] < 0 and b_max.z >= a_min.z:
                    var new_min_z = max(a_min.z, b_max.z)
                    if new_min_z <= m_min.z:
                        c.start_pos.z = new_min_z
                    else:
                        continue
        # reject any inverted dims
        if c.width() > 0 and c.height() > 0 and c.depth() > 0:
            candidates.append(c)
    # pick the candidate with the largest volume (to lose the least)
    if candidates.size() > 0:
        var best = candidates[0]
        var best_vol = best.width() * best.height() * best.depth()
        for cand in candidates:
            var v = cand.width() * cand.height() * cand.depth()
            if v > best_vol:
                best_vol = v
                best = cand
        # commit
        avail.start_pos = best.start_pos
        avail.end_pos   = best.end_pos