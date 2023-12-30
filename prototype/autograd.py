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
    grad : Tensor, initially is None
        The gradient of this tensor.
    autograd : bool, optional
        Whether the tensor should use autograd.
    id: int
        This tensor's unique identificator.
    children : dict[int, int]
        A dictionary where the keys represent the ids of the tensors that were created using this tensor,
        and the values represent the number of times a child tensor needs to backpropagate its gradient to this tensor.
    """


class Tensor:
    def __init__(self, data, autograd=False, creators=None, creation_op=None, id=None) -> None:
        self.data = np.array(data)
        self.creators = creators
        self.creation_op = creation_op
        self.grad = None
        self.autograd = autograd
        
        if id is None:
            id = np.random.randint(0, 100000)
        self.id = id

        self.children = {}
        if creators is not None:
            for c in creators:
                # Keep track of how many children a tensor has
                if self.id not in c.children:
                    c.children[self.id] = 1
                else:
                    c.children[self.id] += 1
    
    def grads_accounted_for_all_children(self):
        """
        Determines whether all the children of this tensor have backpropagated their gradients onto it.

        Returns
        -------
        bool
            True if all the children of this tensor have backpropagated their gradients onto it, False otherwise.
        """
        for cnt in self.children.values():
            if cnt != 0:
                return False
        return True
    
    def backward(self, grad=None, grad_origin=None) -> None:
        """
        Backpropagates the gradient of the tensor to its creators.
        The only supported creation_op of the tensor is "add", which represents the addition of two tensors.

        Parameters
        ----------
        grad : Tensor
            The gradient of this tensor. Its dimensions should match the dimensions of the tensor.
        grad_origin : Tensor
            The child tensor the gradient is backpropagated from.
        
        Raises
        ------
        Exception
            If the 'grad_origin' tensor has already backpropagated its gradient to this tensor the number of times it needed to do so.
        """
        if self.autograd:
            if grad_origin is not None:
                # Check to make sure backpropagation is possible or whether the tensor is waiting for a gradient, in which case decrement the counter
                if self.children[grad_origin.id] == 0:
                    raise Exception("Cannot backprop more than once.")
                else:
                    self.children[grad_origin.id] -= 1

            # Accumulate gradients from several children
            if self.grad is None:
                self.grad = grad
            else:
                self.grad += grad
            
            # Actual backpropagation
            if self.creators is not None and (self.grads_accounted_for_all_children() or grad_origin is None):
                if self.creation_op == "add":
                    self.creators[0].backward(grad, self)
                    self.creators[1].backward(grad, self)
    
    def __add__(self, other: Tensor):
        """
        Adds two tensors together.

        Parameters
        ----------
        other : Tensor
            The tensor that should be added to this tensor. Its dimensions should match to the dimensions of this tensor.
        
        Returns
        -------
        Tensor
            The tensor produced when adding the 'other' tensor to this tensor.
        """
        if self.autograd and other.autograd:
            return Tensor(self.data + other.data, autograd=True, creators=[self, other], creation_op="add")
        return Tensor(self.data + other.data)
    
    def __repr__(self) -> str:
        return str(self.data.__repr__())
    
    def __str__(self) -> str:
        return str(self.data.__str__())
