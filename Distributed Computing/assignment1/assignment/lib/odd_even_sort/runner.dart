library odd_even;

import 'dart:isolate';
import 'dart:developer' as developer;
import 'message.dart';
import 'node.dart';

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
      root.sendDebug(Message(MessageType.roundEnd, nodeIndex: index, roundNo: -1));
    } else if (msg.type == MessageType.roundStart) {
      // Check Odd/Even Round.
      if (msg.roundNo % 2 == index % 2 && type != NodeType.right) {
        rightSendPort.sendDebug(Message(MessageType.sendData, arg: stateVal, nodeIndex: index));
      } else {
        root.sendDebug(Message(MessageType.roundEnd, nodeIndex: index));
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

      leftSendPort.sendDebug(Message(MessageType.receiveData, arg: data, nodeIndex: index));

      root.sendDebug(Message(MessageType.roundEnd, nodeIndex: index));
      //
    } else if (msg.type == MessageType.receiveData) {
      // Set the received value without any issue.
      stateVal = msg.arg as num;

      root.sendDebug(Message(MessageType.roundEnd, nodeIndex: index)); // Maybe send current value
    } else if (msg.type == MessageType.query) {
      root.sendDebug(Message(MessageType.queryResponse, arg: stateVal, nodeIndex: index));
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
