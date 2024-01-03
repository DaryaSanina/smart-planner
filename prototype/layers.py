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

    def __init__(self) -> None:
        self.parameters = list()
    
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
        
        Returns
        -------
        Tensor
            The layer's output.
        """
        return input @ self.weight + self.bias.expand(0, len(input.data))


class Sequential(Layer):
    """
    Represents a sequence of layers of a neural network.

    Attributes
    ----------
    layers : list[Layer]
        A list of neural network layers.
    parameters : list[Tensor]
        The parameters of each layer.
    """

    def __init__(self, layers: list[Layer] = list()) -> None:
        super().__init__()
        self.layers = layers
    
    def add(self, layer: Layer) -> None:
        """
        Adds a layer to the sequence.

        Parameters
        ----------
        layer : Layer
            The layer to add to the sequence.
        """
        self.layers.append(layer)
    
    def forward(self, input: Tensor) -> Tensor:
        """
        Executes forward propagation on the layer sequence.

        Parameters
        ----------
        input : Tensor
            The input to the sequential layer.
        
        Returns
        -------
        Tensor
            The output of the sequential layer.
        """
        for layer in self.layers:
            input = layer.forward(input)
        return input
    
    def get_parameters(self) -> list[Tensor]:
        params = list()
        for layer in self.layers:
            params += layer.get_parameters()
        return params


class MSELoss(Layer):
    """
    Represents the Mean Squared Error loss function.
    """

    def __init__(self) -> None:
        super().__init__()
    
    def forward(self, pred: Tensor, target: Tensor) -> Tensor:
        """
        Calculates the Mean Squared Error of a prediction.

        Parameters
        ----------
        pred : Tensor
            The prediction.
        target : Tensor
            The target values. They should have the same shape as 'pred'.
        
        Returns
        -------
        Tensor
            The value of the Mean Squared Error loss.
        """
        return ((pred - target) * (pred - target)).sum(0)


class Sigmoid(Layer):
    """
    Represents the sigmoid activation function.
    """

    def __init__(self) -> None:
        super().__init__()
    
    def forward(self, input: Tensor) -> Tensor:
        """
        Applies the sigmoid activation function to the input.

        Parameters
        ----------
        input : Tensor
            The input to the sigmoid function (the logits).
        
        Returns
        -------
        Tensor
            The result of applying the sigmoid activation function to the logits.
        """
        return input.sigmoid()
