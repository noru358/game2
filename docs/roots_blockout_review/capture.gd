extends SceneTree
var scene
func _initialize():
 call_deferred("review")
func review():
 scene = load("res://lab/roots_blockout.tscn").instantiate()
 root.add_child(scene)
 for i in range(30): await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("C:/Users/User/Documents/ChatGPT/게임 v2/docs/roots_blockout_review/entry.png")
 print("ENTRY ", scene.player.position, " floor=", scene.player.is_on_floor())
 scene.set_physics_process(false)
 scene.camera.size = 76
 scene.camera.position = Vector3(0,65,32)
 scene.camera.look_at(Vector3(0,0,-14))
 for i in range(5): await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("C:/Users/User/Documents/ChatGPT/게임 v2/docs/roots_blockout_review/overview.png")
 quit()
