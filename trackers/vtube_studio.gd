extends Node

var listening_thread: Thread
var polling_thread: Thread
var running = false
var client: PacketPeerUDP

signal publish_new_data

var data = {
	"Position": {
		"x": 0.0,
		"y": 0.0,
		"z": 0.0
	},
	"Rotation": {
		"x": 0.0,
		"y": 0.0,
		"z": 0.0
	},
	"Blendshapes": {
		# ARKit shapes goes first.
		"browDownLeft": 0.0,
		"browDownRight": 0.0,
		"browInnerUp": 0.0,
		"browOuterUpLeft": 0.0,
		"browOuterUpRight": 0.0,
		"cheekPuff": 0.0,
		"cheekSquintLeft": 0.0,
		"cheekSquintRight": 0.0,
		"eyeBlinkLeft": 0.0,
		"eyeBlinkRight": 0.0,
		"eyeLookDownLeft": 0.0,
		"eyeLookDownRight": 0.0,
		"eyeLookInLeft": 0.0,
		"eyeLookInRight": 0.0,
		"eyeLookOutLeft": 0.0,
		"eyeLookOutRight": 0.0,
		"eyeLookUpLeft": 0.0,
		"eyeLookUpRight": 0.0,
		"eyeSquintLeft": 0.0,
		"eyeSquintRight": 0.0,
		"eyeWideLeft": 0.0,
		"eyeWideRight": 0.0,
		"jawForward": 0.0,
		"jawLeft": 0.0,
		"jawOpen": 0.0,
		"jawRight": 0.0,
		"mouthClose": 0.0,
		"mouthDimpleLeft": 0.0,
		"mouthDimpleRight": 0.0,
		"mouthFrownLeft": 0.0,
		"mouthFrownRight": 0.0,
		"mouthFunnel": 0.0,
		"mouthLeft": 0.0,
		"mouthLowerDownLeft": 0.0,
		"mouthLowerDownRight": 0.0,
		"mouthPressLeft": 0.0,
		"mouthPressRight": 0.0,
		"mouthPucker": 0.0,
		"mouthRight": 0.0,
		"mouthRollLower": 0.0,
		"mouthRollUpper": 0.0,
		"mouthShrugLower": 0.0,
		"mouthShrugUpper": 0.0,
		"mouthSmileLeft": 0.0,
		"mouthSmileRight": 0.0,
		"mouthStretchLeft": 0.0,
		"mouthStretchRight": 0.0,
		"mouthUpperUpLeft": 0.0,
		"mouthUpperUpRight": 0.0,
		"noseSneerLeft": 0.0,
		"noseSneerRight": 0.0,
		"tongueOut": 0.0,
		# Vowels for OpenSeeFace
		"a": 0.0,
		"i": 0.0,
		"u": 0.0,
		"e": 0.0,
		"o": 0.0,
		"blink": 0.0,
		"blinkLeft": 0.0,
		"blinkRight": 0.0
	}
}				

func _listening_thread():
	var server := UDPServer.new()
	server.listen(50506)
	
	while running:
		server.poll()
		if server.is_connection_available():
			var peer = server.take_connection()
			var packet = peer.get_packet()

			var json = JSON.new()
			if json.parse(packet.get_string_from_utf8()) == OK:
				data["Position"]["x"] = -json.data["Position"]["x"] / 100
				data["Position"]["y"] = json.data["Position"]["y"] / 100
				data["Position"]["z"] = json.data["Position"]["z"] / 100
				
				data["Rotation"]["x"] = deg_to_rad(json.data["Rotation"]["y"])
				data["Rotation"]["y"] = deg_to_rad(json.data["Rotation"]["x"])
				data["Rotation"]["z"] = deg_to_rad(json.data["Rotation"]["z"])
				
				for s in json.data["BlendShapes"]:
					s["k"][0] = s["k"][0].to_lower() # I use lowercase first letter in my model
					data["Blendshapes"][s["k"]] = s["v"]
				
				emit_signal("publish_new_data", data)
		
		# Sleep a bit to make sure we don't overdo it
		await get_tree().create_timer(0.02).timeout
	
func _ready():
	running = true
	listening_thread = Thread.new()
	listening_thread.start(_listening_thread.bind())
	client = PacketPeerUDP.new()
	
	
func start_poller(ip):
	client.connect_to_host(ip, 21412)
	$PollTimer.start(1.0)

func _exit_tree():
	running = false
	listening_thread.wait_to_finish()

func _on_poll():
	client.put_packet('{"messageType": "iOSTrackingDataRequest", "sentBy": "Godot", "sendForSeconds": 10, "ports": [50506]}'.to_utf8_buffer())
