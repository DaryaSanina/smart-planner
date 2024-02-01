import pickle as pkl
import datetime

from autograd import Tensor
from layers import *

with open('importance_embedding.pkl', 'rb') as file:
    embedding = pkl.load(file)

with open('importance_model.pkl', 'rb') as file:
    model = pkl.load(file)

with open('importance_output.pkl', 'rb') as file:
    output_layer = pkl.load(file)

with open('word2index.pkl', 'rb') as file:
    word2index = pkl.load(file)

ids_to_entities = dict()


class Entity:
    """
    Represents a task or an event and is a parent class to the Task and Event classes.

    Attributes
    ----------
    id : int
        The unique ID of the entity
    name : str
        The name of the task or the event.
    description : str (optional)
        The description of the task or the event.
    importance : float (optional)
        The importance level of the task or the event from 1 to 10. It can either be set manually or predicted using the machine learning model from this folder.
    parent_id : int
        The ID of this entity's parent.
    children_ids : set[int]
        The IDs of this entity's children.
    """
    def __init__(self, id: int, name: str, description: str = "", importance: float = None, parent_id: int = None, children_ids: set[int] = set()) -> None:
        self.id = id
        self.name = name
        self.description = description
        if importance is None:
            self.predict_importance()
        else:
            self.importance = importance
        self.parent_id = parent_id
        self.children_ids = children_ids
    
    def get_id(self) -> int:
        return self.id
    
    def get_name(self) -> str:
        return self.name
    
    def get_description(self) -> str:
        return self.description
    
    def get_importance(self) -> str:
        return self.importance
    
    def get_parent_id(self) -> int:
        return self.parent_id
    
    def get_children_ids(self) -> set[int]:
        return self.children_ids
    
    def set_name(self, name: str) -> None:
        self.name = name
    
    def set_description(self, description: str) -> None:
        self.description = description
    
    def set_importance(self, importance: float) -> None:
        self.importance = importance
    
    def add_child(self, child_id: int) -> None:
        self.children_ids.add(child_id)

    def remove_child(self, child_id: int) -> None:
        self.children_ids.remove(child_id)
    
    def predict_importance(self) -> None:
        """
        Predicts the importance of the task or the event based on its name.
        """
        tokens = self.name.lower().split()
        task_indices = [word2index[token] for token in tokens if token in word2index.keys()]

        hidden = model.init_hidden()
        for t in range(len(task_indices)):
            input = Tensor([task_indices[t]], autograd=True)
            rnn_input = embedding.forward(input=input)
            hidden = model.forward(input=rnn_input, hidden=hidden)
        output = output_layer.forward(hidden[0])
        
        self.importance = output.data[0][0]
    
    def select_child(self, operation: str) -> int:
        """
        Asks the user to enter the name of the sub-task or sub-event they would like to select and returns its id or raises an error.

        Parameters
        ----------
        operation: str
            The operation to be performed later on the selected child (select/edit/delete). This information is needed to customise the output of the function in the command line.

        Returns
        -------
        child_id: int
            The ID of the sub-task or the sub-event the user would like to select.
        
        Raises
        ------
        NameError:
            If the name of the sub-task or sub-event the user has entered is not in the current task/event children list.
        """
        sub_entity_name = input(f"Enter the name of the subtask or sub-event you would like to {operation}: ")
        for child_id in self.children_ids:
            if ids_to_entities[child_id].name == sub_entity_name:
                return child_id
        print("Sorry, there is no such task or event.")
        raise NameError
    
    def __repr__(self) -> str:
        return f"Name: {self.name.capitalize()}\nDescription: {self.description}\nImportance: {self.importance:.2}\n"


class Task(Entity):
    """
    Represents a task.

    Attributes
    ----------
    name : str
        The name of the task.
    deadline : date
        The task's deadline.
    description : str (optional)
        The task's description.
    importance : float (optional)
        The task's importance level from 1 to 10. It can either be set manually or predicted using the machine learning model from this folder.
    """
    def __init__(self, id: int, name: str, deadline: datetime.date, description: str = "", importance: float = None, parent_id: int = None, children_ids: set[int] = set()) -> None:
        super().__init__(id, name, description, importance, parent_id, children_ids)
        self.deadline = deadline
    
    def get_deadline(self) -> datetime.date:
        return self.deadline
    
    def set_deadline(self, deadline: datetime.date) -> None:
        self.deadline = deadline
    
    def __repr__(self):
        return "Task\n" + super().__repr__() + f"Deadline: {self.deadline}\n"


