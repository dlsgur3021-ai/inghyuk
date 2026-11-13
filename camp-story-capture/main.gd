extends Node3D

# Real runtime mesh scene. Cameras capture the same assets that run in Godot.
var cam: Camera3D
var ticks := 0
var male: Node3D
var female: Node3D
var mats: Dictionary = {}

func mat(hex: String, rough := 0.87) -> StandardMaterial3D:
    var key := hex + str(rough)
    if mats.has(key):
        return mats[key]
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(hex)
    m.roughness = rough
    mats[key] = m
    return m

func ball(parent: Node3D, pos: Vector3, scale3: Vector3, color: String, rotation3 := Vector3.ZERO) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radial_segments = 32
    sphere.rings = 20
    mi.mesh = sphere
    mi.material_override = mat(color)
    mi.position = pos
    mi.scale = scale3
    mi.rotation = rotation3
    parent.add_child(mi)
    return mi

func bar(parent: Node3D, a: Vector3, b: Vector3, low: float, high: float, color: String) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.bottom_radius = low
    cylinder.top_radius = high
    cylinder.height = a.distance_to(b)
    cylinder.radial_segments = 16
    mi.mesh = cylinder
    mi.material_override = mat(color)
    mi.position = (a + b) * 0.5
    mi.basis = Basis(Quaternion(Vector3.UP, (b-a).normalized()))
    parent.add_child(mi)
    return mi

func box(parent: Node3D, pos: Vector3, dims: Vector3, color: String) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = dims
    mi.mesh = mesh
    mi.material_override = mat(color)
    mi.position = pos
    parent.add_child(mi)
    return mi

func tiny_smile(parent: Node3D, female_style: bool) -> void:
    var points = [
        Vector3(-0.090, 2.345, 0.309),
        Vector3(-0.045, 2.328, 0.329),
        Vector3(0.000, 2.324, 0.335),
        Vector3(0.045, 2.328, 0.329),
        Vector3(0.090, 2.345, 0.309)
    ]
    for i in range(points.size()-1):
        bar(parent, points[i], points[i+1], 0.008, 0.008, "795d53" if not female_style else "91615d")

func build_face(parent: Node3D, is_female: bool) -> void:
    var skin := "e9bc9d" if is_female else "d7aa8f"
    var blush := "dfaaa0" if is_female else "c99483"
    var hair := "3e3030" if is_female else "392c28"
    var brow := "43332f"
    var face_width := 0.299 if is_female else 0.326
    # Head is a hand-tuned sculptural arrangement, not an anime texture.
    ball(parent, Vector3(0, 2.515, 0), Vector3(face_width, 0.393, 0.280), skin)
    ball(parent, Vector3(0, 2.340, 0.087), Vector3(face_width*0.80, 0.173, 0.210), skin)
    ball(parent, Vector3(0, 2.310, 0.120), Vector3(0.190, 0.089, 0.180), skin)
    for sx in [-1.0, 1.0]:
        ball(parent, Vector3(sx*face_width*0.95, 2.495, -0.005),
            Vector3(0.063, 0.099, 0.044), skin)
        # small, natural 3D eyes with sclera, iris and pupil
        var ex := sx*(0.126 if is_female else 0.138)
        ball(parent, Vector3(ex, 2.548, 0.258), Vector3(0.058, 0.047, 0.032), "eee4d7")
        ball(parent, Vector3(ex-sx*0.004, 2.548, 0.290), Vector3(0.029, 0.034, 0.017), "5c4332")
        ball(parent, Vector3(ex-sx*0.004, 2.548, 0.307), Vector3(0.016, 0.026, 0.009), "272321")
        ball(parent, Vector3(ex-sx*0.012, 2.558, 0.315), Vector3(0.007, 0.009, 0.004), "fff9e4")
        ball(parent, Vector3(ex, 2.640, 0.257),
            Vector3(0.089, 0.017, 0.021), brow, Vector3(0,0,sx*(0.09 if is_female else 0.13)))
        ball(parent, Vector3(sx*0.205,2.434,0.211), Vector3(0.069,0.036,0.025), blush)
    # Protruding nose with subtly curved bridge and rounded tip.
    ball(parent, Vector3(0,2.461,0.291),Vector3(0.049,0.085,0.078),skin)
    ball(parent, Vector3(0,2.433,0.350),Vector3(0.065,0.047,0.054),skin)
    tiny_smile(parent, is_female)
    # Built 3D hair volume and separate tapered locks.
    ball(parent, Vector3(0,2.789,-0.055),Vector3(face_width+0.033,0.214,0.308),hair)
    ball(parent, Vector3(-0.250,2.685,-0.090),Vector3(0.101,0.200,0.225),hair)
    ball(parent, Vector3(0.251,2.684,-0.080),Vector3(0.098,0.194,0.221),hair)
    if is_female:
        for k in range(5):
            var xp := -0.245 + k*0.103
            var yp := 2.777 - abs(k-2)*0.024
            ball(parent, Vector3(xp,yp,0.213),Vector3(0.078,0.105,0.078),hair,
                Vector3(0,0,-0.19+k*0.06))
        ball(parent, Vector3(0.215,2.807,-0.251),Vector3(0.103,0.100,0.111),hair)
        ball(parent, Vector3(0.286,2.580,-0.300),Vector3(0.092,0.282,0.120),hair,
            Vector3(0,0,-0.23))
        ball(parent, Vector3(0.305,2.386,-0.332),Vector3(0.077,0.189,0.106),hair,
            Vector3(0,0,-0.26))
    else:
        for k in range(5):
            var xp := -0.25 + k*0.125
            var yp := 2.789 - abs(k-1)*0.030
            ball(parent, Vector3(xp, yp,0.220),Vector3(0.092,0.089,0.091),hair,
                Vector3(0,0,-0.14 + k*0.13))
        ball(parent,Vector3(-0.230,2.767,0.043),Vector3(0.110,0.142,0.202),hair)

