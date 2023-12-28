import numpy as np
from layers import Dense
from errors import Error


class Sequential:
    def __init__(self, layers: list[Dense]) -> None:
        """
        :param layers: the layers of the neural network.
        """
        self._layers = layers
    
    def compile(self, error: Error, learning_rate=0.001, regularization=0.001) -> None:
        """
        :param error: the model's cost function.
        :param learning_rate: the model's learning rate.
        :param regularization: the model's regularization parameter.
        """
        self._error = error
        self._learning_rate = learning_rate
        self._regularization = regularization
    
    def predict(self, X: np.ndarray) -> np.ndarray:
        """
        Predicts the outputs of the model for the specified inputs.
        :param X: examples to perform forward propagation (inference) on.
        """
        values = X
        for layer in self._layers:
            n = values.shape[1]  # The number of features
            assert n == layer.input_units
            values = layer.forward(values)
        return values
    
    def predict_with_history(self, X: np.ndarray) -> list[np.ndarray]:
        value_history = [X]
        values = X
        for layer in self._layers:
            n = values.shape[1]  # The number of features
            assert n == layer.input_units
            values = layer.forward(values)
            value_history.append(values)
        return value_history
    
    def fit(self, X: list[np.ndarray], y: list[np.ndarray], epochs: int) -> list[np.int32]:
        """
        Trains the model.
        :param X: features to train the model on (in batches). Each batch should have a shape (number of training examples, number of features).
        :param y: targets to train the model on (in batches). Each batch should have a shape (number of training examples, number of outputs).
        :returns: the cost at each epoch.
        """
        m = len(X)  # The number of batches
        cost_history = list()
        for i in range(epochs):
            cost = 0
            for batch_index in range(len(X)):
                X_batch = X[batch_index]
                y_batch = y[batch_index]

                output_history = self.predict_with_history(X_batch)
                outputs = output_history[-1]
                losses = self._error.get_loss(outputs, y_batch)
                cost += self._error.get_cost(losses)

                # Back propagation
                output_gradients = self._error.get_gradients(outputs, y_batch)
                for layer in reversed(self._layers):
                    output_history.pop()
                    weight_gradients, bias_gradients = layer.get_weight_gradients(output_history[-1], output_gradients, self._regularization)
                    input_gradients = layer.get_input_gradients(output_gradients)
                    layer.update_weights(weight_gradients, bias_gradients, self._learning_rate)
                    output_gradients = input_gradients

            cost /= 2 * m
            cost_history.append(cost)
            print(f"Epoch #{i}: Cost = {cost[0]}")
        
        return cost_history
