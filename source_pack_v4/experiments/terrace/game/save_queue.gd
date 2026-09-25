extends Node
## Single writer. Coalesce combat snapshots; explicit exits wait for the latest one.
signal completed(error: int)
const Store=preload("res://game/save_store.gd")
var worker:=Thread.new()
var pending:Dictionary={}
var pending_path:=""
var last_error:int=OK
var writes:=0
func _ready():process_mode=Node.PROCESS_MODE_ALWAYS
func request(data:Dictionary,path:String):
	pending=data.duplicate(true)
	pending_path=path
	# Requests in one physics tick form one durable snapshot.
func _process(_delta:float):
	if worker.is_started():
		if worker.is_alive():return
		finish()
	if not pending.is_empty():
		var data:=pending
		var path:=pending_path
		pending={}
		var error:=worker.start(func():return Store.write(data,path))
		if error!=OK:
			pending=data
			last_error=error
			completed.emit(error)
func finish():
	last_error=int(worker.wait_to_finish())
	writes+=1
	completed.emit(last_error)
func flush() -> int:
	if worker.is_started():finish()
	if not pending.is_empty():
		last_error=Store.write(pending,pending_path)
		writes+=1
		pending={}
		completed.emit(last_error)
	return last_error
func _exit_tree():flush()
