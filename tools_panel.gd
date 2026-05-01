extends Panel

onready var brush_settings = $BrushSettings
onready var label_brush_size = brush_settings.get_node(@"LabelBrushSize")
onready var label_brush_shape = brush_settings.get_node(@"LabelBrushShape")
onready var label_stats = $LabelStats
onready var label_tools = $LabelTools

onready var _parent = get_parent()
onready var save_dialog = _parent.get_node(@"SaveFileDialog")
onready var paint_control = _parent.get_node(@"PaintControl")

func _ready():
	# Подключаем кнопки управления
	$ButtonUndo.connect("pressed", self, "button_pressed", ["undo_stroke"])
	$ButtonSave.connect("pressed", self, "button_pressed", ["save_picture"])
	$ButtonClear.connect("pressed", self, "button_pressed", ["clear_picture"])

	# Подключаем инструменты и выбор формы кисти
	$ButtonToolPencil.connect("pressed", self, "button_pressed", ["mode_pencil"])
	$ButtonToolEraser.connect("pressed", self, "button_pressed", ["mode_eraser"])
	$ButtonToolRectangle.connect("pressed", self, "button_pressed", ["mode_rectangle"])
	$ButtonToolCircle.connect("pressed", self, "button_pressed", ["mode_circle"])
	$BrushSettings/ButtonShapeBox.connect("pressed", self, "button_pressed", ["shape_rectangle"])
	$BrushSettings/ButtonShapeCircle.connect("pressed", self, "button_pressed", ["shape_circle"])

	# Настройки цвета и размера
	$ColorPickerBrush.connect("color_changed", self, "brush_color_changed")
	$ColorPickerBackground.connect("color_changed", self, "background_color_changed")
	$BrushSettings/HScrollBarBrushSize.connect("value_changed", self, "brush_size_changed")

	save_dialog.connect("file_selected", self, "save_file_selected")
	set_physics_process(true)

func _physics_process(_delta):
	# Обновляем счетчик объектов на холсте
	label_stats.text = "Объектов: " + String(paint_control.brush_data_list.size())

func button_pressed(button_name):
	var tool_name = null
	var shape_name = null

	match button_name:
		"mode_pencil":
			paint_control.brush_mode = paint_control.BrushModes.PENCIL
			brush_settings.modulate.a = 1.0
			tool_name = "Карандаш"
		"mode_eraser":
			paint_control.brush_mode = paint_control.BrushModes.ERASER
			brush_settings.modulate.a = 1.0
			tool_name = "Ластик"
		"mode_rectangle":
			paint_control.brush_mode = paint_control.BrushModes.RECTANGLE_SHAPE
			brush_settings.modulate.a = 0.5
			tool_name = "Прямоугольник"
		"mode_circle":
			paint_control.brush_mode = paint_control.BrushModes.CIRCLE_SHAPE
			brush_settings.modulate.a = 0.5
			tool_name = "Круг"
		"shape_rectangle":
			paint_control.brush_shape = paint_control.BrushShapes.RECTANGLE
			shape_name = "Квадрат"
		"shape_circle":
			paint_control.brush_shape = paint_control.BrushShapes.CIRCLE
			shape_name = "Круг"
		"clear_picture":
			paint_control.brush_data_list = []
			paint_control.update()
		"save_picture":
			save_dialog.popup_centered()
		"undo_stroke":
			paint_control.undo_stroke()

	# Обновляем текст в интерфейсе
	if tool_name:
		label_tools.text = "Инструмент: " + tool_name
	if shape_name:
		label_brush_shape.text = "Форма: " + shape_name

func brush_color_changed(color):
	paint_control.brush_color = color

func background_color_changed(color):
	_parent.get_node("DrawingAreaBG").modulate = color
	paint_control.bg_color = color
	paint_control.update() # Обновляем, так как ластик зависит от цвета фона

func brush_size_changed(value):
	paint_control.brush_size = ceil(value)
	label_brush_size.text = "Размер: " + String(ceil(value)) + "px"

func save_file_selected(path):
	paint_control.save_picture(path)
