class_name AsyncTaskQueue
extends Node

signal all_completed
signal all_complted_of_one_task_name(task_name: String)

var _active_tasks: Dictionary = {}

func add_task_ref(task_name: String) -> void:
    if not _active_tasks.has(task_name):
        _active_tasks[task_name] = 0
    _active_tasks[task_name] += 1

func release_task_ref(task_name: String) -> void:
    if not _active_tasks.has(task_name):
        push_error("You don't have any tasks with " + task_name)
        return
    
    _active_tasks[task_name] -= 1
    if _active_tasks[task_name] <= 0:
        _active_tasks.erase(task_name)

    if _active_tasks.is_empty():
        all_completed.emit()

func is_finished() -> bool:
    return _active_tasks.is_empty()
