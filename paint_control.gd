extends Control

const UNDO_MODE_SHAPE = -2
const UNDO_NONE = -1
const IMAGE_SIZE = Vector2(930, 720) # Размер холста

enum BrushModes { PENCIL, ERASER, CIRCLE_SHAPE, RECTANGLE_SHAPE }
enum BrushShapes { RECTANGLE, CIRCLE }

var TL_node # Узел для определения границ холста
var brush_data_list = [] # Список всех мазков

var is_mouse_in_drawing_area = false
var last_mouse_pos = Vector2()
var mouse_click_start_pos = null

var undo_set = false
var undo_element_list_num = -1

var brush_mode = BrushModes.PENCIL
var brush_size = 32
var brush_color = Color.black
var brush_shape = BrushShapes.CIRCLE
var bg_color = Color.white

func _ready():
	TL_node = get_node("TLPos")
	set_process(true)

func _process(_delta):
	var mouse_pos = get_viewport().get_mouse_position()

	# Проверка, в границах ли холста мышка
	is_mouse_in_drawing_area = false
	if mouse_pos.x > TL_node.global_position.x and mouse_pos.y > TL_node.global_position.y:
		is_mouse_in_drawing_area = true

	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		if mouse_click_start_pos == null:
			mouse_click_start_pos = mouse_pos

		if check_if_mouse_is_inside_canvas():
			if mouse_pos.distance_to(last_mouse_pos) >= 1:
				if brush_mode == BrushModes.PENCIL or brush_mode == BrushModes.ERASER:
					if not undo_set:
						undo_set = true
						undo_element_list_num = brush_data_list.size()
					add_brush(mouse_pos, brush_mode)
	else:
		undo_set = false
		if check_if_mouse_is_inside_canvas():
			if brush_mode == BrushModes.CIRCLE_SHAPE or brush_mode == BrushModes.RECTANGLE_SHAPE:
				add_brush(mouse_pos, brush_mode)
				undo_element_list_num = UNDO_MODE_SHAPE
		mouse_click_start_pos = null

	last_mouse_pos = mouse_pos

func check_if_mouse_is_inside_canvas():
	if mouse_click_start_pos != null:
		# Проверяем, что начали клик внутри холста, чтобы не рисовать при выборе цвета
		if mouse_click_start_pos.x > TL_node.global_position.x and mouse_click_start_pos.y > TL_node.global_position.y:
			return is_mouse_in_drawing_area
	return false

func undo_stroke():
	if undo_element_list_num == UNDO_NONE:
		return

	if undo_element_list_num == UNDO_MODE_SHAPE:
		if brush_data_list.size() > 0:
			brush_data_list.remove(brush_data_list.size() - 1)
	else:
		# Удаляем весь последний мазок карандаша или ластика
		var elements_to_remove = brush_data_list.size() - undo_element_list_num
		for i in range(elements_to_remove):
			brush_data_list.pop_back()

	undo_element_list_num = UNDO_NONE
	update()

func add_brush(mouse_pos, type):
	var new_brush = {
		"brush_type": type,
		"brush_pos": mouse_pos,
		"brush_shape": brush_shape,
		"brush_size": brush_size,
		"brush_color": brush_color
	}

	if type == BrushModes.RECTANGLE_SHAPE:
		var TL_pos = Vector2(min(mouse_pos.x, mouse_click_start_pos.x), min(mouse_pos.y, mouse_click_start_pos.y))
		var BR_pos = Vector2(max(mouse_pos.x, mouse_click_start_pos.x), max(mouse_pos.y, mouse_click_start_pos.y))
		new_brush.brush_pos = TL_pos
		new_brush.brush_shape_rect_pos_BR = BR_pos

	if type == BrushModes.CIRCLE_SHAPE:
		var center_pos = (mouse_pos + mouse_click_start_pos) / 2
		new_brush.brush_pos = center_pos
		new_brush.brush_shape_circle_radius = center_pos.distance_to(Vector2(center_pos.x, mouse_pos.y))

	brush_data_list.append(new_brush)
	update()

func _draw():
	for brush in brush_data_list:
		match brush.brush_type:
			BrushModes.PENCIL:
				draw_brush_item(brush, brush.brush_color)
			BrushModes.ERASER:
				draw_brush_item(brush, bg_color)
			BrushModes.RECTANGLE_SHAPE:
				var rect = Rect2(brush.brush_pos, brush.brush_shape_rect_pos_BR - brush.brush_pos)
				draw_rect(rect, brush.brush_color)
			BrushModes.CIRCLE_SHAPE:
				draw_circle(brush.brush_pos, brush.brush_shape_circle_radius, brush.brush_color)

# Вынес отрисовку мазка в отдельную функцию, чтобы не дублировать код для ластика
func draw_brush_item(brush, color):
	if brush.brush_shape == BrushShapes.RECTANGLE:
		var rect = Rect2(brush.brush_pos - Vector2(brush.brush_size/2, brush.brush_size/2), Vector2(brush.brush_size, brush.brush_size))
		draw_rect(rect, color)
	else:
		draw_circle(brush.brush_pos, brush.brush_size / 2, color)

func save_picture(path):
	yield(VisualServer, "frame_post_draw")
	var img = get_viewport().get_texture().get_data()
	var cropped_image = img.get_rect(Rect2(TL_node.global_position, IMAGE_SIZE))
	cropped_image.flip_y()
	cropped_image.save_png(path)
