import json
import logging
ongoing_task_file = "./todo.json"
archive_file = "./todo_archive.json"

with open(ongoing_task_file, "r") as f:
    ongoing_tasks = json.load(f)

with open(archive_file, "r") as f:
    archive = json.load(f)

def get_completed_tasks():
    completed_tasks = []
    for task in ongoing_tasks["tasks"]:
        completed = 0
        for subtask in task["subtasks"]:
            if subtask["done"]:
                completed += 1
        logging.warning(f"Task {task['name']} has {completed} of {len(task['subtasks'])} subtasks completed")
        if completed >= len(task["subtasks"]):
            completed_tasks.append({
                "name": task["name"],
                "subtasks": task["subtasks"]
            })
    logging.warning(f"Found {len(completed_tasks)} completed tasks")
    return completed_tasks

def archive_completed_tasks(completed_tasks, archive):
    for task in completed_tasks:
        # If goal exists in archive, check if tasks need updating
        found = False
        for archived_task in archive["tasks"]:
            if archived_task["name"] == task["name"]:
                archived_task["subtasks"] = task["subtasks"]
                found = True
                break
        
        # If goal not found in archive, add it
        if not found:
            archive["tasks"].append(task)
    
    return archive

def write_archive(archive):
    with open(archive_file, "w") as f:
        json.dump(archive, f, indent=4)

if __name__ == "__main__":
    completed_tasks = get_completed_tasks()
    archive_contents = archive_completed_tasks(completed_tasks, archive)
    write_archive(archive_contents)
