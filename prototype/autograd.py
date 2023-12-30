import numpy as np


class Tensor:
    def __init__(self, data) -> None:
        self.data = np.array(data)
    
    def __add__(self, other):
        return Tensor(self.data + other.data)
    
    def __repr__(self) -> str:
        return str(self.data.__repr__())
    
    def __str__(self) -> str:
        return str(self.data.__str__())


x = Tensor([1, 2, 3, 4, 5])
y = x + x
print(y)
