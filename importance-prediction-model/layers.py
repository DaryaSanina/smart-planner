import cupy as np
from autograd import Tensor


class Layer:
    """
    Represents a layer of a neural network. It is an abstract class that acts as a parent to all types of layers.

    Attributes
    ----------
    parameters : list[Tensor]
        The layer's parameters.
    """

    def __init__(self) -> None:
        self.parameters = list()
    
    def get_parameters(self) -> list[Tensor]:
        return self.parameters


class Linear(Layer):
    """
    Represents a linear layer of a neural network.

    Attributes
    ----------
    weight : Tensor
        The layer's weights.
    bias : Tensor
        The layer's bias.
    parameters : list[Tensor]
        The layer's parameters (a combination of weight and bias).
    """

    def __init__(self, n_inputs: int, n_outputs: int, bias: bool = True) -> None:
        """
        Parameters
        ----------
        n_inputs : int
            The number of inputs of the layer.
        n_outputs : int
            The number of outputs of the layer.
        bias : bool
            Whether the layer should include bias.
        """
        super().__init__()
        W = np.random.randn(n_inputs, n_outputs) * np.sqrt(2.0 / n_inputs)
        self.weight = Tensor(W, autograd=True)
        self.bias = Tensor(np.zeros(n_outputs), autograd=True)

        self.parameters.append(self.weight)

        if bias:
            self.parameters.append(self.bias)
    
    def forward(self, input: Tensor) -> Tensor:
        """
        Performs forward propagation on this layer.

        Parameters
        ----------
        input : Tensor
            The layer's input.
        
        Returns
        -------
        Tensor
            The layer's output.
        """
        return input @ self.weight + self.bias.expand(0, len(input.data))


class Embedding(Layer):
    """
    Represents an embedding layer of a neural network.

    Attributes
    ----------
    vocab_size : int
        The size of the vocabulary (the number of vectors).
    dim : int
        The number of dimensions of each vector.
    weight : int
        The layer's weights.
    parameters : list[Tensor]
        The layer's parameters.
    """

    def __init__(self, vocab_size: int, dim: int) -> None:
        super().__init__()

        self.vocab_size = vocab_size
        self.dim = dim

        weight = (np.random.rand(vocab_size, dim) - 0.5) / dim
        self.weight = Tensor(weight, autograd=True)
        self.parameters.append(self.weight)
    
    def forward(self, input: Tensor) -> Tensor:
        """
        Performs forward propagation on the embedding layer.

        Parameters
        ----------
        input : Tensor
            The layer's input (one-hot encoded words).
        
        Returns
        -------
        Tensor
            The layer's output (word vectors).
        """
        return self.weight[Tensor(np.asarray([np.argmax(input.data)]))]


class Sequential(Layer):
    """
    Represents a sequence of layers of a neural network.

    Attributes
    ----------
    layers : list[Layer]
        A list of neural network layers.
    parameters : list[Tensor]
        The parameters of each layer.
    """

    def __init__(self, layers: list[Layer] = list()) -> None:
        super().__init__()
        self.layers = layers
    
    def add(self, layer: Layer) -> None:
        """
        Adds a layer to the sequence.

        Parameters
        ----------
        layer : Layer
            The layer to add to the sequence.
        """
        self.layers.append(layer)
    
    def forward(self, input: Tensor) -> Tensor:
        """
        Performs forward propagation on the layer sequence.

        Parameters
        ----------
        input : Tensor
            The input to the sequential layer.
        
        Returns
        -------
        Tensor
            The output of the sequential layer.
        """
        for layer in self.layers:
            input = layer.forward(input)
        return input
    
    def get_parameters(self) -> list[Tensor]:
        params = list()
        for layer in self.layers:
            params += layer.get_parameters()
        return params


class MSELoss(Layer):
    """
    Represents the Mean Squared Error loss function.
    """

    def __init__(self) -> None:
        super().__init__()
    
    def forward(self, prediction: Tensor, target: Tensor) -> Tensor:
        """
        Calculates the Mean Squared Error of a prediction.

        Parameters
        ----------
        prediction : Tensor
            The prediction.
        target : Tensor
            The target values. They should have the same shape as 'prediction'.
        
        Returns
        -------
        Tensor
            The value of the Mean Squared Error loss.
        """
        return ((prediction - target) * (prediction - target)).sum(0)


class CrossEntropyLoss(Layer):
    """
    Represents the Cross-entropy loss function.
    """

    def __init__(self) -> None:
        super().__init__()
    
    def forward(self, prediction: Tensor, target: Tensor) -> Tensor:
        """
        Calculates the Cross-entropy loss of a prediction.

        Parameters
        ----------
        prediction : Tensor
            The prediction.
        target : Tensor
            The indices of the target values. They should have the same shape as 'prediction'.
        
        Returns
        -------
        Tensor
            The value of the Cross-entropy loss.
        """
        return prediction.cross_entropy(target)


