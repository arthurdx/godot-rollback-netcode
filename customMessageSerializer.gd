extends "res://addons/godot-rollback-netcode/MessageSerializer.gd"



const INPUT_PATH_MAPPING := {
	'/root/Main/ServerPlayer': 1,
	'/root/Main/ClientPlayer': 2,
} 

var input_path_mapping_reversed := {}


#flag to verify if the buffer has inputs or not
enum HEADER_FLAGS {
	HAS_INPUT_VECTOR = 0x01,
	DROP_BOMB = 0x02,
}

func _init():
	for key in INPUT_PATH_MAPPING:
		input_path_mapping_reversed[INPUT_PATH_MAPPING[key]] = key

func serialize_input(all_input: Dictionary) -> PackedByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(16)
	buffer.put_u32(all_input['$'])
	buffer.put_u8(all_input.size() - 1)
	for path in all_input:
		if path == "$":
			continue
		buffer.put_u8(INPUT_PATH_MAPPING[path])
		
		var header := 0
		
		var input = all_input[path]
		if input.has('input_vector'):
			header |= HEADER_FLAGS.HAS_INPUT_VECTOR
		if input.get('drop_bomb', false):
			header |= HEADER_FLAGS.DROP_BOMB
		
		buffer.put_u8(header)
		
		if input.has('input_vector'):
			var input_vector: Vector2 = input['input_vector']
			buffer.put_float(input_vector.x)
			buffer.put_float(input_vector.y)
			
		
		
			
	
	buffer.resize(buffer.get_position())
	return buffer.data_array

func unserialize_input(serialized: PackedByteArray) -> Dictionary:
	var buffer := StreamPeerBuffer.new()
	buffer.put_data(serialized)
	buffer.seek(0)
	
	var all_input = {}
	
	all_input['$'] = buffer.get_u32()
	
	var input_count = buffer.get_u8()
	
	if input_count == 0:
		return all_input
		
	var path = input_path_mapping_reversed[buffer.get_u8()]
	var input := {}
	var header = buffer.get_u8()
	# using & (ampersand) for bitwise and operation, since header flags
	#is a single bit value
	if header & HEADER_FLAGS.HAS_INPUT_VECTOR:
		input["input_vector"] = Vector2(buffer.get_float(), buffer.get_float())
	if header & HEADER_FLAGS.DROP_BOMB:
		input["drop_bomb"] = true
	
	all_input[path] = input
	
	return all_input

