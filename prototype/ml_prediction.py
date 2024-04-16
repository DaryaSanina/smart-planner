import numpy as np
import pickle as pkl
import random

from autograd import Tensor


class TaskImportancePredictor:
    """
    This class is used to predict the importance of a task.

    Attributes
    ----------
    word2index: dict
        Maps a word to its index in the vocabulary.
    embedding: layers.Embedding
        An embedding layer of the neural network.
    model: layers.Sequential
        The main layers of the neural network.
    output_layer: layers.Linear
        The output layer of the neural network.
    tokens: list[int]
        A list of indices from the vocabulary that represents the prompt given to the model.
    """
    def __init__(self, text: str=None) -> None:
        with open('prototype/word2index.pkl', 'rb') as file:
            self.word2index = pkl.load(file)
        with open('prototype/importance_embedding.pkl', 'rb') as file:
            self.embedding = pkl.load(file)
        with open('prototype/importance_model.pkl', 'rb') as file:
            self.model = pkl.load(file)
        with open('prototype/importance_output.pkl', 'rb') as file:
            self.output_layer = pkl.load(file)
        
        if text is not None:
            self.load_tokens(text)
        else:
            self.tokens = None
    
    def load_tokens(self, text: str) -> None:
        """
        Assigns the tokens of this instance so that they match the text. Any words that are not in the vocabulary are removed.

        Parameters
        ----------
        text: str
            The prompt the model needs to perform inference on.
        """
        alphanumeric = ''.join([character if character.isalnum() else ' ' for character in text])
        word_tokens = [word for word in alphanumeric.split() if word != '']
        self.tokens = [self.word2index[word] for word in word_tokens if word in self.word2index.keys()]
    
    def predict(self) -> float:
        """
        Predicts the importance of a task based on the loaded prompt (task name + task description).

        Returns
        -------
        float:
            The importance of the task from 0 to 10.
        """
        assert self.tokens is not None, "You need to load the tokens of the input first (use the load_tokens method)."

        hidden = self.model.init_hidden(batch_size=1)
        for t in range(len(self.tokens)):
            input = Tensor([self.tokens[t]], autograd=True)
            lstm_input = self.embedding.forward(input=input)
            hidden = self.model.forward(input=lstm_input, hidden=hidden)
        output = self.output_layer.forward(hidden[0])

        return float(output.data)


class KMeansClassifier:
    """
    This class is used to cluster data points into a specified number of categories using the K Means algorithm.

    Attributes
    ----------
    data: Tensor
        The data to cluster (2D).
    k: int
        The number of clusters.
    centroids: Tensor
        The centroids of each cluster.
    clusters: Tensor
        The index of each data point's cluster.
    """
    def __init__(self, data_list: list[tuple[int, int]]=None, k: int=None) -> None:
        self.data = None
        self.k = None
        self.centroids = None
        self.clusters = None
        self.load_data(data_list, k)
    
    def load_data(self, data_list: list[tuple[int, int]]=None, k: int=None) -> None:
        """
        Loads the data and the number of clusters.

        Parameters
        ----------
        data_list: list[tuple[int, int]]
            A list representing the data in a 2D space.
        k: int
            The number of clusters.
        """
        if data_list is not None:
            self.data = Tensor(data_list)
            self.data.data = self.data.data.astype(np.float64)
        if k is not None:
            self.k = k
    
    def set_centroids(self, centroids: list[int]) -> None:
        """
        Sets the specified points to be the centroids.

        Parameters
        ----------
        centroids: list[int]
            The indices of the points to become centroids.
        
        Raises
        ------
        AssertionError:
            - if the data have not been loaded,
            - if the number of clusters has not been loaded,
            - if the number of centroids is not equal to the number of clusters,
            - if any value in the 'centroids' parameter is not an index of a point in the dataset.
        """
        assert self.data is not None, "You need to load the data first."
        assert self.k is not None, "You need to specify the number of clusters first."
        assert len(centroids) == self.k, "The number of centroids is not equal to the number of clusters."
        for centroid in centroids:
            assert 0 <= centroid < self.data.data.shape[0], "The centroids should represent indices of the data points."
        self.centroids = Tensor(self.data.data[centroids])
    
    def generate_centroids(self, seed: int=None) -> None:
        """
        Randomly selects k different points from the dataset to be cluster centroids.

        Parameters
        ----------
        seed: int
            The seed to use for random generation.
        
        Raises
        ------
        AssertionError:
            - if the data have not been loaded,
            - if the number of clusters has not been loaded.
        """
        assert self.data is not None, "You need to load the data first."
        assert self.k is not None, "You need to specify the number of clusters first."

        if seed is not None:
            random.seed(seed)

        indices = list(range(self.data.data.shape[0]))
        self.set_centroids(random.sample(indices, k=self.k))
    
    def cluster(self, iterations: int=1000) -> tuple[Tensor, Tensor]:
        """
        Performs the K Means clustering algorithm on the data.

        Parameters
        ----------
        iterations: int
            The number of iterations of the algorithm.
        
        Returns
        -------
        Tensor:
            The clusters the points have been divided into.
        Tensor:
            The coordinates of the centroids of each cluster.
        """
        self.clusters = Tensor(np.zeros(self.data.data.shape[0]))
        for _ in range(iterations):
            # Assign points to clusters based on the closest centroid
            for i in range(self.data.data.shape[0]):
                min_distance = -1
                for centroid_index in range(self.k):
                    distance = ((self.centroids.data[centroid_index] - self.data.data[i]) ** 2).sum()  # Euclidean distance
                    if min_distance == -1 or distance < min_distance:
                        min_distance = distance
                        self.clusters.data[i] = centroid_index
            
            # Update the coordinates of the centroids to be the mean of its points
            for i in range(self.centroids.data.shape[0]):
                self.centroids.data[i] = np.sum(self.data.data * np.tile(self.clusters.data == i, (1, 2)).reshape(-1, 2), axis=0)
                self.centroids.data[i] /= np.sum((self.clusters.data == i).astype(np.float64)) + 1e-5
                if np.nan in self.centroids.data[i]:
                    self.centroids.data[i] = np.zeros(self.centroids.data[i].shape)
        
        return self.clusters, self.centroids