class Event(Entity):
    """
    Represents an event.

    Attributes
    ----------
    name : str
        The name of the event.
    start : datetime
        The date and time when the event starts.
    end : datetime
        The date and time when the event ends.
    description : str (optional)
        The task's description.
    importance : float (optional)
        The task's importance level from 1 to 10. It can either be set manually or predicted using the machine learning model from this folder.
    """
    def __init__(self, id: int, name: str, start: datetime.datetime, end: datetime.datetime, description: str = "", importance: float = None, parent_id: int = None, children_ids: set[int] = set()) -> None:
        super().__init__(id, name, description, importance, parent_id, children_ids)
        self.start = start
        self.end = end
    
    def get_start(self) -> datetime.datetime:
        return self.start
    
    def get_end(self) -> datetime.datetime:
        return self.end
    
    def set_start(self, start: datetime.datetime) -> None:
        self.start = start
    
    def set_end(self, end: datetime.datetime) -> None:
        self.end = end
    
    def __repr__(self):
        return "Event\n" + super().__repr__() + f"Start: {self.start}\nEnd: {self.end}\n"


def ask_name() -> str:
    """
    Asks the user to enter the name of a task/event.

    Returns
    -------
    naem: str
        The task/event name entered by the user.
    """
    name = input("Name: ")
    return name


def ask_description() -> str:
    """
    Asks the user to enter the description of a task/event.

    Returns
    -------
    description: str
        The task/event description entered by the user.
    """
    print("Description (you can enter multiple lines of text, enter an empty line after the last line):")
    description = ""
    while True:
        line = input()
        if line == '':
            break
        else:
            description += '\n' + line
    return description


def ask_importance() -> int:
    """
    Asks the user to enter the importance of a task/event.

    Returns
    -------
    importance: int
        The task/event description entered by the user.
    """
    while True:
        try:
            importance = input("Importance level from 1 to 10 (leave blank if you would like it to be predicted by AI): ")
            if importance == '':
                importance = None
            else:
                importance = float(importance)
                if importance < 1 or importance > 10:
                    raise ValueError
            break
        except ValueError:
            print("Please enter the importance level in the specified format.")
    return importance


def add_entity(current_id):
    """
    Adds a task or an event to the list as a child of the current task/event.

    Parameters
    ----------
    current_id: int
        The ID of the current task/event.
    """
    entity_type = input("Task/event: ")
    while entity_type.lower() not in ('task', 'event'):
        print("Sorry, I didn't understand that.")
        entity_type = input("Task/event: ")

    id = max(ids_to_entities.keys()) + 1

    name = ask_name()

    description = ask_description()
    
    importance = ask_importance()

    entity = None
    if entity_type.lower() == 'task':
        deadline = get_task_deadline()
        entity = Task(id, name, deadline, description, importance, current_id, {})
    elif entity_type.lower() == 'event':
        start = get_event_start()
        end = get_event_end()
        entity = Event(id, name, start, end, description, importance, current_id, {})
    
    ids_to_entities[id] = entity
    ids_to_entities[current_id].children_ids.add(id)


def get_task_deadline() -> datetime.date:
    """
    Asks the user to enter the deadline of a task.

    Returns
    -------
    deadline: datetime.date
        The deadline of the task entered by the user.
    """
    while True:
        try:
            deadline = datetime.date(*map(int, input("Deadline (year-month-day as integers): ").split('-')))
            return deadline
        except ValueError:
            print("Please enter the deadline in the specified format.")


def get_event_start() -> datetime.datetime:
    """
    Asks the user to enter the start of an event.

    Returns
    -------
    start: datetime.datetime
        The start of the event entered by the user.
    """
    while True:
        try:
            year, month, day, hour, minute = map(int, input("Start date and time (year-month-day-hour-minute as integers): ").split('-'))
            start = datetime.datetime(year=year, month=month, day=day, hour=hour, minute=minute)
            break
        except ValueError:
            print("Please enter the event start date and time in the specified format.")
    return start


