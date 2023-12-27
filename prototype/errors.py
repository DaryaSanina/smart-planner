import numpy as np
from numpy import int32, ndarray


class Error:
    def __init__(self) -> None:
        pass

    def get_loss(self, model_output: np.ndarray, target: np.ndarray) -> np.ndarray:
        """
        :param model_output: the output of the model with shape (number of examples, number of outputs).
        :param target: the target with shape (number of examples, number of outputs).
        :returns: the result of the loss function applied to each output.
        """
        assert model_output.shape == target.shape
        return np.zeros(target.shape)
    
    def get_cost(self, losses: np.ndarray) -> np.ndarray:
        """
        :param loss: the result of the loss function with shape (number of examples, number of outputs).
        :returns: the result of the cost function with shape (number of outputs).
        """
        return np.zeros((losses.shape[1]))

    def get_gradients(self, model_output: np.ndarray, target: np.ndarray) -> np.ndarray:
        """
        :param model_output: the output of the model with shape (number of examples, number of outputs).
        :param target: the target with shape (number of examples, number of outputs).
        :returns: the result of the derivative of the loss function applied to each output.
        """
        assert model_output.shape == target.shape
        return np.zeros(target.shape)


class MeanSquaredError(Error):
    def __init__(self) -> None:
        super().__init__()
    
    def get_loss(self, model_output: np.ndarray, target: np.ndarray) -> np.ndarray:
        super().get_loss(model_output, target)
        return (model_output - target) ** 2
    
    def get_cost(self, losses: np.ndarray) -> np.ndarray:
        super().get_cost(losses)
        m = losses.shape[0]  # The number of examples
        return 1 / (2 * m) * np.sum(losses, axis=0)
    
    def get_gradients(self, model_output: ndarray, target: ndarray) -> np.ndarray:
        super().get_gradients(model_output, target)
        m = model_output.shape[0]  # The number of examples
        return 1 / m * (model_output - target)
