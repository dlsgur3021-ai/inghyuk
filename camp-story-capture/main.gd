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


# Variant A: charming compact human character with a deliberately oversized head.
# Distinct real Godot mesh, not an illustration.
func island_camper(at_x: float) -> void:
    var r := Node3D.new()
    r.position.x = at_x
    add_child(r)
    var cream := "ecc5a2"
    var parka := "a9bd96"
    var dark := "52655c"
    # Little rounded shoes and compact trousers
    for side in [-1.0,1.0]:
        var x: float = side*.128
        tube(r,[
            [x,.16,0,.100,.105],
            [x,.33,0,.112,.113],
            [x,.51,0,.125,.123],
            [x,.71,0,.117,.121]
        ],"677b73",28)
        ellipsoid(r,Vector3(x,.093,-.078),Vector3(.122,.082,.177),"d2bc9e")
        ellipsoid(r,Vector3(x,.037,-.091),Vector3(.127,.026,.185),"f8f1e4")
    # Body and smooth jacket sleeve shoulder transitions
    tube(r,[
        [0,.64,0,.205,.133],
        [0,.75,0,.228,.137],
        [0,.88,0,.232,.144],
        [0,1.03,0,.225,.147],
        [0,1.11,0,.188,.133],
        [0,1.17,0,.120,.085]
    ],parka,32)
    tube_line(r,[Vector3(0,.67,-.144),Vector3(0,1.075,-.14)],.0075,"e5d2ae")
    for side in [-1.0,1.0]:
        var sx: float = side
        tube(r,[
            [sx*.31,.78,.003,.087,.095],
            [sx*.32,.91,.004,.105,.104],
            [sx*.30,1.045,.004,.124,.105],
            [sx*.22,1.12,.003,.100,.096]
        ],parka,26)
        ellipsoid(r,Vector3(sx*.310,.748,-.004),Vector3(.072,.054,.077),"92a88b")
        ellipsoid(r,Vector3(sx*.316,.688,-.007),Vector3(.063,.094,.068),cream)
        # jetted side pockets
        tube_line(r,[Vector3(sx*.118,.805,-.146),Vector3(sx*.20,.795,-.131)],.006,"77896d")
    ellipsoid(r,Vector3(0,1.172,0),Vector3(.074,.079,.070),cream)
    # Head shaped as a large compact sculpt, short chin and pronounced cheeks
    ellipsoid(r,Vector3(0,1.475,0),Vector3(.249,.257,.224),cream)
    ellipsoid(r,Vector3(0,1.337,-.042),Vector3(.145,.077,.138),cream)
    for side in [-1.0,1.0]:
        var eye_x: float=side*.109
        ellipsoid(r,Vector3(side*.236,1.477,-.002),Vector3(.047,.064,.032),cream)
        ellipsoid(r,Vector3(eye_x,1.485,-.203),Vector3(.046,.051,.016),"fcf9ef")
        ellipsoid(r,Vector3(eye_x-side*.009,1.479,-.225),Vector3(.024,.030,.009),"493d33")
        ellipsoid(r,Vector3(eye_x-side*.012,1.480,-.234),Vector3(.012,.018,.006),"211e1d")
        ellipsoid(r,Vector3(eye_x-side*.019,1.499,-.241),Vector3(.008,.010,.005),"ffffff")
        tube_line(r,[Vector3(eye_x-side*.035,1.591,-.186),Vector3(eye_x+side*.026,1.593,-.186)],.008,"49362b")
    ellipsoid(r,Vector3(0,1.401,-.219),Vector3(.028,.025,.037),cream)
    tube_line(r,[Vector3(-.053,1.337,-.168),Vector3(0,1.325,-.195),Vector3(.053,1.337,-.168)],.005,"805047")
    # Thick swept hair cap with three thick locks
    ellipsoid(r,Vector3(0,1.688,.018),Vector3(.246,.116,.231),"4b332a")
    for n in range(5):
        var tx: float=-.169+float(n)*.083
        ellipsoid(r,Vector3(tx,1.635,-.175+abs(float(n-2))*.014),
            Vector3(.055,.052,.048),"4b332a",Vector3(0,0,(float(n)-2.)*.16))
    # Simple boots and color-coded neck scarf
    ellipsoid(r,Vector3(0,1.126,-.064),Vector3(.113,.028,.047),"e2c8a4")

