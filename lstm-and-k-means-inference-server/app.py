from fastapi import FastAPI
from fastapi.responses import JSONResponse
import uvicorn
from mangum import Mangum
from pydantic import BaseModel
import numpy as np
import random
from autograd import Tensor

app = FastAPI()
handler = Mangum(app)


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


class Data(BaseModel):
    data: list[list[int]]


@app.get('/')
def default():
    return JSONResponse("Nothing here.")


@app.post('/k_means')
def run(data: Data):
    print(data)
    try:
        print(1)
        data = [list(task) for task in data.data]
        print(data)
        classifier = KMeansClassifier(data_list=data, k=4)
        classifier.generate_centroids()
        clusters, centroids = classifier.cluster()
        print(clusters, centroids)

        high_importance_clusters = list(sorted(list(range(4)), key=lambda x: centroids.data[int(x)][0], reverse=True))[:2]
        important_urgent_cluster = min(high_importance_clusters, key=lambda x: centroids.data[int(x)][1])
        important_not_urgent_cluster = max(high_importance_clusters, key=lambda x: centroids.data[int(x)][1])

        low_importance_clusters = list(sorted(list(range(4)), key=lambda x: centroids.data[int(x)][0], reverse=True))[2:]
        not_important_urgent_cluster = min(low_importance_clusters, key=lambda x: centroids.data[int(x)][1])
        not_important_not_urgent_cluster = max(low_importance_clusters, key=lambda x: centroids.data[int(x)][1])

        important_urgent_order = [i for i in range(len(data)) if clusters.data[i] == important_urgent_cluster]
        important_not_urgent_order = [i for i in range(len(data)) if clusters.data[i] == important_not_urgent_cluster]
        not_important_urgent_order = [i for i in range(len(data)) if clusters.data[i] == not_important_urgent_cluster]
        not_important_not_urgent_order = [i for i in range(len(data)) if clusters.data[i] == not_important_not_urgent_cluster]

        order = important_urgent_order + important_not_urgent_order + not_important_urgent_order + not_important_not_urgent_order

        return JSONResponse(order)
    
    except Exception as e:
        print(e)
        return JSONResponse(str(e), status_code=500)


if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000, log_config="log.ini")