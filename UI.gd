extends PanelContainer



func _on_model_text_changed():
	if '.' in $VBoxContainer/Model/TextEdit.text:
		$VBoxContainer/Model/Button.disabled = false
	else:
		$VBoxContainer/Model/Button.disabled = true
