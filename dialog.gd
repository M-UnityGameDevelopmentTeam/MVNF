class_name StoryPanel

extends Panel

signal proceed(type: String)
@export var NextButton: Button
@export var BackButton: Button
@export var ExitButton: Button
@export var ChoiceButton: PackedScene
@export var ChoicePanel: Panel
@export var ChoiceContainer: BoxContainer
@export var DialogPanel: Panel
@export var text: RichTextLabel
@export var character_name_text: RichTextLabel
@export var text_speed := 0.1
@export var StoryJSON: JSON
var current_text_speed: float 
var current_phrases: Array[Dictionary]
var current_index: int
var phrase: Dictionary
var running := true
var is_busy: bool
var temp_choice_button: Button
func _ready() -> void:
	NextButton.pressed.connect(next)
	BackButton.pressed.connect(back)
	ExitButton.pressed.connect(exit)
	current_text_speed = text_speed
	current_phrases.append(StoryJSON.data.phrases[0])
	await show_phrase()
	exit()

func show_phrase() -> bool:
	while running:
		if current_phrases[current_index].has("type"):
			phrase = current_phrases[current_index]
		match phrase.type:
			"text":
				await handle_phrase()
			"choice":
				await handle_choice()
		await proceed
	return true

func handle_choice() -> bool:
	character_name_text.text = phrase.name
	ChoiceContainer.mouse_filter = Control.MOUSE_FILTER_STOP
	await create_tween().tween_property(DialogPanel, "modulate:a", 0, 0.25).finished
	for choice in ChoiceContainer.get_children():
		choice.queue_free()
	for i in phrase.choices:
		temp_choice_button = ChoiceButton.instantiate()
		ChoiceContainer.add_child(temp_choice_button)
		temp_choice_button.text = i;
		temp_choice_button.pressed.connect(Callable(self, "next").bind(phrase.choices[i]))
	await create_tween().tween_property(ChoicePanel, "modulate:a", 1, 0.25).finished
	return true

func handle_phrase() -> bool:
	character_name_text.text = phrase.name
	text.visible_characters = 0
	text.text = phrase.text
	if phrase.has("font_size"):
		text.set(&"theme_override_font_sizes/bold_italics_font_size", phrase.font_size)
		text.set(&"theme_override_font_sizes/italics_font_size", phrase.font_size)
		text.set(&"theme_override_font_sizes/mono_font_size", phrase.font_size)
		text.set(&"theme_override_font_sizes/normal_font_size", phrase.font_size)
		text.set(&"theme_override_font_sizes/bold_font_size", phrase.font_size)
	else: 
		text.do_resize_text()
	is_busy = true
	while not text.visible_characters == len(phrase.text):
		text.visible_characters += 1
		if is_busy:
			await get_tree().create_timer(current_text_speed).timeout
		else:
			text.visible_ratio = 1
			break
	is_busy = false
	return true

func exit() -> void:
	get_tree().quit()
	proceed.emit()

func back() -> void:
	is_busy = false
	if current_phrases.size() == 1:
		return
	current_phrases.remove_at(current_index)
	current_index -= 1
	proceed.emit()

func next(next_index: int = -1) -> void:
	if is_busy:
		is_busy = false
		return
	if next_index != -1:
		ChoiceContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		current_text_speed = text_speed
		current_phrases.resize(next_index+1)
		current_phrases.insert(next_index, StoryJSON.data.phrases[next_index])
		print(current_phrases[next_index].next)
		current_index = next_index
		create_tween().tween_property(ChoicePanel, "modulate:a", 0, 0.25)
		await create_tween().tween_property(DialogPanel, "modulate:a", 1, 0.25).finished
		for choice in ChoiceContainer.get_children():
			choice.queue_free()
	elif phrase.has("next"):
		current_text_speed = text_speed
		current_phrases.append(StoryJSON.data.phrases[int(phrase.next)])
		current_index = phrase.next
	else:
		running = false
	proceed.emit()
	
