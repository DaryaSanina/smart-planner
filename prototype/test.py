from ml_prediction import KMeansTaskClassifier
import numpy as np
import matplotlib.pyplot as plt

data = np.random.randint(0, 20, size=(40, 2))
plt.scatter(data[:, 0], data[:, 1])

classifier = KMeansTaskClassifier(data, 4)
classifier.generate_centroids()

plt.scatter(classifier.centroids.data[:, 0], classifier.centroids.data[:, 1])
plt.show()

_ = input()
classifier.cluster(iterations=1000)

centroids = classifier.centroids
print(centroids)
print(classifier.clusters)
plt.scatter(data[:, 0], data[:, 1], c=classifier.clusters.data)
plt.scatter(centroids.data[:, 0], centroids.data[:, 1], c=list(range(centroids.data.shape[0])))
plt.show()
