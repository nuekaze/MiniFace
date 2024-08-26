extends Control

var output = []
@onready var console = $VBoxContainer/Console

func _install_mediapipe():
	console.visible = true
	$VBoxContainer/HBoxContainer/Install.disabled = true
	$VBoxContainer/HBoxContainer/Skip.disabled = true
	if OS.get_name() == "Windows":
		console.add_text("> wget https://github.com/nuekaze/mediapipe-vt/archive/refs/heads/master.zip\n")
		await get_tree().create_timer(0.5).timeout 
		OS.execute("wget", ["https://github.com/nuekaze/mediapipe-vt/archive/refs/heads/master.zip"], output, true)
		console.add_text(output[0])
		output = []
		
		console.add_text("> tar -xf master.zip\n")
		await get_tree().create_timer(0.5).timeout 
		OS.execute("tar", ["-xf", "master.zip"], output)
		console.add_text(output[0])
		output = []
		
		console.add_text("> rm -f master.zip\n")
		await get_tree().create_timer(0.5).timeout 
		OS.execute("rm", ["-f", "master.zip"], output)
		console.add_text(output[0])
		output = []
		
		console.add_text("> mediapipe-vt-master/miniface-install.bat\n")
		await get_tree().create_timer(0.5).timeout 
		OS.execute("mediapipe-vt-master/miniface-install.bat", [], output)
		console.add_text(output[0])
		output = []
		
	else:
		console.add_text("> wget https://github.com/nuekaze/mediapipe-vt/archive/refs/heads/master.zip\n")
		await get_tree().create_timer(0.5).timeout 
		OS.execute("wget", ["https://github.com/nuekaze/mediapipe-vt/archive/refs/heads/master.zip"], output, true)
		console.add_text(output[0])
		output = []
		
		console.add_text("> unzip master.zip\n")
		await get_tree().create_timer(0.5).timeout 
		OS.execute("unzip", ["master.zip"], output)
		console.add_text(output[0])
		output = []
		
		console.add_text("> rm -f master.zip\n")
		await get_tree().create_timer(0.5).timeout 
		OS.execute("rm", ["-f", "master.zip"], output)
		console.add_text(output[0])
		output = []
		
		console.add_text("> mediapipe-vt-master/miniface-install.sh\nThis will take a while...\n")
		await get_tree().create_timer(0.5).timeout 
		OS.execute("mediapipe-vt-master/miniface-install.sh", [], output)
		console.add_text(output[0])
		output = []
	
	$VBoxContainer/Close.visible = true


func _close():
	self.queue_free()