# Variant B: full-height adult styled male, soft game-feasible fleece/zip jacket
func adult_camper(at_x: float) -> void:
    var r: Node3D = person(at_x,false)
    var coat := "c9b8a0"
    var coat_edge := "a99880"
    # Layer shell over retained slimmer body, gently tapering to waist
    tube(r,[
        [0,.974,0,.202,.135],
        [0,1.050,0,.207,.137],
        [0,1.215,0,.209,.139],
        [0,1.33,0,.229,.138],
        [0,1.362,0,.164,.123]
    ],coat,36)
    # Entire sleeves connect under shoulders; no detached shoulder balls
    for side in [-1.0,1.0]:
        var sx: float=side
        tube(r,[
            [sx*.294,1.000,0,.066,.075],
            [sx*.294,1.10,0,.078,.085],
            [sx*.285,1.215,0,.082,.092],
            [sx*.265,1.32,0,.088,.094],
            [sx*.204,1.345,0,.079,.083]
        ],coat,30)
        tube(r,[
            [sx*.295,.987,0,.071,.075],
            [sx*.294,1.025,0,.071,.076]
        ],coat_edge,26)
        # bag side pocket seam, kept subtle
        tube_line(r,[Vector3(sx*.112,1.083,-.130),Vector3(sx*.188,1.081,-.113)],.004,"a0907a")
    tube_line(r,[Vector3(0,.989,-.138),Vector3(0,1.325,-.139)],.0045,"816b58")
    ellipsoid(r,Vector3(0,1.286,-.141),Vector3(.011,.011,.008),"8b806e")
    # Tightening waistline continuity, no bulging separate hip sphere
    tube(r,[
        [0,.894,0,.206,.130],
        [0,.951,0,.209,.134],
        [0,.989,0,.198,.134]
    ],"69735c",32)
    # understated collar
    ellipsoid(r,Vector3(-.075,1.379,-.060),Vector3(.069,.042,.052),coat)
    ellipsoid(r,Vector3(.075,1.379,-.060),Vector3(.069,.042,.052),coat)
    # Eyeglasses tracing actual face contours (front of original eyes).
    for side in [-1.0,1.0]:
        var x: float=side*.048
        var outline: Array[Vector3]=[
            Vector3(x-.044,1.644,-.131),
            Vector3(x-.042,1.608,-.131),
            Vector3(x-.025,1.593,-.132),
            Vector3(x+.025,1.593,-.132),
            Vector3(x+.042,1.608,-.131),
            Vector3(x+.044,1.644,-.131),
            Vector3(x+.025,1.660,-.131),
            Vector3(x-.025,1.660,-.131),
            Vector3(x-.044,1.644,-.131)
        ]
        tube_line(r,outline,.0045,"54463f")
        tube_line(r,[Vector3(side*.090,1.637,-.128),Vector3(side*.127,1.633,-.060)],.0045,"54463f")
    tube_line(r,[Vector3(-.008,1.641,-.132),Vector3(.008,1.641,-.132)],.004,"54463f")
    # Shoes slightly fuller with sole contrast
    for side in [-1.0,1.0]:
        ellipsoid(r,Vector3(side*.133,.066,-.091),Vector3(.101,.058,.142),"797768")
        ellipsoid(r,Vector3(side*.133,.022,-.099),Vector3(.107,.017,.153),"ddd3c1")


