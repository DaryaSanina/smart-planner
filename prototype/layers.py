import numpy as np
from utils import relu, relu_derivative


class Dense:
    """A fully connected neural network layer."""
    def __init__(self, input_units: int, output_units: int, activation: str) -> None:
        """
        :param input_units: the number of features (input neurons).
        :param output_units: the number of output neurons.
        :param activation: the neuron activation function. Can be either 'linear' or 'relu'.
        """
        self.ACTIVATION_FUNCTIONS = ['linear', 'relu']
        self.input_units = input_units
        self.output_units = output_units
        self._weights = np.random.random(size=(self.input_units, self.output_units))
        self._biases = np.random.random(size=(1, self.output_units))
        assert activation in self.ACTIVATION_FUNCTIONS
        self._activation = activation
    
    def _activate(self, z: np.ndarray) -> np.ndarray:
        """
        Performs the specified activation function.
        :param z: logits with shape (number of examples, number of outputs)
        :returns: a numpy array with the activation function applied to the logits with shape (number of examples, number of outputs).
        """
        if self._activation == 'linear':
            return z
        elif self._activation == 'relu':
            return relu(z)
    
    def _get_logit_gradients(self, output_gradients: np.ndarray) -> np.ndarray:
        """
        Computes the gradients of the logits based on the derivative of the activation function.
        :param output_gradients: the gradients of the cost function for the outputs of the layer. The shape should be (number of examples, number of outputs).
        :returns: logit gradients with shape (number of examples, number of outputs).
        """
        assert output_gradients.shape[1] == self.output_units
        if self._activation == 'linear':
            return output_gradients
        elif self._activation == 'relu':
            return output_gradients * relu_derivative(output_gradients)
    
    def forward(self, X: np.ndarray) -> np.ndarray:
        """
        :param X: examples to perform forward propagation (inference) on. The shape should be broadcastable with the layer's weights and biases.
        :returns: the predicted target values with shape (number of examples, number of outputs).
        """
        z = X @ self._weights + self._biases
        a = self._activate(z)
        return a
    
    def get_weight_gradients(self, X: np.ndarray, output_gradients: np.ndarray) -> np.ndarray:
        """
        :param X: the features of the examples the output gradients were computed for. The shape should be (number of examples, number of features).
        :param output_gradients: the gradients of the cost function for the outputs of the layer. The shape should be (number of examples, number of outputs).
        :returns weight_gradients: the gradients of the layer weights with shape (number of features, number of outputs).
        :return bias_gradients: the gradients of the layer biases with shape (1, number of outputs).
        """
        m = X.shape[0]  # The number of examples
        logit_gradients = self._get_logit_gradients(output_gradients)
        weight_gradients = X.T @ logit_gradients
        bias_gradients = np.sum(logit_gradients, axis=0)
        return weight_gradients, bias_gradients
    
    def get_input_gradients(self, output_gradients: np.ndarray) -> np.ndarray:
        """
        :param output_gradients: the gradients of the cost function for the outputs of the layer. The shape should be (number of examples, number of outputs).
        :returns input_gradients: the gradients of the layer inputs with shape (number of examples, number of features).
        """
        logit_gradients = self._get_logit_gradients(output_gradients)
        input_gradients = (self._weights @ logit_gradients.T).T
        return input_gradients
    
    def update_weights(self, weight_gradients: np.ndarray, bias_gradients: np.ndarray, learning_rate) -> None:
        """
        :param weight_deltas: the gradients of the weights with shape (number of inputs, number of outputs).
        :param bias_deltas: the gradients of the biases with shape (1, number of outputs).
        :prarm learning_rate: the learning rate of the model.
        """
        assert weight_gradients.shape == self._weights.shape
        assert bias_gradients.shape == self._biases.shape
        self._weights -= learning_rate * weight_gradients
        self._biases -= learning_rate * bias_gradients
