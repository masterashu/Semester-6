import 'dart:isolate';
import 'dart:developer' as developer;

// Enabling Debug allows seeing the message transfer log
const bool DEBUG = bool.fromEnvironment('DEBUG', defaultValue: false);

enum NodeType { left, middle, right }

enum NodeState {
  waiting,
  done,
  recieved_one, // For the central node when it has recieved the value
}

enum MessageType {
  setup,
  sendData,
  receiveData,
  roundStart,
  roundEnd,
  query,
  queryResponse,
}

extension Str on MessageType {
  String get str => toString().split('.').last;
}

extension DebugPrint on SendPort {
  void sendMessage(Message message) {
    if (DEBUG) print('Isolate #${message.nodeIndex ?? '?'} | Sent Message: $message.');
    send(message);
  }
}

class Message {
  final MessageType type;
  final int nodeIndex;
  final int roundNo;
  final Object arg;
  final NodeType nodeType;
  final SendPort leftSendPort, rightSendPort;
  // final SendPort returnPort;

  Message(
    this.type, {
    // Setup
    this.nodeType,
    this.leftSendPort,
    this.rightSendPort,
    this.nodeIndex,
    // Round start event
    this.roundNo,
    // Message from other Nodes
    this.arg,
    // this.returnPort,
  });

  @override
  String toString() {
    return 'Message{type: ${type.str} ' +
        (arg == null ? '' : 'arg: $arg ') +
        (nodeIndex == null ? '' : 'nodeIndex: $nodeIndex ') +
        (roundNo == null ? '' : 'roundNo: $roundNo ') +
        (leftSendPort == null ? '' : 'leftSendPort: $leftSendPort ') +
        (rightSendPort == null ? '' : 'rightSendPort: $rightSendPort') +
        '}';
  }
}

void run(SendPort root) async {
  var port = ReceivePort();
  root.send(port.sendPort);

  SendPort leftSendPort, rightSendPort;
  NodeType type;
  int index;
  num stateVal;
  // State to know if the left/right Isolate has returned the value.
  int roundNo;
  NodeState lState, rState;
  num lVal, rVal;

  bool isAllValueReceived() {
    if (type == NodeType.left) return rState == NodeState.done;
    if (type == NodeType.right) return lState == NodeState.done;
    if (type == NodeType.middle) {
      return lState == NodeState.done && rState == NodeState.done;
    }
    throw Exception('Node Type cannot be null!');
  }

  void lStateDone() => lState = NodeState.done;
  void lStateWaiting() => lState = NodeState.waiting;
  void rStateDone() => rState = NodeState.done;
  void rStateWaiting() => rState = NodeState.waiting;

  await for (Message msg in port) {
    developer.log('Isolate #${index ?? '?'} | Received Message: $msg.');
    if (msg.type == MessageType.setup) {
      // Setup Message
      type = msg.nodeType;
      index = msg.nodeIndex;
      stateVal = msg.arg;
      if (type == NodeType.right) leftSendPort = msg.leftSendPort;
      if (type == NodeType.left) rightSendPort = msg.rightSendPort;
      if (type == NodeType.middle) {
        leftSendPort = msg.leftSendPort;
        rightSendPort = msg.rightSendPort;
      }
      root.sendMessage(Message(MessageType.roundEnd, nodeIndex: index, roundNo: -1));
    } else if (msg.type == MessageType.roundStart) {
      // Send message to left and right Isolate Round.
      roundNo = msg.roundNo;
      if (msg.roundNo % 3 == (index - 1) % 3) {
        if (type == NodeType.right || type == NodeType.middle) {
          leftSendPort.sendMessage(Message(MessageType.sendData, arg: stateVal, nodeIndex: index));
        } else {
          // Will not participate in this round.
          root.sendMessage(Message(MessageType.roundEnd, nodeIndex: index));
        }
      } else if (msg.roundNo % 3 == (index + 1) % 3) {
        if (type == NodeType.left || type == NodeType.middle) {
          rightSendPort.sendMessage(Message(MessageType.sendData, arg: stateVal, nodeIndex: index));
        } else {
          // Will not participate in this round.
          root.sendMessage(Message(MessageType.roundEnd, nodeIndex: index));
        }
      } else {
        if (type == NodeType.right || type == NodeType.middle) lStateWaiting();
        if (type == NodeType.left || type == NodeType.middle) rStateWaiting();
      }
    } else if (msg.type == MessageType.sendData) {
      // Only The Central nodes can recieve messages in this round
      assert(roundNo % 3 == index % 3);
      if (msg.nodeIndex == index - 1) {
        // Save the value received from left Isolate
        lVal = msg.arg as num;
        lStateDone();
      }
      if (msg.nodeIndex == index + 1) {
        // Save the value received from right Isolate
        rVal = msg.arg as num;
        rStateDone();
      }
      if (isAllValueReceived()) {
        // Return sorted values
        if (type == NodeType.middle) {
          List<num> sorted = [lVal, stateVal, rVal]..sort();
          leftSendPort.sendMessage(
            Message(MessageType.receiveData, arg: sorted[0], nodeIndex: index),
          );
          rightSendPort.sendMessage(
            Message(MessageType.receiveData, arg: sorted[2], nodeIndex: index),
          );
          stateVal = sorted[1];
        } else if (type == NodeType.left) {
          // Only return to right node
          List<num> sorted = [stateVal, rVal]..sort();
          rightSendPort.sendMessage(
            Message(MessageType.receiveData, arg: sorted[1], nodeIndex: index),
          );
          stateVal = sorted[0];
        } else if (type == NodeType.right) {
          // Only return to left node
          List<num> sorted = [lVal, stateVal]..sort();
          leftSendPort.sendMessage(
            Message(MessageType.receiveData, arg: sorted[0], nodeIndex: index),
          );
          stateVal = sorted[1];
        }
      }

      root.sendMessage(Message(MessageType.roundEnd, nodeIndex: index));
      //
    } else if (msg.type == MessageType.receiveData) {
      // Set the received value without any issue.
      stateVal = msg.arg as num;

      root.sendMessage(Message(MessageType.roundEnd, nodeIndex: index)); // Maybe send current value
    } else if (msg.type == MessageType.query) {
      root.sendMessage(Message(MessageType.queryResponse, arg: stateVal, nodeIndex: index));
    }
  }
}

