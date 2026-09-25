extends SceneTree
var failures:=0
const Store=preload("res://game/save_store.gd")
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func run():
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	var writer=load("res://game/save_queue.gd").new()
	root.add_child(writer)
	var path:="user://queue_contract_%d.json"%OS.get_process_id()
	var data={"schema":2,"player":[1,0,2],"enemies":[],"kills":0}
	for i in range(20):
		data.kills=i
		writer.request(data,path)
	check(writer.writes==0,"combat tick performs no synchronous file writes")
	await process_frame
	data.kills=20
	writer.request(data,path)
	data.kills=999
	check(writer.flush()==OK,"exit flush waits for latest immutable snapshot")
	check(Store.read_data(path).kills==20,"latest queued progress survives reload")
	check(writer.writes<=2,"same tick kill snapshots coalesced")
	writer.request(data,"user://missing_parent_d106_%d/no_save.json"%OS.get_process_id())
	check(writer.flush()!=OK,"write failure reported to exit caller")
	data.kills=21
	writer.request(data,path)
	check(writer.flush()==OK and Store.read_data(path).kills==21,"retry recovers without losing progress")
	data.kills=22
	writer.request(data,path)
	writer.free()
	check(Store.read_data(path).kills==22,"scene exit flushes pending progress")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
