import 'dart:isolate';
import 'dart:developer' as developer;

// Enabling Debug allows seeing the message transfer log
const bool DEBUG = bool.fromEnvironment('DEBUG', defaultValue: false);

enum NodeType { left, middle, right }

enum NodeState { waiting, done }

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

class Item {
  final num val;
  final bool marked;

  Item(this.val, {this.marked = false});

  @override
  String toString() {
    return '$val${marked ? '^' : ''}';
  }
}

void run(SendPort root) async {
  var port = ReceivePort();
  root.send(port.sendPort);

  NodeType type;
  SendPort leftSendPort, rightSendPort;
  int index;
  int area;
  NodeState lState, rState;
  Item lVal, rVal;

  bool isRoundComplete() {
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
  void sort() {
    if (type == NodeType.middle) {
      if (lVal.val > rVal.val) {
        var d = lVal;
        lVal = rVal;
        rVal = d;
      }
    }
  }

  await for (Message msg in port) {
    developer.log('Isolate #${index ?? '?'} | Received Message: $msg.');
    if (msg.type == MessageType.setup) {
      // Setup Message
      type = msg.nodeType;
      index = msg.nodeIndex;
      area = type == NodeType.left ? -1 : 0;
      var a = (msg.arg as num);
      if (type == NodeType.right || type == NodeType.middle) {
        leftSendPort = msg.leftSendPort;
        lVal = Item(a, marked: (type == NodeType.right));
        lStateDone();
      }
      if (type == NodeType.left || type == NodeType.middle) {
        rightSendPort = msg.rightSendPort;
        rVal = Item(a, marked: (type == NodeType.left));
        rStateDone();
      }
      root.sendMessage(Message(MessageType.roundEnd, nodeIndex: index, roundNo: -1));
    } else if (msg.type == MessageType.roundStart) {
      /// Send [lVal] to [leftSendPort] and [rVal] to [rightSendPort].
      if (type == NodeType.left || type == NodeType.middle) {
        rightSendPort.sendMessage(Message(MessageType.sendData, arg: rVal, nodeIndex: index));
      } else {
        // Wait
      }
      lStateWaiting();
      rStateWaiting();
    } else if (msg.type == MessageType.sendData) {
      Item data;

      // Compare incoming Value
      if ((msg.arg as Item).val > lVal.val) {
        data = lVal; //
        lVal = msg.arg; // Update locally
        if ((msg.arg as Item).marked) {
          area += 1;
        }
      } else {
        data = msg.arg;
      } // Send

      leftSendPort.sendMessage(Message(MessageType.receiveData, arg: data, nodeIndex: index));
      lStateDone();
      //
    } else if (msg.type == MessageType.receiveData) {
      // Set the received value without any issue.
      if (rVal != msg.arg) {
        if (rVal.marked) {
          area -= 1;
        }
        rVal = msg.arg as Item;
      }
      rStateDone();
    } else if (msg.type == MessageType.query) {
      var data = (area <= -1) ? rVal : lVal;
      root.sendMessage(Message(MessageType.queryResponse, arg: data.val, nodeIndex: index));
    }
    if (isRoundComplete()) {
      sort();
      root.sendMessage(Message(MessageType.roundEnd, nodeIndex: index));
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
            // Stop after `n-1` rounds;
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
  if (args.isNotEmpty && args.length < 2) {
    print('Enter a minimum of 2 numbers.');
    return;
  }
  await start(args);
}
