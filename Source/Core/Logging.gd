# res://Source/Core/Logger.gd
extends Node
class_name Logging

# ─── Log levels ──────────────────────────────────────────────────────────────
enum Level { NONE, ERROR, WARN, INFO, DEBUG }

# change this in the Inspector or via code at startup
@export var level: int = Level.DEBUG

# ─── Internal ────────────────────────────────────────────────────────────────
func _should_log(msg_level: int) -> bool:
    if OS.is_debug_build():
        return msg_level <= level
    else:
        return false

# ─── Public API ──────────────────────────────────────────────────────────────
func debug(message: String) -> void:
    if not _should_log(Level.DEBUG):
        return
    print_debug("[%s] %s" % ["DEBUG", message])

func info(message: String) -> void:
    if not _should_log(Level.DEBUG):
        return
    print("[%s] %s" % ["INFO", message])

func warn(message: String) -> void:
    if not _should_log(Level.DEBUG):
        return
    push_warning("[%s] %s" % ["WARNING", message])

func error(message: String) -> void:
    if not _should_log(Level.DEBUG):
        return
    push_error("[%s] %s" % ["ERROR", message])
