extends Control

@export var audio_player: AudioStreamPlayer

@export var NUMBER_OF_BARS: int = 32 # number of frequency bands
@export var MAX_FREQUENCY: float = 1000.0 # frequency range
@export var bar_width: float = 8
@export var bar_separation: float = 2

var spectrum_instance: AudioEffectInstance
var bars: Array = []

@export var shuffle_frequeny: bool = false
@export var flip_y: bool = false

var color_gradient: Gradient = Gradient.new()

func _ready() -> void:
	color_gradient.add_point(0.0, Color("32e332"))
	color_gradient.add_point(0.5, Color("61e978"))
	color_gradient.add_point(1.0, Color("97f1b0"))
	spectrum_instance = AudioServer.get_bus_effect_instance(AudioServer.get_bus_index("Music"), 0)
	create_bars()

func create_bars() -> void:
	for i in range(NUMBER_OF_BARS):
		var bar: ColorRect = ColorRect.new()
		bar.color = Color("32e332")
		bar.size = Vector2(bar_width, 50)
		bar.position = Vector2(i * (bar_width + bar_separation), 0)
		add_child(bar)
		bars.append(bar)

func _process(_delta: float) -> void:
	if not spectrum_instance:
		return
	
	var max_freq_amp: float = bars.reduce(func(m, b): return b if b.size.y > m.size.y else m).size.y
	
	for i in range(NUMBER_OF_BARS):
		var freq_start: float = (i * MAX_FREQUENCY) / NUMBER_OF_BARS
		var freq_end: float = ((i + 1) * MAX_FREQUENCY) / NUMBER_OF_BARS
		var magnitude: float = spectrum_instance.get_magnitude_for_frequency_range(freq_start, freq_end).length()
		bars[i].size.y = lerp(bars[i].size.y, magnitude * MAX_FREQUENCY, 0.2) # smooth animation
		
		var intensity: float = (magnitude * 1000) / (max_freq_amp * 1000) if max_freq_amp > 0 else 0.0
		intensity *= 1000
		intensity = clamp(intensity, 0.0, 1.0)
		
		# set dynamic color from gradient
		var new_color: Color = color_gradient.sample(intensity)
		bars[i].color = new_color
		if flip_y:
			bars[i].scale.y = -1
	
	if shuffle_frequeny:
		bars.shuffle()
