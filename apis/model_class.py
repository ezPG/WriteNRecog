import torch.nn as nn

class cnn(nn.Module):
  def __init__(self):
    super().__init__()
    self.c1 = nn.Conv2d(1,22,3)
    self.c2 = nn.Conv2d(22,16,3)
    self.c3 = nn.Conv2d(16,10,3)
  
    self.flatten = nn.Flatten()
    self.fc1 = nn.LazyLinear(512)
    self.o1 = nn.Linear(512,10)
    self.relu = nn.ReLU()
    self.softmax = nn.Softmax(dim = 1)

  def forward(self,ip):
    a = self.relu(self.c1(ip))
    a = self.relu(self.c2(a))
    a = self.relu(self.c3(a))
    
    ft = self.flatten(a)
    a = self.relu(self.fc1(ft))
    a = self.softmax(self.o1(a))

    return a

def make_model():
  obj = cnn()
  return obj