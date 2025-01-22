import cupy as np
from autograd import Tensor


class Adam:
    """
    Implements the Adam optimisation algorithm.

    Attributes
    ----------
    parameters : list[Tensor]
        The model's parameters.
    alpha : float
        The model's learning rate.
    """
    def __init__(self, parameters: list[Tensor], alpha: float = 0.001, beta1: float = 0.9, beta2: float = 0.999, epsilon: float = float(10)**(-8)) -> None:
        self.parameters = parameters
        self.alpha = alpha
        self.beta1 = beta1
        self.beta2 = beta2
        self.epsilon = epsilon
    
    def zero(self) -> None:
        """
        Resets the parameters' gradients.
        """
        for p in self.parameters:
            p.grad = Tensor(np.zeros_like(p.grad))
    
    def step(self, timestep: int, moment1: list[np.ndarray], moment2: list[np.ndarray], zero=True) -> tuple[np.ndarray, np.ndarray]:
        """
        Updataes the model's parameters.

        Parameters
        ----------
        timestep : int
            The number of times the gradients have been updated + 1
        moment1 : np.ndarray
            1st moment tensor
        moment2 : np.ndarray
            2nd moment tensor
        zero : bool
            Whether the parameters' gradients should be reset after this step.
        
        Returns
        -------
        moment1 : np.ndarray
            The value of moment1 to use for the next step
        moment2 : np.ndarray
            The value of moment2 to use for the next step
        """
        for i in range(len(self.parameters)):
            gradients = self.parameters[i].grad.data.astype("float64")  # Get gradients w.r.t. stochastic objective at the current timestep
            moment1[i] = moment1[i] * self.beta1 + (1 - self.beta1) * gradients  # Update biased first moment estimate
            moment2[i] = moment2[i] * self.beta2 + (1 - self.beta2) * (gradients * gradients)  # Update biased second raw moment estimate
            bias_corrected_moment1 = moment1[i] / (1 - pow(self.beta1, timestep))  # Compute bias-corrected first moment estimate
            bias_corrected_moment2 = moment2[i] / (1 - pow(self.beta2, timestep))  # Compute bias-corrected second raw moment estimate
            self.parameters[i].data -= bias_corrected_moment1 * self.alpha / (np.sqrt(bias_corrected_moment2) - self.epsilon)  # Update parameters
            if zero:
                self.parameters[i].grad = Tensor(np.zeros_like(self.parameters[i].grad.data))
        
        return moment1, moment2
