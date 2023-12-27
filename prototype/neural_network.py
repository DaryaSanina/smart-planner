import numpy as np
from utils import relu


class Dense:
    """A fully connected neural network layer."""
    def __init__(self, input_units: int, output_units: int, activation: str, learning_rate=0.001) -> None:
        """
        :param input_units: the number of features (input neurons)
        :param output_units: the number of output neurons
        :param activation: the neuron activation function. Can be either 'linear' or 'relu'.
        """
        self.ACTIVATION_FUNCTIONS = ['linear', 'relu']
        self._input_units = input_units
        self._output_units = output_units
        self._weights = np.random.random(size=(self._input_units, self._output_units))
        self._biases = np.random.random(size=(1, self._output_units))
        assert activation in self.ACTIVATION_FUNCTIONS
        self._activation = activation
        self._learning_rate = learning_rate
    
    def _activate(self, z: np.ndarray):
        """
        Performs the specified activation function.
        :param z: logits.
        :returns: a numpy array with the activation function applied to the logits.
        """
        if self.activation == 'linear':
            return z
        elif self._activation == 'relu':
            return relu(z)
    
    def forward(self, X: np.ndarray):
        """
        :param X: features of examples to perform forward propagation (inference) on. The shape should be broadcastable with the weights and biases of the layer.
        :returns: the predicted target values. The shape is (number of examples, number of outputs).
        """
        z = X @ self._weights + self._biases
        a = self._activate(z)
        return a
    
    def update_weights(self, weight_deltas: np.ndarray, bias_deltas: np.ndarray):
        """
        :param weight_deltas: the gradients of the weights. The shape should be (number of inputs, number of outputs).
        :param bias_deltas: the gradients of the biases. The shape should be (1, number of outputs).
        """
        assert weight_deltas.shape == self._weights.shape
        assert bias_deltas.shape == self._biases.shape
        self._weights -= self._learning_rate * weight_deltas
        self._biases -= self._learning_rate * bias_deltas