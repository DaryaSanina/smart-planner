import datetime

ORDER_OPTIONS = ["importance", "deadline"]


class Task:
    def __init__(self, name: str, importance: float, deadline: datetime.date) -> None:
        assert len(name) <= 30
        self.name = name
        assert 0 <= importance <= 10
        self.importance = importance
        self.deadline = deadline
    
    def get_deadline(self) -> str:
        return self.deadline.strftime("%d %b %Y")


class TaskList:
    def __init__(self, tasks: list[Task]=[]) -> None:
        self.tasks = tasks
    
    def append(self, task: Task):
        self.tasks.append(task)
    
    def remove(self, task: Task):
        self.tasks.remove(task)
    
    def sort(self, order: str):
        assert order in ORDER_OPTIONS
        if order == "importance":
            self.tasks.sort(key=lambda task: task.importance, reverse=True)
        elif order == "deadline":
            self.tasks.sort(key=lambda task: task.deadline)