class Sigmoid(Layer):
    """
    Represents the sigmoid activation function.
    """

    def __init__(self) -> None:
        super().__init__()
    
    def forward(self, input: Tensor) -> Tensor:
        """
        Applies the sigmoid activation function to the input.

        Parameters
        ----------
        input : Tensor
            The input to the sigmoid function (the logits).
        
        Returns
        -------
        Tensor
            The result of applying the sigmoid activation function to the logits.
        """
        return input.sigmoid()


class Tanh(Layer):
    """
    Represents the tanh activation function.
    """

    def __init__(self) -> None:
        super().__init__()
    
    def forward(self, input: Tensor) -> Tensor:
        """
        Applies the tanh activation function to the input.

        Parameters
        ----------
        input : Tensor
            The input to the tanh function (the logits).
        
        Returns
        -------
        Tensor
            The result of applying the tanh activation function to the logits.
        """
        return input.tanh()


class Relu(Layer):
    """
    Represents the ReLU activation function.
    """

    def __init__(self) -> None:
        super().__init__()
    
    def forward(self, input: Tensor) -> Tensor:
        """
        Applies the ReLU activation function to the input.

        Parameters
        ----------
        input : Tensor
            The input to the ReLU function (the logits).
        
        Returns
        -------
        Tensor
            The result of applying the ReLU activation function to the logits.
        """
        return input.relu()


class RNNCell(Layer):
    """
    Represents a RNN (Recurrent Neural Network) cell.

    Attributes
    ----------
    n_inputs : int
        The number of inputs to the cell.
    n_hidden : int
        The number of hidden neurons in the cell.
    n_outputs : int
        The number of outputs of the cell.
    activation : Layer
        The activation function applied to the hidden layer before passing its result to the output layer.
    w_ih : Linear
        The weight matrix from the input layer to the hidden layer.
    w_hh : Linear
        The weight matrix from one hidden state to the next.
    w_ho : Linear
        The weight matrix from the hidden layer to the output layer.
    parameters : list[Tensor]
        The cell's parameters (a combination of the parameters of w_ih, w_hh and w_ho)
    """

    def __init__(self, n_inputs: int, n_hidden: int, n_outputs: int, activation: str) -> None:
        """
        Raises
        ------
        Exception
            If the activation is neither "sigmoid" nor "tanh" nor "relu".
        """
        super().__init__()

        self.n_inputs = n_inputs
        self.n_hidden = n_hidden
        self.n_outputs = n_outputs

        if activation == 'sigmoid':
            self.activation = Sigmoid()
        elif activation == 'tanh':
            self.activation = Tanh()
        elif activation == 'relu':
            self.activation = Relu()
        else:
            raise Exception("Non-linearity not found")
        
        self.w_ih = Linear(n_inputs, n_hidden)
        self.w_hh = Linear(n_hidden, n_hidden)
        self.w_ho = Linear(n_hidden, n_outputs)

        self.parameters += self.w_ih.get_parameters()
        self.parameters += self.w_hh.get_parameters()
        self.parameters += self.w_ho.get_parameters()
    
    def forward(self, input: Tensor, hidden: Tensor) -> tuple[Tensor, Tensor]:
        """
        Performs forward propagation on the RNN cell.

        Parameters
        ----------
        input : Tensor
            The input to the cell.
        hidden : Tensor
            The hidden layer from the previous cell.
        
        Returns
        -------
        output : Tensor
            This cell's output.
        new_hidden : Tensor
            This cell's hidden layer.
        """
        from_previous_hidden = self.w_hh.forward(hidden)
        combined = self.w_ih.forward(input) + from_previous_hidden
        new_hidden = self.activation.forward(combined)
        output = self.w_ho.forward(new_hidden)
        return output, new_hidden
    
    def init_hidden(self, batch_size: int = 1) -> Tensor:
        """
        Initialises a hidden layer to be inputted to the first cell with 0s.

        Parameters
        ----------
        batch_size : int
            The cell's batch size.
        
        Returns
        -------
        Tensor
            A tensor of shape (batch_size, n_hidden) initialised with 0s.
        """
        return Tensor(np.zeros((batch_size, self.n_hidden)), autograd=True)


