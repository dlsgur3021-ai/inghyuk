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
    sm.radius = 1.0
    sm.height = 2.0
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
            var rxa: float = float(a[3])
            var rza: float = float(a[4])
            var rxb: float = float(b[3])
            var rzb: float = float(b[4])
            var dh: float = max(.001,float(b[1])-float(a[1]))
            var drx: float = (rxb-rxa)/dh
            var drz: float = (rzb-rza)/dh
            for index in [0, 1, 2, 2, 1, 3]:
                var q: float = q0 if index <= 1 else q1
                var rx: float = rxa if index==0 or index==2 else rxb
                var rz: float = rza if index==0 or index==2 else rzb
                var normal := Vector3(cos(q)/max(.001,rx),
                    -drx*cos(q)*cos(q)/max(.001,rx)-drz*sin(q)*sin(q)/max(.001,rz),
                    sin(q)/max(.001,rz)).normalized()
                st.set_normal(normal)
                st.add_vertex(verts[index])
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

func head_form(parent: Node3D, skin: String) -> void:
    # Continuous sculpted head mesh; soft tapered jaw, no flat facial plates.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var rings := 42
    var slices := 64
    for i in range(rings):
        var a0: float = PI * float(i) / float(rings)
        var a1: float = PI * float(i+1) / float(rings)
        for j in range(slices):
            var b0: float = TAU * float(j) / float(slices)
            var b1: float = TAU * float(j+1) / float(slices)
            var v0 := head_point(a0,b0)
            var v1 := head_point(a1,b0)
            var v2 := head_point(a0,b1)
            var v3 := head_point(a1,b1)
            for v in [v0,v2,v1,v1,v2,v3]:
                st.add_vertex(v)
    st.generate_normals()
    mesh_node(parent,st.commit(),skin)

func head_point(theta: float, phi: float) -> Vector3:
    var yy: float = cos(theta)
    var jaw_t: float = 1.0-smoothstep(-.82,-.12,yy)
    var rx: float = .113*(1.0-.20*jaw_t)
    var rz: float = .101*(1.0-.065*jaw_t)
    var xx: float = sin(theta)*cos(phi)
    var zz: float = sin(theta)*sin(phi)
    var face_z: float = -.006-.012*jaw_t
    return Vector3(rx*xx,1.592+.151*yy,face_z+rz*zz)

func face(parent: Node3D, is_female: bool) -> void:
    var skin := "ecc2a5" if not is_female else "f0cdb6"
    var hair := "332824" if not is_female else "292528"
    var brow := "3b2b26"
    head_form(parent,skin)
    for side in [-1.0,1.0]:
        ellipsoid(parent,Vector3(side*.107,1.588,.001),Vector3(.013,.029,.015),skin)
        var ex: float=side*(.047 if not is_female else .049)
        # eyes partly embedded: no oversized protruding spheres
        ellipsoid(parent,Vector3(ex,1.626,-.098),Vector3(.025,.019,.009),"eee9df")
        ellipsoid(parent,Vector3(ex-side*.003,1.625,-.106),Vector3(.013,.015,.006),"6e4a32")
        ellipsoid(parent,Vector3(ex-side*.003,1.625,-.111),Vector3(.007,.010,.004),"211d1d")
        ellipsoid(parent,Vector3(ex-side*.008,1.632,-.115),Vector3(.004,.004,.002),"fefaf0")
        tube_line(parent,[Vector3(ex-side*.024,1.660,-.091),Vector3(ex,1.666,-.103),Vector3(ex+side*.026,1.660,-.086)],.0058,brow)
        ellipsoid(parent,Vector3(side*.081,1.579,-.076),Vector3(.020,.010,.009),"dcb39e")
    ellipsoid(parent,Vector3(0,1.603,-.103),Vector3(.016,.034,.019),skin)
    ellipsoid(parent,Vector3(0,1.581,-.121),Vector3(.022,.012,.018),skin)
    tube_line(parent,[Vector3(-.044,1.539,-.080),Vector3(-.030,1.528,-.099),Vector3(0,1.522,-.107),Vector3(.030,1.528,-.099),Vector3(.044,1.539,-.080)],.0035,"7e4c42")
    ellipsoid(parent,Vector3(0,1.524,-.108),Vector3(.026,.006,.003),"fff1e3")
    tube_line(parent,[Vector3(-.027,1.514,-.092),Vector3(0,1.510,-.102),Vector3(.027,1.514,-.092)],.0022,"be8376")
    # Layered small hair locks, not bowl-cut sphere
    ellipsoid(parent,Vector3(0,1.734,.022),Vector3(.110,.071,.109),hair)
    ellipsoid(parent,Vector3(-.061,1.740,-.014),Vector3(.055,.048,.099),hair,Vector3(0,0,-.13))
    ellipsoid(parent,Vector3(.055,1.735,.012),Vector3(.057,.048,.091),hair,Vector3(0,0,.17))
    for k in range(8):
        var xx: float=-.084+float(k)*.024
        var yy: float=1.709+sin(float(k)*1.8)*.012
        var zz: float=-.072+cos(float(k)*.83)*.009
        ellipsoid(parent,Vector3(xx,yy,zz),Vector3(.022,.024,.022),hair,Vector3(0,0,-.22+float(k)*.067))
    if is_female:
        ellipsoid(parent,Vector3(.094,1.671,.058),Vector3(.047,.053,.055),hair)
        ellipsoid(parent,Vector3(.133,1.592,.104),Vector3(.039,.086,.043),hair,Vector3(0,0,-.28))
        ellipsoid(parent,Vector3(.147,1.515,.107),Vector3(.033,.065,.035),hair,Vector3(0,0,-.28))

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
        [0,1.473,0,.049,.047],
        [0,1.486,0,.032,.039]
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
    env.ambient_light_energy=.30
    env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
    world.environment=env
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-52,-25,0)
    sun.light_energy=.37
    sun.shadow_enabled=true
    add_child(sun)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-28,140,0)
    fill.light_energy=.12
    add_child(fill)
    rounded_box(self,Vector3(0,-.070,0),Vector3(12,.12,12),"9dbdb0")
    person(.55,false)
    person(-.55,true)
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
