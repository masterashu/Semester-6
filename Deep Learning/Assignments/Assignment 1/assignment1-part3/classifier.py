import torch
import torch.nn as nn
from torch.autograd import Variable
import torch.nn.functional as F
from torch import optim
import numpy as np

NUM_CLASSES = 21

class SimpleClassifier(nn.Module):
    def __init__(self):
        super(SimpleClassifier, self).__init__()
        self.conv1 = nn.Conv2d(3, 64, 5)
        self.conv2 = nn.Conv2d(64, 32, 3)
        self.conv3 = nn.Conv2d(32, 16, 3)
        self.pool = nn.MaxPool2d(2, 2)
        self.fc1 = nn.Linear(16 * 26 * 26, 120)
        self.fc2 = nn.Linear(120, 84)
        self.fc3 = nn.Linear(84, NUM_CLASSES)

    def forward(self, x):
        x = self.pool(F.relu(self.conv1(x)))
        x = self.pool(F.relu(self.conv2(x)))
        x = self.pool(F.relu(self.conv3(x)))
        x = x.view(x.size()[0], 16 * 26 * 26)
        x = F.relu(self.fc1(x))
        x = F.relu(self.fc2(x))
        x = self.fc3(x)
        return x

class ResBlock(nn.Module):
    def __init__(self, in_channels, out_channels, stride=1):
        """
        Args:
          in_channels (int):  Number of input channels.
          out_channels (int): Number of output channels.
          stride (int):       Controls the stride.
        """
        super(ResBlock, self).__init__()

        self.skip = nn.Sequential()

        if stride != 1 or in_channels != out_channels:
          self.skip = nn.Sequential(
            nn.Conv2d(in_channels=in_channels, out_channels=out_channels, kernel_size=1, stride=stride, bias=False),
            nn.BatchNorm2d(out_channels))
        else:
          self.skip = None

        self.block = nn.Sequential(
            nn.Conv2d(in_channels=in_channels, out_channels=out_channels, kernel_size=3, padding=1, stride=1, bias=False),
            nn.BatchNorm2d(out_channels),
            nn.ReLU(),
            nn.Conv2d(in_channels=in_channels, out_channels=out_channels, kernel_size=3, padding=1, stride=1, bias=False),
            nn.BatchNorm2d(out_channels))

    def forward(self, x):
        identity = x
        out = self.block(x)

        if self.skip is not None:
            identity = self.skip(x)

        out += identity
        out = F.relu(out)

        return out

class Classifier(nn.Module):
    def __init__(self):
        super(Classifier, self).__init__()
        self.conv1 = nn.Conv2d(3, 32, 3, stride=1)
        self.conv1b = nn.Conv2d(32, 32, 3, stride=2)
        # self.conv2a = nn.Conv2d(48, 32, 1)
        # self.conv2b = nn.Conv2d(32, 32, 5, stride=1, padding=2)
        # self.conv2c = nn.Conv2d(32, 256, 1)
        self.conv3a = nn.Conv2d(32, 64, 1)
        self.res = ResBlock(64, 64)
        self.conv3e = nn.Conv2d(64, 256, 1)
        self.pool = nn.MaxPool2d(3, 2)
        self.fc1 = nn.Linear(2*2*256, 200)
        self.fc2 = nn.Linear(200, 64)
        self.fc3 = nn.Linear(64, NUM_CLASSES)

    def forward(self, x):
        #print(x.size())
        x = self.conv1(x)
        x = F.relu(x)
        #print(x.size())
        x = self.pool(x)
        #print(x.size())
        x = self.conv1b(x)
        x = F.relu(x)
        #print(x.size())
        x = self.conv1b(x)
        x = F.relu(x)
        #print(x.size())
        x = self.pool(x)
        #print(x.size())
        x = self.conv3a(x)
        x = F.relu(x)
        #print(x.size())
        x = self.res(x)
        x = self.res(x)
        x = self.res(x)
        x = F.relu(x)
        #print(x.size())
        x = self.pool(x)
        #print(x.size())
        x = self.conv3e(x)
        x = F.relu(x)
        #print(x.size())
        x = self.pool(x)
        #print(x.size())
        x = x.view(x.size()[0], 2*2*256)
        x = F.relu(self.fc1(x))
        x = F.relu(self.fc2(x))
        x = self.fc3(x)
        return x
