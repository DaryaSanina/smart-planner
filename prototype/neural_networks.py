import numpy as np
from layers import Dense
from errors import Error


class Sequential:
    def __init__(self, layers: list[Dense]) -> None:
        """
        :param layers: the layers of the neural network.
        """
        self._layers = layers
    
    def compile(self, error: Error, learning_rate=0.001) -> None:
        """
        :param 
        """
        self._error = error
        self._learning_rate = learning_rate
    
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
    
    def fit(self, X: list[np.ndarray], y: list[np.ndarray], epochs: int) -> list[np.int32]:
        """
        Trains the model.
        :param X: features to train the model on (in batches). Each batch should have a shape (number of training examples, number of features).
        :param y: targets to train the model on (in batches). Each batch should have a shape (number of training examples, number of outputs).
        :returns: the cost at each epoch.
        """
        m = X.shape[0]  # The number of training examples
        cost_history = list()
        for i in range(epochs):
            cost = 0
            for batch_index in range(len(X)):
                X_batch = X[batch_index]
                y_batch = y[batch_index]

                outputs = self.predict(X_batch)
                losses = self._error.get_loss(outputs, y_batch)
                cost += self._error.get_cost(losses)

                # Back propagation
                output_gradients = self._error.get_gradients(outputs, y_batch)
                for layer in reversed(self._layers):
                    weight_gradients, bias_gradients = layer.get_weight_gradients(output_gradients)
                    input_gradients = layer.get_input_gradients(output_gradients)
                    layer.update_weights(weight_gradients, bias_gradients, self._learning_rate)
                    output_gradients = input_gradients

            cost /= 2 * m
            cost_history.append(cost)
            print(f"Epoch #{i}: Cost = {cost}")
        
        return cost_history
