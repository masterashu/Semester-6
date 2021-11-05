"""Softmax model."""

import numpy as np

# Ashutosh Chauhan: S20180010017
# Ayush Gairola: S20180010020
# Pradum Singh: S20180010136
# Vipul Rawat: S20180010192
class Softmax:
    def __init__(self, n_class: int, lr: float, epochs: int, reg_const: float):
        """Initialize a new classifier.

        Parameters:
            n_class: the number of classes
            lr: the learning rate
            epochs: the number of epochs to train for
            reg_const: the regularization constant
        """
        self.lr = lr
        self.epochs = epochs
        self.reg_const = reg_const
        self.n_class = n_class

    def calc_gradient(self, X_train: np.ndarray, y_train: np.ndarray) -> np.ndarray:
        """Calculate gradient of the softmax loss.

        Inputs have dimension D, there are C classes, and we operate on
        mini-batches of N examples.

        Parameters:
            X_train: a numpy array of shape (N, D) containing a mini-batch
                of data
            y_train: a numpy array of shape (N,) containing training labels;
                y[i] = c means that X[i] has label c, where 0 <= c < C

        Returns:
            gradient with respect to weights w; an array of same shape as w
        """
        #Calculating Cross entropy loss
        dW = np.zeros_like(self.w)
        num_train = X_train.shape[0]
        X = X_train
        z = np.dot(X, self.w)
        # print("\noriginal z", z)
        z -= np.max(z, axis=1, keepdims=True) 
        # print("\nchanged z",z)
        p = np.exp(z) / np.sum(np.exp(z), axis=1, keepdims=True) # Softmax function 2x4874(p)
        L = np.sum(-np.log(p[np.arange(num_train), y_train]))
        L /= num_train
        R = np.sum(self.w * self.w)
        loss = L + R * self.reg_const

        #Calculation of Grad
        p[np.arange(num_train), y_train] -= 1
        dW = (1/num_train) * X.T.dot(p) + (self.reg_const * 2 * self.w)
        return loss, dW
        # return loss

    def train(self, X_train: np.ndarray, y_train: np.ndarray):
        """Train the classifier.

        Hint: operate on mini-batches of data for SGD.

        Parameters:
            X_train: a numpy array of shape (N, D) containing training data;
                N examples with D dimensions
            y_train: a numpy array of shape (N,) containing training labels
        """
        
        x = X_train 
        N = x.shape[0]
        dim = x.shape[1]
        loss_calc = []
        self.w = np.random.randn(dim,self.n_class) * 0.0001
        batch_size = 200
        for itr in range(1, self.epochs+1):
          X_batch = None
          y_batch = None
          batch_indices = np.random.choice(N, batch_size, replace=False)
          X_batch = X_train[batch_indices]
          y_batch = y_train[batch_indices]
            
          loss, grad = self.calc_gradient(X_batch, y_batch)
          loss_calc.append(loss)
          
          if itr % 100 == 0:
            print(f"\nLoss in epoch {itr} is {loss}")
          # print(f"\nGrad in epoch {itr} is {grad}")
          self.w -= self.lr * grad 
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
        # TODO: implement me
        y = X_test.dot(self.w)
        y_pred = np.argmax(y, axis=1)
        # y_pred = y_pred.reshape((len(y_pred),1))
        return y_pred
