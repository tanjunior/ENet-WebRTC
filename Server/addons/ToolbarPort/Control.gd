tool
extends CenterContainer

signal setting_changed
var edit

func _enter_tree():
	edit = $HBoxContainer/LineEdit

func _on_LineEdit_text_changed(new_text):
	emit_signal("setting_changed", new_text)