class LSTMCell(Layer):
    """
    Represents a LSTM (Long Short-Term Memory) cell.

    Attributes
    ----------
    n_inputs : int
        The number of inputs to the cell.
    n_hidden : int
        The number of hidden neurons in the cell.
    n_outputs : int
        The number of outputs of the cell.
    input_to_forgetting_gate : Linear
        A linear layer mapping the input to the forgetting gate.
    input_to_input_gate : Linear
        A linear layer mapping the input to the input gate.
    input_to_output_gate : Linear
        A linear layer mapping the input to the output gate.
    input_to_update_gate : Linear
        A linear layer mapping the input to the update gate.
    hidden_to_forgetting_gate : Linear
        A linear layer (without bias) mapping the hidden layer to the forgetting gate.
    hidden_to_input_gate : Linear
        A linear layer (without bias) mapping the hidden layer to the input gate.
    hidden_to_output_gate : Linear
        A linear layer (without bias) mapping the hidden layer to the output gate.
    hidden_to_update_gate : Linear
        A linear layer (without bias) mapping the hidden layer to the update gate.
    parameters : list[Tensor]
        A combination of all the parameters of this cell.
    """
    def __init__(self, n_inputs, n_outputs) -> None:
        super().__init__()

        self.n_inputs = n_inputs
        self.n_outputs = n_outputs

        self.input_to_forgetting_gate = Linear(n_inputs, n_outputs)
        self.input_to_input_gate = Linear(n_inputs, n_outputs)
        self.input_to_output_gate = Linear(n_inputs, n_outputs)
        self.input_to_update_gate = Linear(n_inputs, n_outputs)
        self.hidden_to_forgetting_gate = Linear(n_outputs, n_outputs, bias=False)
        self.hidden_to_input_gate = Linear(n_outputs, n_outputs, bias=False)
        self.hidden_to_output_gate = Linear(n_outputs, n_outputs, bias=False)
        self.hidden_to_update_gate = Linear(n_outputs, n_outputs, bias=False)

        self.parameters += self.input_to_forgetting_gate.get_parameters()
        self.parameters += self.input_to_input_gate.get_parameters()
        self.parameters += self.input_to_output_gate.get_parameters()
        self.parameters += self.input_to_update_gate.get_parameters()
        self.parameters += self.hidden_to_forgetting_gate.get_parameters()
        self.parameters += self.hidden_to_input_gate.get_parameters()
        self.parameters += self.hidden_to_output_gate.get_parameters()
        self.parameters += self.hidden_to_update_gate.get_parameters()
    
    def forward(self, input: Tensor, hidden: tuple[Tensor, Tensor]) -> tuple[Tensor, Tensor]:
        """
        Performs forward propagation on the LSTM cell.

        Parameters
        ----------
        input : Tensor
            The input to the cell.
        hidden : tuple[Tensor, Tensor]
            A tuple of length 2
            where the first value is a Tensor that represents the hidden hidden state vector of the previous cell,
            and the second value is a Tensor that represents the cell hidden state vector of the previous cell.
        
        Returns
        -------
        new_hidden : Tensor
            The cell's hidden hidden state vector.
        new_cell : Tensor
            The cell's cell hidden state vector.
        """
        previous_hidden = hidden[0]
        previous_cell = hidden[1]

        forgetting_gate = (self.input_to_forgetting_gate.forward(input) + self.hidden_to_forgetting_gate.forward(previous_hidden)).sigmoid()
        input_gate = (self.input_to_input_gate.forward(input) + self.hidden_to_input_gate.forward(previous_hidden)).sigmoid()
        output_gate = (self.input_to_output_gate.forward(input) + self.hidden_to_output_gate.forward(previous_hidden)).sigmoid()
        update_gate = (self.input_to_update_gate.forward(input) + self.hidden_to_update_gate.forward(previous_hidden)).tanh()
        new_cell = forgetting_gate * previous_cell + input_gate * update_gate
        self.new_cell_tanh = new_cell.tanh()
        new_hidden = output_gate * self.new_cell_tanh

        return new_hidden, new_cell
    
    def init_hidden(self) -> tuple[Tensor, Tensor]:
        """
        Initialises a hidden and a cell hidden states to be inputted to the first cell.

        Parameters
        ----------
        batch_size : int
            The cell's batch size.
        
        Returns
        -------
        hidden : Tensor
            A tensor of shape (batch_size, n_hidden) where the first element is 1 and the rest of the elements are 0.
        cell : Tensor
            A tensor of shape (batch_size, n_hidden) where the first element is 1 and the rest of the elements are 0.
        """
        hidden = Tensor(np.zeros((1, self.n_outputs)), autograd=True)
        cell = Tensor(np.zeros((1, self.n_outputs)), autograd=True)
        hidden.data[0] += 1
        cell.data[0] += 1
        return hidden, cell
