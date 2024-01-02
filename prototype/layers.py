import numpy as np
from autograd import Tensor


class Layer:
    """
    Represents a layer of a neural network. It is an abstract class that acts as a parent to all types of layers.

    Attributes
    ----------
    parameters : list[Tensor]
        The layer's parameters.
    """


class Layer:
    def __init__(self) -> None:
        self.parameters = list()
    
    @property
    def get_parameters(self) -> list[Tensor]:
        return self.parameters


class Linear(Layer):
    """
    Represents a linear layer of a neural network.

    Attributes
    ----------
    weight : Tensor
        The layer's weights.
    bias : Tensor
        The layer's bias.
    parameters : list[Tensor]
        The layer's parameters (a combination of weight and bias).
    """


class Linear(Layer):
    def __init__(self, n_inputs: int, n_outputs: int) -> None:
        """
        Parameters
        ----------
        n_inputs : int
            The number of inputs of the layer.
        n_outputs : int
            The number of outputs of the layer.
        """
        super().__init__()
        W = np.random.randn(n_inputs, n_outputs) * np.sqrt(2.0 / n_inputs)
        self.weight = Tensor(W, autograd=True)
        self.bias = Tensor(np.zeros(n_outputs), autograd=True)

        self.parameters.append(self.weight)
        self.parameters.append(self.bias)
    
    def forward(self, input: Tensor) -> Tensor:
        """
        Executes forward propagation on this layer.

        Parameters
        ----------
        input : Tensor
            The layer's input.
        """
        return input @ self.weight + self.bias.expand(0, len(input.data))
