extends Node

var listening_thread: Thread
var polling_thread: Thread
var running = false
var mappings = {}

signal publish_new_data

var server: UDPServer = null
var peers = []

var data = []

func osc_to_array(packet: PackedByteArray):
	var args = packet.slice(packet.find(44), packet.size())
	var tags = args.get_string_from_ascii()
	var vals = []
	
	args = args.slice(ceili((tags.length() + 1) / 4.0) * 4, args.size())
	
	for tag in tags.to_ascii_buffer():
		match tag:
			44: #,: comma
				pass
			105: #i: int32
				var val = args.slice(0, 4)
				val.reverse()
				vals.append(val.decode_s32(0))
				args = args.slice(4, args.size())
			102: #f: float32
				var val = args.slice(0, 4)
				val.reverse()
				vals.append(val.decode_float(0))
				args = args.slice(4, args.size())
			115: #s: string
				var val = args.get_string_from_ascii()
				vals.append(val)
				args = args.slice(ceili((val.length() + 1) / 4.0) * 4, args.size())
			98:  #b: blob
				vals.append(args)
	
	return vals
	
	
# Extract data from VMC message
func parse_message(packet: PackedByteArray):
	var bundled_vals = []
	
	# Check if bundle
	if packet.slice(0,7).get_string_from_ascii() == "#bundle":
		var i = 16
		while i < packet.size():
			var n = packet.slice(i, i+4)
			n.reverse()
			n = n.decode_s32(0)
			i += 4
			bundled_vals.append(osc_to_array(packet.slice(i, i+n)))
			i += n
		
		return bundled_vals

	return [osc_to_array(packet)]

func _process(_delta):
	server.poll()
	if server.is_connection_available():
		peers.append(server.take_connection())
		
	for p in peers:
		for l in range(p.get_available_packet_count()):
			var packet = p.get_packet()
			var vals = parse_message(packet)
			
			for v in vals:
				if len(v) == 8:
					var pos = Vector3(v[1], v[2], -v[3])
					var quat = Quaternion(v[4], v[5], v[6], v[7])
					
					# Put bone specific conversions here.
					
					var eul = quat.get_euler()
					eul = Vector3(eul.z, eul.y, eul.x)
						
					quat = Quaternion.from_euler(eul)
					
					if mappings.has(v[0]):
						data.append({
							"Name": mappings[v[0]],
							"Position": pos, 
							"Rotation": quat
							})
					else:
						data.append({
							"Name": v[0],
							"Position": pos, 
							"Rotation": quat
							})
		
		emit_signal("publish_new_data", data)
		data = []
		
	
func _ready():
	var f = FileAccess.open("bone_mapping.json", FileAccess.READ)
	if f:
		mappings = JSON.parse_string(f.get_as_text())
	
	server = UDPServer.new()
	server.listen(39539)