void start(List<String> args) async {
  if (args.isEmpty) {
    print('Pass numbers as Command line arguments');
    return;
  }
  // Get Numbers.
  var numbers = args.map((e) => num.tryParse(e)).where((e) => e != null).toList();

  var msgPorts = <int, SendPort>{};

  /// Create a `ReceivePort` for current isolate.
  var receivePort = ReceivePort();

  // Create Isolates
  for (var _ in numbers) {
    await Isolate.spawn(run, receivePort.sendPort);
  }

  var index = 0;
  var setupDone = false;
  var roundNo = -1;
  var roundComplete = <int>{}; // For collection roundComplete events.
  var sortedSequence = <int, num>{}; // For sorted Sequence of numbers.

  await for (var msg in receivePort) {
    if (msg is SendPort) {
      /// Save [SendPort] of `n` spawned isolates.
      msgPorts[index] = msg;
      index++;
      if (msgPorts.length == numbers.length) {
        for (var i = 0; i < numbers.length; i++) {
          msgPorts[i].send(Message(
            MessageType.setup,
            nodeIndex: i,
            arg: numbers[i],
            leftSendPort: (i > 0) ? msgPorts[i - 1] : null,
            rightSendPort: (i < numbers.length - 1) ? msgPorts[i + 1] : null,
            nodeType: (i == 0)
                ? NodeType.left
                : (i == numbers.length - 1)
                    ? NodeType.right
                    : NodeType.middle,
          ));
        }
        setupDone = true;
      }
    } else if (msg is Message) {
      if (!setupDone) ;
      // Impossible situation a/c to Casual Precedence Relation.

      if (msg.type == MessageType.roundEnd) {
        roundComplete.add(msg.nodeIndex);

        // If every node is ready.
        if (roundComplete.length == numbers.length) {
          roundComplete.clear();

          if (roundNo == numbers.length - 1) {
            msgPorts.forEach((key, value) => value.send(Message(MessageType.query)));
            // Stop;
          } else {
            // Start new round
            roundNo++;
            msgPorts.forEach(
                (key, value) => value.send(Message(MessageType.roundStart, roundNo: roundNo)));
          }
        }
      } else if (msg.type == MessageType.queryResponse) {
        sortedSequence[msg.nodeIndex] = (msg.arg as num);
        if (sortedSequence.length == numbers.length) break;
      }
    }
  }

  print('Sorted Sequence:');
  for (var i = 0; i < numbers.length; i++) {
    print(sortedSequence[i]);
  }
}

void main(List<String> args) async {
  if (args.isNotEmpty && args.length < 3) {
    print('Enter a minimum of 3 numbers.');
    return;
  }
  await start(args);
}