func create_character(xoffset: float, is_female: bool) -> Node3D:
    var character := Node3D.new()
    character.position.x = xoffset
    add_child(character)
    var cloth := "c4bbb1" if is_female else "a49d91"
    var cloth_dark := "b4a69a" if is_female else "918c83"
    var pants := "465260" if is_female else "2f3c4b"
    var shoes := "e0dbcd" if is_female else "d8d4c9"
    var skin := "e9bc9d" if is_female else "d7aa8f"
    var v := 0.96 if is_female else 1.0
    character.scale = Vector3(v, v, v)
    # neck / hood / adult-proportioned torso
    ball(character, Vector3(0,2.130,0),Vector3(0.092,0.160,0.097),skin)
    ball(character, Vector3(0,1.762,0.0), Vector3(0.391 if not is_female else 0.352,0.468,0.242),cloth)
    ball(character, Vector3(0,1.875,-0.120), Vector3(0.345,0.244,0.181),cloth_dark)
    ball(character,Vector3(0,2.072,0.023),Vector3(0.169,0.088,0.150),cloth_dark)
    bar(character,Vector3(0,1.995,0.228),Vector3(0,1.818,0.240),0.006,0.006,"e6d9c7")
    # front kangaroo pocket seam
    ball(character,Vector3(0,1.564,0.216),Vector3(0.226,0.140,0.022),cloth_dark)
    # arms: sleeves, cuffs, hands in relaxed natural placement
    for sx in [-1.0,1.0]:
        var shoulder := Vector3(sx*(0.374 if is_female else 0.411),1.987,0)
        var elbow := Vector3(sx*(0.438 if is_female else 0.477),1.529,0.026)
        var wrist := Vector3(sx*(0.449 if is_female else 0.491),1.267,0.075)
        ball(character,shoulder,Vector3(0.155,0.168,0.165),cloth)
        bar(character,shoulder,elbow,0.127,0.103,cloth)
        ball(character,elbow,Vector3(0.111,0.120,0.116),cloth)
        bar(character,elbow,wrist,0.103,0.091,cloth)
        ball(character,wrist,Vector3(0.105,0.062,0.106),cloth_dark)
        ball(character,wrist+Vector3(0,-0.116,0.016),Vector3(0.081,0.111,0.066),skin)
        for f in range(3):
            ball(character,wrist+Vector3(sx*(f*0.025-0.024),-0.202,0.032),
                Vector3(0.021,0.049,0.031),skin)
    # hips and legs
    ball(character,Vector3(0,1.300,0),Vector3(0.330 if is_female else 0.345,0.228,0.230),pants)
    for sx in [-1.0,1.0]:
        var hx := sx*0.180
        var knee := Vector3(sx*0.189,0.715,0.012)
        var ankle := Vector3(sx*0.199,0.197,-0.004)
        bar(character,Vector3(hx,1.307,0),knee,0.163,0.137,pants)
        ball(character,knee,Vector3(0.139,0.144,0.141),pants)
        bar(character,knee,ankle,0.130,0.099,pants)
        ball(character,Vector3(sx*0.201,0.204,0.014),Vector3(0.108,0.099,0.110),pants)
        ball(character,Vector3(sx*0.199,0.124,0.117),Vector3(0.136,0.091,0.240),shoes)
        box(character,Vector3(sx*0.199,0.054,0.130),Vector3(0.275,0.055,0.436),"ede9df")
    build_face(character,is_female)
    return character

func _ready() -> void:
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color("deded9")
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color("ffffff")
    e.ambient_light_energy = 0.74
    e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.environment = e
    add_child(env)
    var sunlight := DirectionalLight3D.new()
    sunlight.rotation_degrees = Vector3(-48,-40,0)
    sunlight.light_energy = 0.91
    sunlight.shadow_enabled = true
    add_child(sunlight)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-30,128,0)
    fill.light_energy=0.31
    add_child(fill)
    box(self,Vector3(0,-0.086,0),Vector3(30,0.13,30),"d3d3cb")
    male = create_character(-0.88,false)
    female = create_character(0.88,true)
    cam = Camera3D.new()
    cam.fov=48
    cam.position=Vector3(0,1.62,6.30)
    add_child(cam)
    cam.look_at(Vector3(0,1.52,0))
    cam.current = true

func _process(_delta: float) -> void:
    ticks += 1
    if ticks == 45:
        _snapshot("res://renders/camp_front.png")
    elif ticks == 58:
        cam.position = Vector3(2.30,1.70,6.20)
        cam.look_at(Vector3(0,1.50,0))
    elif ticks == 92:
        _snapshot("res://renders/camp_three_quarter.png")
    elif ticks == 112:
        get_tree().quit()

func _snapshot(path: String) -> void:
    await RenderingServer.frame_post_draw
    var img := get_viewport().get_texture().get_image()
    var result := img.save_png(path)
    print("CAPTURE: ", path, " status=", result)
