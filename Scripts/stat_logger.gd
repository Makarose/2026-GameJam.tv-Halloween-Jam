extends Node

var timer := 0.0

func _process(delta: float) -> void:
	timer += delta
	if timer < 1.0:
		return
	timer = 0.0

	var fps := Performance.get_monitor(Performance.TIME_FPS)
	var frame_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var draw_calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var objects := Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	var primitives := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var vram := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0

	print("FPS: %d | Process: %.2f ms | Draw calls: %d | Objects: %d | Primitives: %d | Nodes: %d | VRAM: %.1f MB" % [fps, frame_ms, draw_calls, objects, primitives, nodes, vram])
