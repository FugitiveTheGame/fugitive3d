extends Control

onready var mapBackground := $Map as TextureRect

export(DynamicFont) var streetNameFont

const road_width := 20.0

var mapSize: Vector2
var mapStart: Vector2
var mapDrawn := false

onready var roads = GameData.currentMap.roads
var playerShape := PoolVector2Array()
const playerSize := 20.0
var playerOutlineShape := PoolVector2Array()
const playerOutlineSize := 23.0

var drawStreetNames := true

func _ready():
	var bb := GameData.currentMap.mapBoundingBox as AABB
	mapSize = Vector2(bb.size.x, bb.size.z)
	mapStart = Vector2(bb.position.x, bb.position.z)
	
	playerShape = _build_triangle(playerSize)
	playerOutlineShape = _build_triangle(playerOutlineSize)
	
	update_map_background()


func _build_triangle(triangle_size: float) -> PoolVector2Array:
	var half_size := triangle_size/2.0
	var new_points := PoolVector2Array()
	new_points.append(Vector2(-half_size, -half_size))
	new_points.append(Vector2(half_size, -half_size))
	new_points.append(Vector2(0.0, triangle_size))
	return new_points


func update_map_background():
	if mapBackground != null:
		var imageTexture = ImageTexture.new()
		var image = Image.new()
		
		var curSize := rect_size
		image.create(curSize.x, curSize.y, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.1, 0.9, 0.1, 0.5))
		imageTexture.create_from_image(image)
		mapBackground.texture = imageTexture
		
		mapBackground.update()


func _process(delta):
	if visible:
		update()


func to_map_scale(globalCoord: Vector3) -> Vector2:
	return Vector2(globalCoord.x, globalCoord.z) / mapSize


func to_map_coord(globalCoord: Vector3) -> Vector2:
	return to_map_coord_vector2(Vector2(globalCoord.x, globalCoord.z))


func to_map_coord_vector2(globalCoord: Vector2) -> Vector2:
	var correctedCoord := globalCoord
	# Translate to local
	correctedCoord -= mapStart
	# Shift so 0,0 is bottom left corner
	correctedCoord += (mapSize / 2.0)
	# Convert to percent inside local area
	var mapScale := correctedCoord / mapSize
	# Convert to 2d rect coord
	var mapCoord = (rect_size * mapScale)
	
	return mapCoord


func _on_Map_draw():
	# First draw the eblows
	var elbowRadius := floor(road_width/2.0) - 1.0 # -1 so the elbows don't peak past the roads
	for road in roads:
		for node in road.get_children():
			if node is Position3D:
				var pos = node.global_transform.origin
				var coord := to_map_coord(pos)
				mapBackground.draw_circle(coord, elbowRadius, Color.black)
	
	# Then draw the main roads
	for road in roads:
		var fromCoord = null
		for node in road.get_children():
			if node is Position3D:
				var pos = node.global_transform.origin
				if fromCoord == null:
					fromCoord = to_map_coord(pos)
				else:
					var toCoord := to_map_coord(pos)
					mapBackground.draw_line(fromCoord, toCoord, Color.black, road_width)
					fromCoord = toCoord
	
	# Then draw the road lines
	for road in roads:
		var fromCoord = null
		for node in road.get_children():
			if node is Position3D:
				var pos = node.global_transform.origin
				if fromCoord == null:
					fromCoord = to_map_coord(pos)
				else:
					var toCoord := to_map_coord(pos)
					mapBackground.draw_line(fromCoord, toCoord, Color.white, 1.0)
					fromCoord = toCoord
	
	# Now draw the win zones
	for zone in GameData.currentMap.get_win_zones():
		var pos = zone.global_transform.origin
		var coord := to_map_coord(pos)
		
		if zone.get_children().empty():
			print("ERROR: Winzone missing colission shape")
			continue
		
		var colShape = zone.get_node("CollisionShape")
		var colSize = colShape.shape.extents
		colSize *= 4.0 # I don't understand why this is 4... it should be 2.0...
		var colSizeMap := to_map_scale(colSize) * mapSize
		coord = coord - (colSizeMap / 2.0)
		var rect := Rect2(coord, colSizeMap)
		
		mapBackground.draw_rect(rect, Color(0.0, 0.0, 1.0, 0.75))
		
		var safeText := "Safe Zone"
		mapBackground.draw_set_transform(coord, 0.0, Vector2(1.0, 1.0))
		mapBackground.draw_string(streetNameFont, Vector2(), safeText)
		mapBackground.draw_set_transform(Vector2(), 0.0, Vector2(1.0, 1.0))
		
	
	# Finally draw road names
	if drawStreetNames:
		for road in roads:
			var namePos := to_map_coord(road.global_transform.origin)
			
			var textSize = streetNameFont.get_string_size(road.street_name)
			
			var rotation := 0.0
			if road.vertical:
				rotation = deg2rad(-90.0)
				#namePos -= Vector2(-textSize.y, -(textSize.x/2.0))
				namePos -= Vector2(0.0, -(textSize.x/2.0))
			else:
				namePos -= Vector2(textSize.x/2.0, -textSize.y)
			
			
			mapBackground.draw_set_transform(namePos, rotation, Vector2(1.0, 1.0))
			mapBackground.draw_string(streetNameFont, Vector2(), road.street_name)
			mapBackground.draw_set_transform(Vector2(), 0.0, Vector2(1.0, 1.0))


func _on_MapHud_resized():
	update_map_background()
