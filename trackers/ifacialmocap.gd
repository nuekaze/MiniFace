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
	server.listen(49983)
	
	while running:
		server.poll()
		if server.is_connection_available():
			var peer = server.take_connection()
			var packet = peer.get_packet()
			var d = packet.get_string_from_utf8()
			
			if d:
				d = d.split("|")
				for i in 52:
					var t = d[i+1].split("-")
					var key = t[0]
					var val = t[1]
					key = key.replace("_R", "Right").replace("_L", "Left")
					val = float(val) / 100.0

					data["Blendshapes"][key] = val

				var pos_rots = d[54].split('#')[1].split(',')
				data["Position"]['x'] = float(pos_rots[3])
				data["Position"]['y'] = float(pos_rots[4])
				data["Position"]['z'] = float(pos_rots[5])
				
				data["Rotation"]['x'] = deg_to_rad(float(pos_rots[0]))
				data["Rotation"]['y'] = deg_to_rad(float(pos_rots[1]))
				data["Rotation"]['z'] = deg_to_rad(float(pos_rots[2]))
				
				emit_signal("publish_new_data", data)
		
		# Sleep a bit to make sure we don't overdo it
		await get_tree().create_timer(0.02).timeout
	
func _ready():
	running = true
	listening_thread = Thread.new()
	listening_thread.start(_listening_thread.bind())
	client = PacketPeerUDP.new()
	
	
func start_poller(ip):
	client.connect_to_host(ip, 49983)
	$PollTimer.start(1.0)

func _exit_tree():
	running = false
	listening_thread.wait_to_finish()

func _on_poll():
	client.put_packet('iFacialMocap_sahuasouryya9218sauhuiayeta91555dy3719'.to_utf8_buffer())
