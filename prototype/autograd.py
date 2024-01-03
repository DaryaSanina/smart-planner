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
    index_select_indices : Tensor
        If the tensor was created using the 'index_select' operation, this attribute stores the indices of the tensor this tensor was created from.
    softmax_output : Tensor
        If the tensor was created using the 'cross_entropy' operation, this attribute stores the values of the softmax activation function applied to the original layer.
    target_distribution : Tensor
        If the tensor was created using the 'cross_entropy' operation, this attribute stores a tensor of one-hot encoded targets.
    """


class Tensor:
    def __init__(self, data, autograd=False, creators: list[Tensor] = None, creation_op: str = None, id: int = None) -> None:
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
    
    def grads_accounted_for_all_children(self) -> bool:
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
        Supported values of creation_op of this tensor:
            - "add": tensor addition,
            - "neg": tensor negation,
            - "sub": tensor subtraction,
            - "mul": elementwise tensor multiplication,
            - "sum_<dim>": tensor summation along the specified dimension,
            - "expand_<dim>": tensor expansion along the specified dimension,
            - "transpose": tensor transpose,
            - "matmul": matrix multiplication,
            - "sigmoid": sigmoid function,
            - "tanh": tanh function,
            - "relu": ReLU function,
            - "index_select": tensor index selection,
            - "cross_entropy": cross-entropy function.

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
            # Allows not to pass the gradient when calling backward() for the first time
            if grad is None:
                grad = Tensor(np.ones_like(self.data))
            
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
                    self.creators[0].backward(self.grad, self)
                    self.creators[1].backward(self.grad, self)
                
                if self.creation_op == "neg":
                    self.creators[0].backward(self.grad.__neg__(), self)
                
                if self.creation_op == "sub":
                    self.creators[0].backward(self.grad, self)
                    self.creators[1].backward(self.grad.__neg__(), self)
                
                if self.creation_op == "mul":
                    self.creators[0].backward(self.grad * self.creators[1], self)
                    self.creators[1].backward(self.grad * self.creators[0], self)
                
                if self.creation_op == "matmul":
                    activation = self.creators[0]
                    weights = self.creators[1]
                    activation.backward(self.grad @ weights.transpose(), self)
                    weights.backward((self.grad.transpose() @ activation).transpose(), self)
                
                if self.creation_op == "transpose":
                    self.creators[0].backward(self.grad.transpose())
                
                if self.creation_op == "sigmoid":
                    # σ'(x) = σ(x) * (1 - σ(x))
                    ones = Tensor(np.ones_like(self.grad.data))
                    self.creators[0].backward(self.grad * (self * (ones - self)))
                
                if self.creation_op == "tanh":
                    # tanh'(x) = 1 - tanh(x) ** 2
                    ones = Tensor(np.ones_like(self.grad.data))
                    self.creators[0].backward(self.grad * (ones - self * self))
                
                if self.creation_op == "relu":
                    # ReLU'(x) = 1 if x > 0, 0 if x <= 0
                    ones = Tensor(np.ones_like(self.grad.data))
                    self.creators[0].backward(self.grad * (self > 0))
                
                if self.creation_op == "index_select":
                    new_grad = np.zeros_like(self.creators[0].data)
                    indices_ = self.index_select_indices.data.flatten()
                    grad_ = grad.data.reshape(len(indices_), -1)
                    for i in range(len(indices_)):
                        new_grad[indices_[i]] += grad_[i]
                    self.creators[0].backward(Tensor(new_grad))
                
                if self.creation_op == "cross_entropy":
                    self.creators[0].backward(Tensor(self.softmax_output - self.target_distribution))
                
                if "sum" in self.creation_op:
                    dim = int(self.creation_op.split('_')[1])
                    copies = self.creators[0].data.shape[dim]
                    self.creators[0].backward(self.grad.expand(dim, copies), self)
                
                if "expand" in self.creation_op:
                    dim = int(self.creation_op.split('_')[1])
                    self.creators[0].backward(self.grad.sum(dim), self)
    
    def __add__(self, other: Tensor) -> Tensor:
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
    
    def __neg__(self) -> Tensor:
        """
        Performs the negation operation on the tensor.

        Returns
        -------
        Tensor
            The tensor produced when negating this tensor.
        """
        if self.autograd:
            return Tensor(self.data * -1, autograd=True, creators=[self], creation_op="neg")
        return Tensor(self.data * -1)
    
    def __sub__(self, other: Tensor) -> Tensor:
        """
        Subtracts one vector from another.

        Parameters
        ----------
        other : Tensor
            The tensor that should be subtracted from this tensor. Its dimensions should match to the dimensions of this tensor.
        
        Returns
        -------
        Tensor
            The tensor produced when subtracting the 'other' tensor from this tensor.
        """
        if self.autograd:
            return Tensor(self.data - other.data, autograd=True, creators=[self, other], creation_op="sub")
        return Tensor(self.data - other.data)
    
    def __mul__(self, other: Tensor) -> Tensor:
        """
        Multiplies the elements of one tensor by the corresponding elements of another tensor.

        Parameters
        ----------
        other : Tensor
            The tensor this tensor should be multiplied by. Its dimensions should match to the dimensions of this tensor.
        
        Returns
        -------
        Tensor
            The tensor produced when multiplying the elements of this tensor by the corresponding elements of the 'other' tensor.
        """
        if self.autograd and other.autograd:
            return Tensor(self.data * other.data, autograd=True, creators=[self, other], creation_op="mul")
        return Tensor(self.data * other.data)
    
    def __matmul__(self, other: Tensor) -> Tensor:
        """
        Performs matrix multiplication on two tensors (multiplies this tensor by the 'other' tensor).

        Parameters
        ----------
        other : Tensor
            The tensor this tensor should be multiplied by. Its first dimension should be equal to the last dimension of this tensor.
        
        Returns
        -------
        Tensor
            The tensor produced when multiplying this tensor by the 'other' tensor.
        """
        if self.autograd:
            return Tensor(self.data @ other.data, autograd=True, creators=[self, other], creation_op="matmul")
        return Tensor(self.data @ other.data)
    
    def __getitem__(self, indices: Tensor) -> Tensor:
        """
        Selects the elements of the tensor with the corresponding indices.

        Parameters
        ----------
        indices : Tensor
            The indices to be selected.
        
        Returns
        -------
        Tensor
            The tensor of this tensor's elements with the corresponding indices.
        """
        if self.autograd:
            new = Tensor(self.data[indices.data], autograd=True, creators=[self], creation_op="index_select")
            new.index_select_indices = indices
            return new
        return Tensor(self.data[indices.data])
    
    def sum(self, dim: int) -> Tensor:
        """
        Sums the tensor along the specified axes.

        Parameters
        ----------
        dim : int
            The axis along which the tensor should be summed.
        
        Returns
        -------
        Tensor
            The tensor produced when summing this tensor along the specified axes.
        """
        if self.autograd:
            return Tensor(self.data.sum(dim), autograd=True, creators=[self], creation_op="sum_" + str(dim))
        return Tensor(self.data.sum(dim))
    
    def expand(self, dim: int, copies: int) -> Tensor:
        """
        Repeats the specified axis of the tensor the specified number of times.

        Parameters
        ----------
        dim : int
            The axis that should be repeated.
        copies : int
            The number of copies of the axis.
        
        Returns
        -------
        Tensor
            The tensor produced when repeating the specifed axis of this tensor the specified number of times.
        """
        transpose_command = list(range(0, len(self.data.shape)))
        transpose_command.insert(dim, len(self.data.shape))
        new_shape = list(self.data.shape) + [copies]
        new_data = self.data.repeat(copies).reshape(new_shape).transpose(transpose_command)

        if self.autograd:
            return Tensor(new_data, autograd=True, creators=[self], creation_op="expand_" + str(dim))
        return Tensor(new_data)
    
    def transpose(self) -> Tensor:
        """
        Transposes the tensor.

        Returns
        -------
        Tensor
            The transposed tensor.
        """
        if self.autograd:
            return Tensor(self.data.transpose(), autograd=True, creators=[self], creation_op="transpose")
        return Tensor(self.data.transpose())
    
    def sigmoid(self) -> Tensor:
        """
        Applies the sigmoid function to each element of the tensor.

        σ(x) = 1 / (1 + e ** (-x))

        Returns
        -------
            The result of applying the sigmoid function to the tensor.
        """
        if self.autograd:
            return Tensor(1 / (1 + np.exp(-self.data)), autograd=True, creators=[self], creation_op="sigmoid")
        return Tensor(1 / (1 + np.exp(-self.data)))
    
    def tanh(self) -> Tensor:
        """
        Applies the tanh function to each element of the tensor.

        tanh(x) = (e ** x - e ** (-x)) / (e ** x + e ** (-x))

        Returns
        -------
        Tensor
            The result of applying the tanh function to the tensor.
        """
        if self.autograd:
            return Tensor(np.tanh(self.data), autograd=True, creators=[self], creation_op="tanh")
        return Tensor(np.tanh(self.data))
    
    def relu(self) -> Tensor:
        """
        Applies the ReLU function to each element of the tensor.

        ReLU(x) = 
            x if x > 0
            0 if x <= 0

        Returns
        -------
        Tensor
            The result of applying the ReLU function to the tensor.
        """
        if self.autograd:
            return Tensor(self.data * (self.data > 0), autograd=True, creators=[self], creation_op="relu")
        return Tensor(self.data * (self.data > 0))
    
    def cross_entropy(self, target_indices: Tensor) -> Tensor:
        """
        Calculates the cross entropy of the tensor given the indices of the target values (where the target = 1).

        Parameters
        ----------
        target_indices : Tensor
            The indices where the target = 1.
        
        Returns
        -------
        Tensor
            A tensor containing the calculated cross-entropy.
        """
        temp = np.exp(self.data)
        softmax_output = temp / np.sum(temp, axis=len(self.data.shape) - 1, keepdims=True)
        target = target_indices.data.flatten()
        prediction = softmax_output.reshape(len(target), -1)
        target_distribution = np.eye(prediction.shape[1])[target]
        loss = -(np.log(prediction) * target_distribution).sum(1).mean()

        if self.autograd:
            output = Tensor(loss, autograd=True, creators=[self], creation_op="cross_entropy")
            output.softmax_output = softmax_output
            output.target_distribution = target_distribution
            return output
        return Tensor(loss)
    
    def __repr__(self) -> str:
        return str(self.data.__repr__())
    
    def __str__(self) -> str:
        return str(self.data.__str__())
