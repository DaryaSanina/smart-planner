import datetime

from ml_prediction import TaskImportancePredictor, KMeansTaskClassifier

ORDER_OPTIONS = ["Importance", "Deadline", "AI-Generated"]


class Task:
    def __init__(self, name: str, importance: float, deadline: datetime.date) -> None:
        assert len(name) <= 30
        self.name = name
        assert 0 <= importance <= 10
        self.importance = importance
        self.deadline = deadline
    
    def get_name(self) -> str:
        return self.name
    
    def get_importance(self) -> str:
        return self.importance
    
    def get_deadline_date(self) -> datetime.date:
        return self.deadline
    
    def get_deadline_str(self) -> str:
        return self.deadline.strftime("%d %b %Y")
    
    def set_predicted_importance(self, description: str) -> None:
        text = self.name + " " + description
        predictor = TaskImportancePredictor(text)
        self.importance = predictor.predict()


class TaskList:
    def __init__(self, tasks: list[Task]=[]) -> None:
        self.tasks = tasks
    
    def get_items(self) -> list[Task]:
        return self.tasks
    
    def append(self, task: Task):
        self.tasks.append(task)
    
    def remove(self, task: Task):
        self.tasks.remove(task)
    
    def sort(self, order: str):
        assert order in ORDER_OPTIONS
        if order == "Importance":
            self.tasks.sort(key=lambda task: task.get_importance(), reverse=True)
        elif order == "Deadline":
            self.tasks.sort(key=lambda task: task.deadline)
        elif order == "AI-Generated":
            data = [(task.get_importance(), (task.get_deadline_date() - datetime.date.today()).days) for task in self.tasks]
            classifier = KMeansTaskClassifier(data_list=data, k=4)
            classifier.generate_centroids()
            clusters, centroids = classifier.cluster()

            high_importance_clusters = list(sorted(list(range(4)), key=lambda x: centroids.data[int(x)][0], reverse=True))[:2]
            important_urgent_cluster = min(high_importance_clusters, key=lambda x: centroids.data[int(x)][1])
            important_not_urgent_cluster = max(high_importance_clusters, key=lambda x: centroids.data[int(x)][1])

            low_importance_clusters = list(sorted(list(range(4)), key=lambda x: centroids.data[int(x)][0], reverse=True))[2:]
            not_important_urgent_cluster = min(low_importance_clusters, key=lambda x: centroids.data[int(x)][1])
            not_important_not_urgent_cluster = max(low_importance_clusters, key=lambda x: centroids.data[int(x)][1])

            important_urgent_tasks = [self.tasks[i] for i in range(len(self.tasks)) if clusters.data[i] == important_urgent_cluster]
            important_not_urgent_tasks = [self.tasks[i] for i in range(len(self.tasks)) if clusters.data[i] == important_not_urgent_cluster]
            not_important_urgent_tasks = [self.tasks[i] for i in range(len(self.tasks)) if clusters.data[i] == not_important_urgent_cluster]
            not_important_not_urgent_tasks = [self.tasks[i] for i in range(len(self.tasks)) if clusters.data[i] == not_important_not_urgent_cluster]

            self.tasks = important_urgent_tasks + important_not_urgent_tasks + not_important_urgent_tasks + not_important_not_urgent_tasks