def get_event_end() -> datetime.datetime:
    """
    Asks the user to enter the end of an event.

    Returns
    -------
    end: datetime.datetime
        The end of the event entered by the user.
    """
    while True:
        try:
            year, month, day, hour, minute = map(int, input("End date and time (year-month-day-hour-minute as integers): ").split('-'))
            end = datetime.datetime(year=year, month=month, day=day, hour=hour, minute=minute)
            break
        except ValueError:
            print("Please enter the event end date and time in the specified format.")
    return end


def edit_entity(entity_id: int):
    """
    Asks the user to enter the property of the task/event they would like to edit and edit it.

    Parameters
    ----------
    entity_id: int
        The ID of the entity to edit.
    
    Raises
    ------
    KeyError:
        If the task/event doesn't have the entered property.
    """
    entity = ids_to_entities[entity_id]
    property_ = input("Which property would you like to edit? ")
    if property_ == "name":
        new_name = ask_name()
        entity.set_name(new_name)
    elif property_ == "description":
        new_description = ask_description()
        entity.set_description(new_description)
    elif property_ == "importance":
        new_importance = ask_importance()
        entity.set_importance(new_importance)
    else:
        if isinstance(entity, Task):
            edit_task()
        elif isinstance(entity, Event):
            edit_event()
        else:
            raise KeyError


def edit_task(task: Task, property_: str):
    """
    Allows the user to edit the given property of the given task.

    Parameters
    ----------
    task: Task
        The task to edit.
    property_: str
        The property of the task to edit.
    
    Raises
    ------
    KeyError:
        If the task doesn't have this property.
    """
    if property_ == "deadline":
        new_deadline = get_task_deadline()
        task.set_deadline(new_deadline)
    else:
        raise KeyError


def edit_event(event: Event, property_: str):
    """
    Allows the user to edit the given property of the given event.

    Parameters
    ----------
    event: Event
        The event to edit.
    property_: str
        The property of the event to edit.
    
    Raises
    ------
    KeyError:
        If the event doesn't have this property.
    """
    if property_ == "start":
        new_start = get_event_start()
        event.set_start(new_start)
    elif property_ == "end":
        new_end = get_event_end()
        event.set_end(new_end)
    else:
        raise KeyError


def main():
    global ids_to_entities
    ids_to_entities = {-1: Entity(-1, "base", importance = 0)}
    view = 'deadline'
    current_id = -1
    while True:
        # Show the current task or event
        entity = ids_to_entities[current_id]
        if current_id == -1:
            print("Current location: base")
        else:
            if isinstance(entity, Task):
                print("Current task:", entity.name)
            elif isinstance(entity, Event):
                print("Current event:", entity.name)
        
        # Output the subtasks and subevents of the current task or event
        print("\nContains:\n")
        for child_id in entity.children_ids:
            print(ids_to_entities[child_id])
            print()
        
        command = input("Enter a command ('add', 'edit', 'delete', 'go back', 'select', 'view' or 'quit'): ")
        match command:
            case 'add':
                add_entity(current_id)

            case 'edit':
                try:
                    entity_id = ids_to_entities[current_id].select_child("edit")
                    edit_entity(entity_id)
                except NameError:
                    print("Sorry, there is not such task or event.")
                except KeyError:
                    print("Sorry the entity doesn't have this property.")

            case 'delete':
                try:
                    entity_id = ids_to_entities[current_id].select_child("delete")
                    ids_to_entities[current_id].remove_child(entity_id)
                    ids_to_entities.pop(entity_id)
                except NameError:
                    print("Sorry, there is not such task or event.")

            case 'go back':
                current_id = ids_to_entities[current_id].parent_id

            case 'select':
                try:
                    current_id = ids_to_entities[current_id].select_child("select")
                except NameError:
                    print("Sorry, there is not such task or event.")

            case 'view':
                pass

            case 'quit':
                break

            case _:
                print("Sorry, I didn't understand that.")


if __name__ == '__main__':
    main()
