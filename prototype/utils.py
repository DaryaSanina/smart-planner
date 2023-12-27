import numpy as np


def relu(x: np.ndarray):
    """
    Perfroms the relu function on each element of a numpy array. The relu function returns the original number if it is > 0, otherwise returns 0.
    :param x: the numpy array to compute relu for.
    :returns: the result of the relu operation on x.
    """
    return x * (x > 0)
