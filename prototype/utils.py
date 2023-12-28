import numpy as np
from nltk import word_tokenize, WordNetLemmatizer


def relu(x: np.ndarray) -> np.ndarray:
    """
    Perfroms the relu function on each element of a numpy array. The relu function returns the original number if it is > 0, otherwise returns 0.
    :param x: the numpy array to compute relu for.
    :returns: the result of the relu operation on x.
    """
    return x * (x > 0)


def relu_derivative(x: np.ndarray) -> np.ndarray:
    """
    Computes the value of the derivative of the relu function for each element of a numpy array.
    :param x: the numpy array to compute the derivative of relu for.
    :returns: the result of applying the relu derivative to x.
    """
    return x > 0


def get_batches(X: np.ndarray, y: np.ndarray, batch_size) -> (list[np.ndarray], list[np.ndarray]):
        """
        Divides the training examples into batches.
        :param X: features of the training examples.
        :param y: targets of the training examples.
        :param batch_size: number of training examples in a batch.
        :returns X_batches: features of the training examples divided into batches.
        :returns y_batches: targets of the training examples divided into batches.
        """
        m = X.shape[0]  # The number of training examples
        X_batches = list()
        y_batches = list()
        for batch_index in range(m // batch_size):
            X_batches.append(X[batch_size * batch_index: batch_size * (batch_index + 1)])
            y_batches.append(y[batch_size * batch_index: batch_size * (batch_index + 1)])
        if m % batch_size != 0:
            X_batches.append(X[batch_size * (m // batch_size):])
            y_batches.append(y[batch_size * (m // batch_size):])
        return X_batches, y_batches


def preprocess_data(examples: list[str]) -> list[list[str]]:
    tokens = [word_tokenize(example) for example in examples]
    stemmer = WordNetLemmatizer()
    stemmed_tokens = [[stemmer.lemmatize(token.lower()) for token in example] for example in tokens]
    return stemmed_tokens


class BagOfWords:
    def __init__(self, vocabulary: list) -> None:
        """
        Creates a bag of words vocabulary based on the training examples.
        :param training_examples: a list of training examples where each example is a list of words.
        """
        self.vocabulary = vocabulary
    
    def encode(self, examples: list[list[str]]) -> np.ndarray:
        """
        Converts the training examples into numbers using the bag of words method.
        :param examples: a list of training examples where each example is a list of words.
        :returns: training examples encoded using the bag of words method.
        """
        encoded_examples = list()
        for example in examples:
            encoded_example = np.zeros(len(self.vocabulary))
            for word in example:
                if word in self.vocabulary:
                    encoded_example[self.vocabulary.index(word)] = 1
            encoded_examples.append(encoded_example)

        encoded_examples = np.asarray(encoded_examples)
        return encoded_examples   
