import numpy as np
from autograd import Tensor


class SGD:
    """
    Implements stochastic gradient descent.

    Attributes
    ----------
    parameters : list[Tensor]
        The model's parameters.
    alpha : float
        The model's learning rate.
    """


class SGD:
    def __init__(self, parameters: list[Tensor], alpha: float = 0.1) -> None:
        self.parameters = parameters
        self.alpha = alpha
    
    def zero(self) -> None:
        """
        Resets the parameters' gradients.
        """
        for p in self.parameters:
            p.grad = Tensor(np.zeros_like(p.grad))
    
    def step(self, zero=True) -> None:
        """
        Updates the model's parameters.

        Parameters
        ----------
        zero : bool
            Whether the parameters' gradients should be reset after this step.
        """
        for p in self.parameters:
            p.data -= p.grad.data.astype("float64") * self.alpha
            if zero:
                p.grad = Tensor(np.zeros_like(p.grad))
