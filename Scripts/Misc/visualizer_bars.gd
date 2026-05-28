extends Control

@export var audio_player: AudioStreamPlayer

@export var NUMBER_OF_BARS = 32 # number of frequency bands
@export var MAX_FREQUENCY = 1000 # frequency range
@export var bar_width = 8
@export var bar_separation = 2

var spectrum_instance
var bars = []

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
		var bar = ColorRect.new()
		bar.color = Color("32e332")
		bar.size = Vector2(bar_width, 50)
		bar.position = Vector2(i * (bar_width + bar_separation), 0)
		add_child(bar)
		bars.append(bar)

func _process(delta: float) -> void:
	if not spectrum_instance:
		return
	
	var max_freq_amp = bars.reduce(func(m, b): return b if b.size.y > m.size.y else m).size.y
	
	for i in range(NUMBER_OF_BARS):
		var freq_start = (i * MAX_FREQUENCY) / NUMBER_OF_BARS
		var freq_end = ((i + 1) * MAX_FREQUENCY) / NUMBER_OF_BARS
		var magnitude = spectrum_instance.get_magnitude_for_frequency_range(freq_start, freq_end).length()
		bars[i].size.y = lerp(bars[i].size.y, magnitude * MAX_FREQUENCY, 0.2) # smooth animation
		
		var intensity = (magnitude * 1000) / (max_freq_amp * 1000) if max_freq_amp > 0 else 0.0
		intensity *= 1000
		intensity = clamp(intensity, 0.0, 1.0)
		
		# set dynamic color from gradient
		var new_color = color_gradient.sample(intensity)
		bars[i].color = new_color
		if flip_y:
			bars[i].scale.y = -1
	
	if shuffle_frequeny:
		bars.shuffle()
