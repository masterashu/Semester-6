"""Support Vector Machine (SVM) model."""

import numpy as np
from random import random
from sklearn.utils import shuffle

# Ashutosh Chauhan: S20180010017
# Ayush Gairola: S20180010020
# Pradum Singh: S20180010136
# Vipul Rawat: S20180010192
class SVM:
    def __init__(self, n_class: int, lr: float, epochs: int, reg_const: float):
        """Initialize a new classifier.

        Parameters:
            n_class: the number of classes
            lr: the learning rate
            epochs: the number of epochs to train for
            reg_const: the regularization constant
        """
        self.alpha = lr
        self.epochs = epochs
        self.reg_const = reg_const
        self.n_class = n_class
        

    def calc_gradient(self, X_train: np.ndarray, y_train: np.ndarray) -> np.ndarray:
        """Calculate gradient of the svm hinge loss.

        Inputs have dimension D, there are C classes, and we operate on
        mini-batches of N examples.

        Parameters:
            X_train: a numpy array of shape (N, D) containing a mini-batch
                of data
            y_train: a numpy array of shape (N,) containing training labels;
                y[i] = c means that X[i] has label c, where 0 <= c < C

        Returns:
            the gradient with respect to weights w; an array of the same shape
                as w
        """
        loss = 0.0
        dW = np.zeros(self.w.shape)
        num_train = X_train.shape[0]

        scores = X_train.dot(self.w)
        # print("cost shape = ", cost.shape)
        # correct_class_scores = cost[np.arange(num_train), y_train].reshape(num_train,1)
        correct_class_scores = np.choose(y_train, scores.T)
        # print("correct_cost shape = ", correct_class_scores.shape)
        margin = scores - correct_class_scores.reshape(correct_class_scores.shape[0],1) + 1
        margin[margin <= 0] = 0
        loss = np.sum(margin) - num_train
        loss /= num_train

        R = np.sum(self.w * self.w)
        loss += self.reg_const * R

        mask = np.zeros(margin.shape)
        mask[margin > 0] = 1
        valid_dist_count = margin.sum(axis = 1)
        mask[range(num_train), y_train] -= valid_dist_count
        dW = (X_train.T).dot(mask) / num_train
        dW += self.reg_const * 2 * self.w

        return loss, dW

    def train(self, X_train: np.ndarray, y_train: np.ndarray):
        """Train the classifier.

        Hint: operate on mini-batches of data for SGD.

        Parameters:
            X_train: a numpy array of shape (N, D) containing training data;
                N examples with D dimensions
            y_train: a numpy array of shape (N,) containing training labels
        """
        num_train = X_train.shape[0]
        x_size = X_train.shape[1]
        self.w = np.random.randn(x_size, self.n_class) * 0.001 # Initialize random weights
        # print('W', self.w.shape)
        batch_size = 200
        loss_calc = []
        for epoch in range(1, self.epochs + 1):
            X_batch = None
            y_batch = None
            X, y = shuffle(X_train, y_train)
            batch_indices = np.random.choice(num_train, batch_size, replace=False)
            X_batch = X[batch_indices]
            y_batch = y[batch_indices]
            loss, grad = self.calc_gradient(X_batch, y_batch)
            loss_calc.append(loss)
            if epoch % 100 == 0:
                print(f"\nLoss in epoch {epoch} is {loss}")
            self.w -= (self.alpha * grad)
        print(self.w)
        return

    def predict(self, X_test: np.ndarray) -> np.ndarray:
        """Use the trained weights to predict labels for test data points.

        Parameters:
            X_test: a numpy array of shape (N, D) containing testing data;
                N examples with D dimensions

        Returns:
            predicted labels for the data in X_test; a 1-dimensional array of
                length N, where each element is an integer giving the predicted
                class.
        """
        # print(np.sign(X_test @ self.w).shape)
        y_pred = np.zeros(X_test.shape[0])
        y = X_test.dot(self.w)
        y_pred = y.argmax(axis=1)
        return y_pred
