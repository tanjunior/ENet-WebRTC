tool
extends EditorPlugin

var toolbar
var remote_port_path = "custom_settings/remote_port"

func _enter_tree():
	toolbar = preload("res://addons/ToolbarPort/Control.tscn").instance()
	toolbar.connect("setting_changed", self, "_on_setting_changed")
	ProjectSettings.connect("script_changed", self, "_on_script_changed")
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar)
	
	if ProjectSettings.has_setting(remote_port_path):
		var port = ProjectSettings.get_setting(remote_port_path)
		get_editor_interface().get_editor_settings().set_setting("network/debug/remote_port", port)
	else:
		var port = get_editor_interface().get_editor_settings().get_setting("network/debug/remote_port")
		ProjectSettings.set_setting(remote_port_path, port)
		var property_info = {
			"name": "Remote Port",
			"type": TYPE_INT,
			"hint": 3,
			"hint_string": "property: custom_settings/remote_port"
		}
		ProjectSettings.add_property_info(property_info)
		ProjectSettings.save()
		
func _process(_delta):
	var port = ProjectSettings.get_setting(remote_port_path)
	if toolbar.edit.text != str(port):
		toolbar.edit.text = str(port)
		get_editor_interface().get_editor_settings().set_setting("network/debug/remote_port", port)

func _on_setting_changed(port: int):
	get_editor_interface().get_editor_settings().set_setting("network/debug/remote_port", port)
	ProjectSettings.set_setting(remote_port_path, port)

func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar)
	toolbar.queue_free()

