import tkinter as tk
from tkinter import ttk
from tkcalendar import Calendar
import datetime

from tasks import Task, TaskList, ORDER_OPTIONS


class App:
    """
    The app.

    Attributes
    ----------
    tasks: TaskList
    window: tk.Tk
    task_list_label: ttk.Label
    order_frame: ttk.Frane
    order_label: ttk.Label
    order_option: tk.StringVar
    order_selector: ttk.OptionMenu
    task_list_frame: ttk.Frame
    create_task_button: ttk.Button
    """
    def __init__(self) -> None:
        self.tasks = TaskList()

        self.window = tk.Tk()
        self.window.title("Smart Planner Prototype")
        self.window.geometry('300x400')

        self.task_list_label = ttk.Label(master=self.window, text=f"Your tasks:", font="Calibri 18")
        self.task_list_label.pack(anchor='w')

        self.order_frame = ttk.Frame(master=self.window)
        self.order_label = ttk.Label(master=self.order_frame)
        self.order_option = tk.StringVar()
        self.order_selector = ttk.OptionMenu(
            self.order_frame,
            self.order_option,
            ORDER_OPTIONS[0],
            *[option for option in ORDER_OPTIONS],
            command=lambda option: (self.tasks.sort(option), self.render_task_list())
        )
        self.order_label.pack(side='left')
        self.order_selector.pack(side='left')
        self.order_frame.pack(anchor='w')

        self.task_list_frame = ttk.Frame(master=self.window)
        self.render_task_list()
        self.task_list_frame.pack(anchor='w')

        self.create_task_button = ttk.Button(master=self.window, text="+", width=3, command=self.create_task)
        self.create_task_button.pack(anchor='w')
    
    def clear_task_list(self) -> None:
        """
        Clears the list of tasks displayed on the screen (not the internal task list)
        by destroying all the widgets that represent tasks.
        """
        for widget in self.task_list_frame.winfo_children():
            widget.destroy()
    
    def render_task_list(self) -> None:
        """
        Renders the internal task list to the screen.
        """
        self.clear_task_list()
        for task in self.tasks.tasks:
            task_frame = ttk.Frame(master=self.task_list_frame)

            def delete_task(task=task):
                self.tasks.remove(task)
                self.render_task_list()

            complete_button = ttk.Button(master=task_frame, text="✓", command=delete_task, width=3)
            complete_button.pack(side='left')

            task_info_frame = ttk.Frame(master=task_frame)
            render_task(task_info_frame, task)
            task_info_frame.pack(side='left')

            task_frame.pack(pady=10, anchor='w')
    
    def add_task(self, task: Task) -> None:
        """
        Adds a task to the internal task list and updates the task list on the screen

        Parameters
        ----------
        task: Task
            The task to be added.
        """
        self.tasks.append(task)
        self.tasks.sort(self.order_option.get())
        self.render_task_list()
    
    def create_task(self) -> None:
        """
        Creates a dialogue for the user to create a new task.
        """
        dialogue = TaskCreationDialogue(self, self.window)
        dialogue.grab_set()
    
    def run(self) -> None:
        """
        Runs the app.
        """
        self.window.mainloop()


class TaskCreationDialogue(tk.Toplevel):
    """
    A dialogue to create a task.

    Attributes
    ----------
    app: App
    parent: Tk
        The parent window.
    name_frame: ttk.Frame
    name_label: ttk.Label
    name_entry: ttk.Entry
    description_frame: ttk.Frame
    description_label: ttk.Label
    description_entry: ttk.Text
    importance_frame: ttk.Frame
    importance_label: ttk.Label
    importance_entry: ttk.Spinbox
    deadline_frame: ttk.Frame
    deadline_label: ttk.Label
    deadline_entry: tkcalendar.Calendar
    create_button: ttk.Button
    """
    def __init__(self, app: App, parent) -> None:
        super().__init__(parent)

        self.title("Create Task")
        self.geometry("300x400")

        self.app = app

        self.name_frame = ttk.Frame(master=self)
        self.name_label = ttk.Label(master=self.name_frame, text="*Name:")
        self.name_entry = ttk.Entry(master=self.name_frame)
        self.name_label.pack(side='left')
        self.name_entry.pack(side='left', padx=10)
        self.name_frame.pack(anchor='w')

        self.description_frame = ttk.Frame(master=self)
        self.description_label = ttk.Label(master=self.description_frame, text="Description:")
        self.description_entry = tk.Text(master=self.description_frame, height=7)
        self.description_label.pack(anchor='w')
        self.description_entry.pack(anchor='w')
        self.description_frame.pack(anchor='w')

        self.importance_frame = ttk.Frame(master=self)
        self.importance_label = ttk.Label(master=self.importance_frame, text="*Importance:")
        self.importance_entry = ttk.Spinbox(master=self.importance_frame, from_=0, to=10)
        self.importance_label.pack(side='left')
        self.importance_entry.pack(side='left', padx=10)
        self.importance_frame.pack(anchor='w')

        self.deadline_frame = ttk.Frame(master=self)
        self.deadline_label = ttk.Label(master=self.deadline_frame, text="*Deadline:")
        self.deadline_entry = Calendar(master=self.deadline_frame)
        self.deadline_label.pack(side='left')
        self.deadline_entry.pack(side='left', padx=10)
        self.deadline_frame.pack(anchor='w')

        self.create_button = ttk.Button(master=self, text="Create", command=self.create)
        self.create_button.pack(side='bottom')
    
    def create(self) -> None:
        """
        Checks the values of all the entry fields in the dialogue window,
        calls the add_task method of the app with the retrieved values,
        and destroys the dialogue window.
        """
        task = Task(
            name=self.name_entry.get(),
            importance=int(self.importance_entry.get()) if self.importance_entry.get() != '' else 0,
            deadline=datetime.datetime.strptime(self.deadline_entry.get_date(), '%m/%d/%y').date()
        )

        if self.importance_entry.get() == '':
            task.set_predicted_importance(self.description_entry.get('1.0', 'end'))

        self.app.add_task(task)
        self.destroy()


def render_task(frame: ttk.Frame, task: Task) -> None:
    """
    Renders a single task on a frame. Used by the render_task_list method of the App class.

    Parameters
    ----------
    frame: ttk.Frame
        The frame for the task to be rendered to.
    task: Task
        The task to be rendered.
    """
    name_label = ttk.Label(master=frame, text=task.get_name(), font="Calibri 14")
    name_label.pack(anchor='w')

    deadline = task.get_deadline_str()
    time_constraints_label = ttk.Label(master=frame, text=f"Due: {deadline}", font="Calibri 12")
    time_constraints_label.pack(anchor='w')

    importance_label = ttk.Label(master=frame, text=f"Importance: {task.get_importance()}", font="Calibri 12")
    importance_label.pack(anchor='w')


def main():
    app = App()
    app.run()


if __name__ == '__main__':
    main()
