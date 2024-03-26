import datetime

from ml_prediction import TaskImportancePredictor, KMeansClassifier

ORDER_OPTIONS = ["Importance", "Deadline", "AI-Generated"]


class Task:
    """
    Represents a task.

    Attributes
    ----------
    name: str
        The name of the task.
    importance: float
        The importance of the task. 0 <= importance <= 10.
    deadline: datetime.date
        The deadline of the task.
    
    Raises
    ------
    AssertionError:
        - if the name of the task is longer than 30 characters,
        - if the importance of the task is not between 0 and 10.
    """
    def __init__(self, name: str, importance: float, deadline: datetime.date) -> None:
        assert len(name) <= 30, "The name of the task should be <= 30 characters long."
        self.name = name
        assert 0 <= importance <= 10, "The importance of the task should be between 0 and 10."
        self.importance = importance
        self.deadline = deadline
    
    def get_name(self) -> str:
        """
        Returns
        -------
        str:
            The name of the task.
        """
        return self.name
    
    def get_importance(self) -> float:
        """
        Returns
        -------
        float:
            The importance of the task.
        """
        return self.importance
    
    def get_deadline_date(self) -> datetime.date:
        """
        Returns
        -------
        datetime.date:
            The deadline of the task.
        """
        return self.deadline
    
    def get_deadline_str(self) -> str:
        """
        Returns
        -------
        str:
            The deadline of the task in the format '<day> <month> <year>'.
        """
        return self.deadline.strftime("%d %b %Y")
    
    def set_predicted_importance(self, description: str) -> None:
        """
        Predicts the importance of a task based on its name and description
        and sets the prediction as the value of the importance attribute.

        Parameters
        ----------
        description: str
            The description of the task.
        """
        text = self.name + " " + description
        predictor = TaskImportancePredictor(text)
        self.importance = predictor.predict()


class TaskList:
    """
    Represents a list of tasks that can be sorted.

    Attributes
    ----------
    tasks: list[Task]
    """
    def __init__(self, tasks: list[Task]=[]) -> None:
        self.tasks = tasks
    
    def get_items(self) -> list[Task]:
        """
        Returns
        -------
        list[Task]
            The task list.
        """
        return self.tasks
    
    def append(self, task: Task) -> None:
        """
        Appends a task to the end of the list.
        """
        self.tasks.append(task)
    
    def remove(self, task: Task) -> None:
        """
        Removes a task from the list.

        Parameters
        ----------
        task: Task
            The task to remove.
        """
        self.tasks.remove(task)
    
    def sort(self, order: str) -> None:
        """
        Sorts the tasks in the provided order.

        Parameters
        ----------
        order: str
            The order the tasks should be sorted in. Either 'Importance', 'Deadline' or 'AI-Generated'.
            - In the 'Importance' order, the tasks are sorted so that tasks with higer importances are
              above tasks with lower importances.
            - In the 'Deadline' order, the tasks are sorted so that tasks with sooner deadlines are above
              tasks with later deadlines.
            - In the 'AI-Generated' order, the tasks are clustered into four categories based on their
              importances and deadlines. The four clusters are then divided into two halves:
              2 most important clusters and 2 least important clusters. The clusters in each half are ordered by
              their average deadline (sooner comes first). The tasks in each cluster are also sored by their deadlines.
              The clusters are then combined in the following way:
              1. Important and urgent,
              2. Important but not urgent,
              3. Not important but urgent,
              4. Not important and not urgent.
        """
        assert order in ORDER_OPTIONS
        if order == "Importance":
            self.tasks.sort(key=lambda task: task.get_importance(), reverse=True)
        elif order == "Deadline":
            self.tasks.sort(key=lambda task: task.get_deadline_date())
        elif order == "AI-Generated":
            data = [(task.get_importance(), (task.get_deadline_date() - datetime.date.today()).days) for task in self.tasks]
            classifier = KMeansClassifier(data_list=data, k=4)
            classifier.generate_centroids()
            clusters, centroids = classifier.cluster()

            high_importance_clusters = list(sorted(list(range(4)), key=lambda x: centroids.data[int(x)][0], reverse=True))[:2]
            important_urgent_cluster = min(high_importance_clusters, key=lambda x: centroids.data[int(x)][1])
            important_not_urgent_cluster = max(high_importance_clusters, key=lambda x: centroids.data[int(x)][1])

            low_importance_clusters = list(sorted(list(range(4)), key=lambda x: centroids.data[int(x)][0], reverse=True))[2:]
            not_important_urgent_cluster = min(low_importance_clusters, key=lambda x: centroids.data[int(x)][1])
            not_important_not_urgent_cluster = max(low_importance_clusters, key=lambda x: centroids.data[int(x)][1])

            self.tasks = list(sorted(self.tasks, key=lambda task: task.get_deadline_date()))

            important_urgent_tasks = [self.tasks[i] for i in range(len(self.tasks)) if clusters.data[i] == important_urgent_cluster]
            important_not_urgent_tasks = [self.tasks[i] for i in range(len(self.tasks)) if clusters.data[i] == important_not_urgent_cluster]
            not_important_urgent_tasks = [self.tasks[i] for i in range(len(self.tasks)) if clusters.data[i] == not_important_urgent_cluster]
            not_important_not_urgent_tasks = [self.tasks[i] for i in range(len(self.tasks)) if clusters.data[i] == not_important_not_urgent_cluster]

            self.tasks = important_urgent_tasks + important_not_urgent_tasks + not_important_urgent_tasks + not_important_not_urgent_tasks

