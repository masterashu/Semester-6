import 'dart:isolate';
import 'dart:developer' as developer;

// Enabling Debug allows seeing the message transfer log
const bool DEBUG = bool.fromEnvironment('DEBUG', defaultValue: false);

enum NodeType { left, middle, right }

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

  NodeType type;
  SendPort leftSendPort, rightSendPort;
  int index;
  num stateVal;

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
      // Check Odd/Even Round.
      if (msg.roundNo % 2 == index % 2 && type != NodeType.right) {
        rightSendPort.sendMessage(Message(MessageType.sendData, arg: stateVal, nodeIndex: index));
      } else {
        root.sendMessage(Message(MessageType.roundEnd, nodeIndex: index));
      }
      //
    } else if (msg.type == MessageType.sendData) {
      var data;

      if ((msg.arg as num) > stateVal) {
        // Compare
        data = stateVal; //
        stateVal = (msg.arg as num); // Update locally
      } else {
        data = msg.arg;
      } // Send

      leftSendPort.sendMessage(Message(MessageType.receiveData, arg: data, nodeIndex: index));

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
          if (roundNo == numbers.length) {
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
  if (args.isNotEmpty && args.length < 2) {
    print('Enter a minimum of 2 numbers.');
    return;
  }
  await start(args);
}