# CAMP STORY v0.1: two compact stylized 3D campers.
# True procedural Godot meshes, deliberately stylized, not source artwork.
func camp_kid(at_x: float, female: bool) -> Node3D:
    var root := Node3D.new()
    root.position.x = at_x
    add_child(root)
    var skin := "edc49f" if not female else "f3ccb0"
    var jacket := "a5ae83" if not female else "f1ddc4"
    var jacket_dark := "818a65" if not female else "d5b69c"
    var pocket := "d3b996" if not female else "dfa79a"
    var pants := "666853" if not female else "94816b"
    var shoes := "7b5d47" if not female else "b19a82"
    var hair := "49352f" if not female else "59433b"
    var hat := "c7ab87" if not female else "e6c9a5"
    # Both characters have the same short, sturdy friendly proportions.
    for side in [-1.0,1.0]:
        var sx: float = side
        var lx: float = side*.126
        tube(root, [
            [lx,.145,0,.083,.088],
            [lx,.202,0,.102,.098],
            [lx,.38,0,.108,.106],
            [lx,.52,0,.113,.114],
            [lx,.632,0,.112,.116]
        ], pants, 28)
        # high-top ankle boots and soft oval toes
        ellipsoid(root,Vector3(lx,.158,-.010),Vector3(.106,.12,.113),shoes)
        ellipsoid(root,Vector3(lx,.092,-.081),Vector3(.118,.088,.149),shoes)
        ellipsoid(root,Vector3(lx,.036,-.087),Vector3(.124,.025,.159),"dfd3bc")
        tube_line(root,[
            Vector3(lx-.039,.172,-.114),
            Vector3(lx+.041,.172,-.114)
        ],.0055,"dfc9a9")
    # Covered, smooth jacket body; the filled mesh hides the backpack from frontal view.
    ellipsoid(root,Vector3(0,.835,.007),Vector3(.240,.281,.153),jacket)
    ellipsoid(root,Vector3(0,.630,.006),Vector3(.224,.065,.145),jacket)
    # soft hem is narrow; it does not form a bulbous hip.
    tube_line(root,[Vector3(-.183,.609,-.084),Vector3(-.10,.592,-.128),Vector3(0,.591,-.145),Vector3(.10,.592,-.128),Vector3(.183,.609,-.084)],.0045,jacket_dark)
    # collar seam and centered, straight zip
    tube_line(root,[Vector3(0,.613,-.155),Vector3(0,1.053,-.147)],.006,"eee2cb")
    tube_line(root,[Vector3(.012,.636,-.156),Vector3(.012,1.044,-.148)],.0028,"957e66")
    ellipsoid(root,Vector3(0,1.045,-.151),Vector3(.010,.014,.006),"8c765f")
    # Front panels and stitched pockets
    for side in [-1.0,1.0]:
        var sx: float=side
        # Soft sloping shoulder, tapering to fitted cuff rather than floating cylinders.
        ellipsoid(root,Vector3(sx*.239,.982,.010),Vector3(.110,.128,.107),jacket,Vector3(0,0,-sx*.17))
        ellipsoid(root,Vector3(sx*.316,.845,.012),Vector3(.089,.183,.088),jacket,Vector3(0,0,sx*.055))
        ellipsoid(root,Vector3(sx*.339,.720,.013),Vector3(.079,.035,.085),jacket_dark)
        ellipsoid(root,Vector3(sx*.336,.662,.008),Vector3(.066,.081,.069),skin)
        # simple thumb from glove cuff, deliberately only 2 hand details
        ellipsoid(root,Vector3(sx*.272,.666,-.042),Vector3(.031,.051,.029),skin)
        rounded_box(root,Vector3(sx*.118,.764,-.150),Vector3(.103,.087,.010),pocket)
        tube_line(root,[Vector3(sx*.070,.812,-.159),Vector3(sx*.169,.812,-.159)],.0038,jacket_dark)
        tube_line(root,[Vector3(sx*.096,1.011,-.150),Vector3(sx*.159,1.011,-.150)],.0035,pocket)
    # neck, raised soft collar, beige hoodie inside
    tube(root,[[0,1.083,0,.081,.079],[0,1.330,0,.080,.079]],skin,24)
    ellipsoid(root,Vector3(-.062,1.113,-.056),Vector3(.068,.039,.060),jacket_dark)
    ellipsoid(root,Vector3(.062,1.113,-.056),Vector3(.068,.039,.060),jacket_dark)
    # Large egg-shaped head with subtle cheek and chin taper
    ellipsoid(root,Vector3(0,1.510,.004),Vector3(.246,.260,.218),skin)
    ellipsoid(root,Vector3(0,1.381,-.022),Vector3(.176,.109,.184),skin)
    # tidy side ears partly tucked behind hair and hat
    for side in [-1.0,1.0]:
        var sx: float=side
        ellipsoid(root,Vector3(sx*.243,1.480,.010),Vector3(.043,.063,.030),skin)
        ellipsoid(root,Vector3(sx*.248,1.480,-.010),Vector3(.018,.033,.009),"dba98d")
        # flat cartoon eyes, slightly inset rather than protruding eyeballs
        var ex: float=sx*.105
        ellipsoid(root,Vector3(ex,1.496,-.210),Vector3(.033,.051,.012),"302823")
        ellipsoid(root,Vector3(ex-.009,1.514,-.222),Vector3(.010,.015,.005),"fff6e9")
        tube_line(root,[Vector3(ex-sx*.028,1.581,-.189),Vector3(ex+sx*.022,1.581,-.189)],.005,hair)
        # round peach cheeks
        ellipsoid(root,Vector3(sx*.160,1.407,-.189),Vector3(.047,.025,.008),"eaa88c" if not female else "e9a19a")
    ellipsoid(root,Vector3(0,1.439,-.228),Vector3(.014,.010,.009),"d9a28c")
    tube_line(root,[Vector3(-.037,1.385,-.208),Vector3(0,1.368,-.222),Vector3(.037,1.385,-.208)],.0037,"a26354")
    # hair cap, visible below hat
    ellipsoid(root,Vector3(0,1.691,.025),Vector3(.243,.093,.220),hair)
    for k in range(5):
        var xx: float = -.173+float(k)*.084
        ellipsoid(root,Vector3(xx,1.656,-.174),Vector3(.055,.066,.052),hair,Vector3(0,0,.11*float(k-2)))
    if female:
        # Short soft bob, not separate spherical pigtails.
        for side in [-1.0,1.0]:
            var sx: float=side
            ellipsoid(root,Vector3(sx*.199,1.452,.051),Vector3(.062,.122,.111),hair,Vector3(0,0,sx*.13))
            ellipsoid(root,Vector3(sx*.196,1.391,.061),Vector3(.066,.051,.094),hair)
    else:
        ellipsoid(root,Vector3(-.154,1.658,-.083),Vector3(.073,.078,.088),hair)
        ellipsoid(root,Vector3(.151,1.659,-.090),Vector3(.068,.071,.075),hair)
    # The brim is a separate low silhouette curved cap for a controllable game asset.
    var crown := CylinderMesh.new()
    crown.top_radius = .218
    crown.bottom_radius = .248
    crown.height = .132
    crown.radial_segments = 40
    var crown_mesh := mesh_node(root,crown,hat)
    crown_mesh.position = Vector3(0,1.725,.026)
    ellipsoid(root,Vector3(0,1.797,.025),Vector3(.212,.035,.210),hat)
    var brim := CylinderMesh.new()
    brim.top_radius = .250
    brim.bottom_radius = .284
    brim.height = .051
    brim.radial_segments = 40
    var brim_mesh := mesh_node(root,brim,hat)
    brim_mesh.position = Vector3(0,1.660,-.020)
    rounded_box(root,Vector3(0,1.730,-.217),Vector3(.087,.041,.014),"947f64")
    # tiny mountain badge on cap
    tube_line(root,[Vector3(-.031,1.725,-.227),Vector3(-.002,1.743,-.230),Vector3(.027,1.725,-.227)],.006,"f1eadd")
    # shoulder straps and backpack, modeled behind upper torso.
    for side in [-1.0,1.0]:
        var sx: float=side
        tube_line(root,[Vector3(sx*.168,1.062,-.116),Vector3(sx*.182,.902,-.145),Vector3(sx*.159,.777,-.131)],.010,"887460")
    rounded_box(root,Vector3(0,.872,.287),Vector3(.349,.376,.166),"78694e" if not female else "947b5f")
    rounded_box(root,Vector3(0,.960,.390),Vector3(.301,.078,.031),"5d513d" if not female else "79614e")
    # rolled ground mat on top of the backpack
    var bedroll := CylinderMesh.new()
    bedroll.top_radius=.062
    bedroll.bottom_radius=.062
    bedroll.height=.35
    bedroll.radial_segments=22
    var bed := mesh_node(root,bedroll,"65725d")
    bed.position=Vector3(0,1.128,.355)
    bed.rotation_degrees.z=90
    return root

func _ready() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("e9e8e3")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("ffffff")
    env.ambient_light_energy=.59
    env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
    world.environment=env
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-52,-25,0)
    sun.light_energy=.68
    sun.shadow_enabled=true
    add_child(sun)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-28,140,0)
    fill.light_energy=.29
    add_child(fill)
    rounded_box(self,Vector3(0,-.070,0),Vector3(12,.12,12),"c6d7c9")
    camp_kid(-.66,false)
    camp_kid(.66,true)
    camera=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=2.20
    camera.position=Vector3(0,.95,-4.0)
    add_child(camera)
    camera.look_at(Vector3(0,.94,0))
    camera.current=true

func _process(_delta: float) -> void:
    frame_idx+=1
    if frame_idx == 40:
        capture("res://renders/camp_front.png")
    if frame_idx == 58:
        camera.position=Vector3(2.5,1.18,-3.4)
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
