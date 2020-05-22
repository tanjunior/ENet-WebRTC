extends Webrtc


onready var button = $Button
onready var popup = $AcceptDialog

func _ready():
	self.connect("game_start", self, "_on_game_start")


func _on_game_start():
	button.disabled = false


func _on_Button_pressed():
	rpc("test")


func _on_Button2_pressed():
	leave()

remote func test():
	var caller_id = webrtc.get_rpc_sender_id()
	popup.dialog_text = "[%s] says hi" %[caller_id]
	popup.popup()
