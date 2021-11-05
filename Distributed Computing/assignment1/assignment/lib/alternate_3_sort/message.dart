library alternate;

import '../assignment.dart';
import 'node.dart';
import 'dart:isolate';

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
