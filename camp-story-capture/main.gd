extends Node3D

# The proportions below are reconstructed from the original Camp Story human sheet.
# No sphere-bodied replacement characters. Only the face uses the supplied Western-animation reference.
var camera: Camera3D
var frame_idx := 0
var palette: Dictionary = {}

func material(hex: String, spec: float = .14) -> StandardMaterial3D:
    var key := hex + "/" + str(spec)
    if palette.has(key):
        return palette[key]
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(hex)
    m.metallic = 0.0
    m.roughness = .90 - spec * .35
    palette[key] = m
    return m

func mesh_node(parent: Node3D, mesh: Mesh, color: String) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = material(color)
    parent.add_child(mi)
    return mi

func ellipsoid(parent: Node3D, p: Vector3, radii: Vector3, color: String, angle: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var sm := SphereMesh.new()
    sm.radial_segments = 32
    sm.rings = 20
    var mi := mesh_node(parent, sm, color)
    mi.position = p
    mi.scale = radii
    mi.rotation = angle
    return mi

func tube(parent: Node3D, path: Array, color: String, sides: int = 28) -> MeshInstance3D:
    # Each section: [center_x, center_y, center_z, radius_x, radius_z]
    var rings: Array = path.duplicate(true)
    if float(rings[0][1]) > float(rings[rings.size()-1][1]):
        rings.reverse()
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for k in range(rings.size() - 1):
        var a: Array = rings[k]
        var b: Array = rings[k + 1]
        for i in range(sides):
            var q0 := TAU * float(i) / sides
            var q1 := TAU * float(i + 1) / sides
            var verts: Array[Vector3] = [
                Vector3(float(a[0]) + cos(q0)*float(a[3]), float(a[1]), float(a[2])+sin(q0)*float(a[4])),
                Vector3(float(b[0]) + cos(q0)*float(b[3]), float(b[1]), float(b[2])+sin(q0)*float(b[4])),
                Vector3(float(a[0]) + cos(q1)*float(a[3]), float(a[1]), float(a[2])+sin(q1)*float(a[4])),
                Vector3(float(b[0]) + cos(q1)*float(b[3]), float(b[1]), float(b[2])+sin(q1)*float(b[4]))
            ]
            for index in [0, 1, 2, 2, 1, 3]:
                st.add_vertex(verts[index])
    st.generate_normals()
    return mesh_node(parent, st.commit(), color)

func tube_line(parent: Node3D, points: Array[Vector3], radius: float, color: String) -> void:
    for i in range(points.size() - 1):
        var first := points[i]
        var second := points[i+1]
        var v := second - first
        var c := CylinderMesh.new()
        c.top_radius = radius
        c.bottom_radius = radius
        c.height = v.length()
        c.radial_segments = 10
        var mi := mesh_node(parent, c, color)
        mi.position = (first+second)*.5
        mi.quaternion = Quaternion(Vector3.UP, v.normalized())
        ellipsoid(parent,second,Vector3(radius,radius,radius),color)

func rounded_box(parent: Node3D, at: Vector3, dim: Vector3, color: String) -> void:
    var m := BoxMesh.new()
    m.size=dim
    var mi := mesh_node(parent,m,color)
    mi.position=at

func face(parent: Node3D, is_female: bool) -> void:
    var skin := "efc4a5" if not is_female else "f1cab3"
    var skin_shadow := "d6a18b" if not is_female else "e4b09d"
    var hair := "262223"
    var eyebrow := "3a2c27"
    var eye_white := "f8f2e9"
    var iris := "795638" if not is_female else "654b38"
    var face_w := .111 if not is_female else .105
    # Long continuous sculpted mesh. Crown is wider than jaw, jaw converges softly.
    tube(parent,[
        [0,1.445,0.006,.019,.016],
        [0,1.466,0,.055,.053],
        [0,1.493,0,.085,.080],
        [0,1.540,0,.105,.097],
        [0,1.589,0,face_w,.104],
        [0,1.636,0,face_w,.105],
        [0,1.681,.002,.103,.094],
        [0,1.714,.012,.083,.070],
        [0,1.736,.014,.050,.041],
        [0,1.744,.015,.012,.010]
    ],skin,36)
    # Soft cheeks, connected visually with head; fine visible ears and jaw definition.
    for side in [-1.0,1.0]:
        ellipsoid(parent,Vector3(side*face_w*.92,1.591,.005),
            Vector3(.021,.042,.022),skin)
        var eye_x: float=side*.051
        # Forward is -Z for the current orthographic camera.
        ellipsoid(parent,Vector3(eye_x,1.624,-.102),
            Vector3(.029,.020,.006),eye_white)
        ellipsoid(parent,Vector3(eye_x-side*.002,1.624,-.109),
            Vector3(.014,.016,.004),iris)
        ellipsoid(parent,Vector3(eye_x-side*.003,1.624,-.114),
            Vector3(.008,.010,.003),"251d1a")
        ellipsoid(parent,Vector3(eye_x-side*.007,1.631,-.117),
            Vector3(.004,.004,.002),"ffffff")
        # Strong brows from Western character reference; no anime eyeliner.
        tube_line(parent,[
            Vector3(eye_x-side*.025,1.659,-.092),
            Vector3(eye_x,1.664,-.102),
            Vector3(eye_x+side*.025,1.657,-.089)
        ],.006,eyebrow)
        ellipsoid(parent,Vector3(side*.085,1.555,-.066),
            Vector3(.010,.009,.008),skin_shadow)
    # Rounded bridge and nose tip, thin under lip instead of a huge pasted mouth.
    ellipsoid(parent,Vector3(0,1.594,-.107),
        Vector3(.016,.033,.016),skin)
    ellipsoid(parent,Vector3(0,1.573,-.120),
        Vector3(.027,.016,.023),skin)
    tube_line(parent,[
        Vector3(-.046,1.526,-.083),
        Vector3(-.030,1.516,-.101),
        Vector3(0,1.510,-.106),
        Vector3(.030,1.516,-.101),
        Vector3(.046,1.526,-.083)
    ],.0038,"835047")
    # Very small natural smile teeth, not a big cartoon mouth
    ellipsoid(parent,Vector3(0,1.516,-.110),
        Vector3(.019,.004,.002),"fff5ec")
    tube_line(parent,[
        Vector3(-.022,1.506,-.100),
        Vector3(0,1.503,-.106),
        Vector3(.022,1.506,-.100)
    ],.0021,"cc8f7e")
    # Existing hairstyle remains short black for man; ponytail for woman.
    tube(parent,[
        [0,1.689,.017,.086,.076],
        [0,1.716,.014,.105,.105],
        [0,1.749,.012,.107,.108],
        [0,1.768,.010,.086,.094],
        [0,1.780,.008,.040,.049]
    ],hair,36)
    # angled fringe, organic locks embedded in scalp
    for i in range(7):
        var tx: float=-.080+i*.026
        var yy: float=1.703+sin(float(i)*1.6)*.011
        ellipsoid(parent,Vector3(tx,yy,-.085),
            Vector3(.028,.015,.024),hair,Vector3(0,0,-.22+i*.07))
    if is_female:
        # tied low ponytail, hanging behind right shoulder
        ellipsoid(parent,Vector3(.079,1.677,.094),
            Vector3(.038,.042,.039),hair)
        tube(parent,[
            [.086,1.688,.118,.026,.029],
            [.091,1.622,.136,.041,.032],
            [.104,1.530,.145,.040,.032],
            [.108,1.452,.149,.029,.026],
            [.110,1.419,.150,.009,.010]
        ],hair,20)

func person(offset: float, is_female: bool) -> Node3D:
    var root := Node3D.new()
    root.position.x=offset
    root.scale=Vector3(.93,.93,.93) if is_female else Vector3.ONE
    add_child(root)
    var shirt := "a9c0ad" if is_female else "f0ede6"
    var shirt_shadow := "93ac99" if is_female else "d9d7cf"
    var pant := "4b586d" if is_female else "4c5b4e"
    var pant_seam := "647184" if is_female else "5c6c5c"
    var skin := "f1cab3" if is_female else "efc4a5"
    var sock := "f4f2e9"
    # continuous loose T-shirt, exact soft half-sleeve look from original render
    tube(root,[
        [0,.958,0,.183,.109],
        [0,.982,0,.197,.121],
        [0,1.050,0,.203,.127],
        [0,1.163,0,.196,.124],
        [0,1.295,0,.187,.108],
        [0,1.342,0,.208,.103],
        [0,1.366,0,.174,.096],
        [0,1.381,0,.092,.079]
    ],shirt)
    # neck exposed from collar to head
    tube(root,[
        [0,1.364,0,.055,.052],
        [0,1.407,0,.054,.051],
        [0,1.473,0,.049,.047]
    ],skin)
    for side in [-1.0,1.0]:
        var x: float=side*.222
        tube(root,[
            [side*.228,1.350,0,.086,.106],
            [side*.237,1.320,0,.093,.111],
            [side*.250,1.245,0,.085,.102],
            [side*.255,1.210,0,.081,.096]
        ],shirt,24)
        tube(root,[
            [side*.257,1.206,0,.068,.065],
            [side*.265,1.124,.003,.064,.063],
            [side*.282,1.020,.003,.053,.056],
            [side*.292,.936,.008,.043,.045],
            [side*.298,.892,.012,.035,.038]
        ],skin,24)
        # simplified small hands with finger detail
        ellipsoid(root,Vector3(side*.301,.858,.016),
            Vector3(.030,.045,.033),skin)
        for fi in range(3):
            ellipsoid(root,Vector3(side*(.281+fi*.015),.825,-.002),
                Vector3(.006,.030,.006),skin)
    # Straight waistband and baggy jogger-style trouser legs: no ball joints.
    tube(root,[
        [0,.914,0,.208,.138],
        [0,.949,0,.216,.135],
        [0,.979,0,.210,.129]
    ],pant,30)
    for side in [-1.0,1.0]:
        var x: float=side*.109
        tube(root,[
            [x,.936,0,.118,.135],
            [side*.114,.877,0,.126,.139],
            [side*.119,.749,.003,.136,.146],
            [side*.120,.620,.008,.139,.145],
            [side*.123,.463,.010,.134,.141],
            [side*.125,.301,.014,.127,.133],
            [side*.128,.199,.011,.120,.123],
            [side*.129,.152,.009,.096,.108]
        ],pant,30)
        # cuff narrow hem and visible white sock
        tube(root,[
            [side*.130,.157,.005,.093,.101],
            [side*.132,.131,.006,.092,.101]
        ],pant_seam,30)
        tube(root,[
            [side*.132,.130,.006,.059,.070],
            [side*.132,.075,.011,.060,.070]
        ],sock,24)
        # egg-shaped canvas sneaker and sole, very close to original illustration
        ellipsoid(root,Vector3(side*.134,.068,-.055),
            Vector3(.087,.060,.155),"dad9d1")
        ellipsoid(root,Vector3(side*.133,.028,-.063),
            Vector3(.098,.020,.165),"fafaf5")
    # drawstrings and flat seam
    tube_line(root,[Vector3(-.026,.972,-.128),Vector3(-.028,.922,-.144)],.0035,"e1e0d4")
    tube_line(root,[Vector3(.026,.972,-.128),Vector3(.025,.914,-.144)],.0035,"e1e0d4")
    face(root,is_female)
    return root

func _ready() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("d3d2cf")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("ffffff")
    env.ambient_light_energy=.66
    env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
    world.environment=env
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-52,-25,0)
    sun.light_energy=.58
    sun.shadow_enabled=true
    add_child(sun)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-28,140,0)
    fill.light_energy=.20
    add_child(fill)
    rounded_box(self,Vector3(0,-.070,0),Vector3(12,.12,12),"9dbdb0")
    person(-.55,false)
    person(.55,true)
    camera=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=2.13
    camera.position=Vector3(0,.95,-4.0)
    add_child(camera)
    camera.look_at(Vector3(0,.94,0))
    camera.current=true

func _process(_delta: float) -> void:
    frame_idx+=1
    if frame_idx == 40:
        capture("res://renders/camp_front.png")
    if frame_idx == 58:
        camera.position=Vector3(1.50,1.12,-4.0)
        camera.look_at(Vector3(0,.96,0))
    if frame_idx == 96:
        capture("res://renders/camp_three_quarter.png")
    if frame_idx == 120:
        get_tree().quit()

func capture(where: String) -> void:
    await RenderingServer.frame_post_draw
    var img=get_viewport().get_texture().get_image()
    var err=img.save_png(where)
    print("CAPTURED ",where," ",err)
