import numpy as np


class Tensor:
    """
    Represents a tensor.

    Attributes
    ----------
    data : NDArray
        The data stored in the tensor.
    creators : list[Tensor], optional
        A list of tensors an operation on which produced this tensor.
    creation_op : str, optional
        The operation that was used to produce this tensor.
    grad: Tensor, initially is None
        The gradient of this tensor.
    """


class Tensor:
    def __init__(self, data, creators=None, creation_op=None) -> None:
        self.data = np.array(data)
        self.creators = creators
        self.creation_op = creation_op
        self.grad = None
    
    def backward(self, grad: Tensor) -> None:
        """
        Backpropagates the gradient of the tensor to its creators.
        The only supported creation_op of the tensor is "add", which represents the addition of two tensors.

        Parameters
        ----------
        grad: Tensor
            The gradient of this tensor.
        """
        self.grad = grad

        if self.creation_op == "add":
            self.creators[0].backward(grad)
            self.creators[1].backward(grad)
    
    def __add__(self, other: Tensor):
        """
        Adds two tensors together.

        Parameters
        ----------
        other: Tensor
            The tensor that should be added to this tensor.
        
        Returns
        -------
        Tensor
            The tensor produced when adding the 'other' tensor to this tensor.
        """
        return Tensor(self.data + other.data, creators=[self, other], creation_op="add")
    
    def __repr__(self) -> str:
        return str(self.data.__repr__())
    
    def __str__(self) -> str:
        return str(self.data.__str__())
