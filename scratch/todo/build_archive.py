import json
import logging
import argparse

def parse_args():
    parser = argparse.ArgumentParser(description='Archive completed tasks from todo list')
    parser.add_argument('--suffix', type=str, default='',
                       help='Suffix to append to todo and archive filenames (e.g., "ae2" for todo_ae2.json)')
    return parser.parse_args()

def get_file_paths(suffix):
    if suffix:
        ongoing_task_file = f"./todo_{suffix}.json"
        archive_file = f"./todo_archive_{suffix}.json"
    else:
        ongoing_task_file = "./todo.json"
        archive_file = "./todo_archive.json"
    return ongoing_task_file, archive_file

def main():
    args = parse_args()
    ongoing_task_file, archive_file = get_file_paths(args.suffix)

    with open(ongoing_task_file, "r") as f:
        ongoing_tasks = json.load(f)

    with open(archive_file, "r") as f:
        archive = json.load(f)

    def get_completed_subtasks():
        completed_subtasks = []
        for task in ongoing_tasks["tasks"]:
            task_name = task["name"]
            for subtask in task["subtasks"]:
                if subtask["done"]:
                    completed_subtasks.append({
                        "task_name": task_name,
                        "subtask": subtask
                    })
        logging.warning(f"Found {len(completed_subtasks)} completed subtasks")
        return completed_subtasks

    def archive_completed_subtasks(completed_subtasks, archive):
        for item in completed_subtasks:
            task_name = item["task_name"]
            subtask = item["subtask"]
            
            # Find or create the task in archive
            task_found = False
            for archived_task in archive["tasks"]:
                if archived_task["name"] == task_name:
                    # Check if subtask already exists in archive
                    subtask_exists = False
                    for archived_subtask in archived_task["subtasks"]:
                        if archived_subtask["name"] == subtask["name"]:
                            subtask_exists = True
                            break
                    
                    if not subtask_exists:
                        archived_task["subtasks"].append(subtask)
                    task_found = True
                    break
            
            # If task not found in archive, create new task with the completed subtask
            if not task_found:
                archive["tasks"].append({
                    "name": task_name,
                    "subtasks": [subtask]
                })
        
        return archive

    def cleanup_ongoing_tasks(completed_subtasks):
        # Create a set of completed subtask names for quick lookup
        completed_subtask_names = {(item["task_name"], item["subtask"]["name"]) for item in completed_subtasks}
        
        # Process each task
        tasks_to_keep = []
        for task in ongoing_tasks["tasks"]:
            task_name = task["name"]
            subtasks_to_keep = []
            
            # Filter out completed subtasks
            for subtask in task["subtasks"]:
                if (task_name, subtask["name"]) not in completed_subtask_names:
                    subtasks_to_keep.append(subtask)
            
            # Only keep the task if it has remaining subtasks
            if subtasks_to_keep:
                task["subtasks"] = subtasks_to_keep
                tasks_to_keep.append(task)
        
        ongoing_tasks["tasks"] = tasks_to_keep
        return ongoing_tasks

    def write_archive(archive):
        with open(archive_file, "w") as f:
            json.dump(archive, f, indent=4)

    def write_ongoing_tasks(tasks):
        with open(ongoing_task_file, "w") as f:
            json.dump(tasks, f, indent=4)

    # Get completed subtasks
    completed_subtasks = get_completed_subtasks()
    
    # Archive completed subtasks
    archive_contents = archive_completed_subtasks(completed_subtasks, archive)
    write_archive(archive_contents)
    
    # Clean up ongoing tasks
    updated_ongoing_tasks = cleanup_ongoing_tasks(completed_subtasks)
    write_ongoing_tasks(updated_ongoing_tasks)

if __name__ == "__main__":
    main()
