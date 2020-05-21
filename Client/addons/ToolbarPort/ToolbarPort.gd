tool
extends EditorPlugin

var control

func _enter_tree():
	control = preload("res://addons/ToolbarPort/Control.tscn").instance()
	control.connect("setting_changed", self, "_on_setting_changed")
	
	var current_port = get_editor_interface().get_editor_settings().get_setting("network/debug/remote_port")
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, control)
	control.edit.text = str(current_port)


func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, control)
	control.queue_free()


func _on_setting_changed(port):
	get_editor_interface().get_editor_settings().set_setting("network/debug/remote_port", int(port))
