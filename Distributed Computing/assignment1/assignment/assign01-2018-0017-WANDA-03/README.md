## Assignment 1
## Distributed Computing

Submitted by:
> Ashutosh Chauhan  
> Roll No: S20180010017

Choice of Language: **Dart**  
### Why Dart?  
1. Dart is a cross platform programming language which support 
   multiple compilation paradigmns such as :
   * AOT (Ahead of time compilation with Type Checking) like C, Java, etc.
   * JIT (Just in Time compilation with optional dynamic types) like python, etc.
   * dart2js (Transpilation to Javascript).

2. Even through dart is a single threaded language, it support 
   parallel execution using [Isolates](https://api.flutter.dev/flutter/dart-isolate/Isolate-class.html). Isolates have their own **Event Loop** and **isolated Memory**. The communication between isolates occurs only through asynchronous channels called [Ports](https://api.dart.dev/stable/2.10.5/dart-isolate/SendPort-class.html).

The second reason is majorly why I chose Dart.

### Installion of dart:
A. Ubuntu
```bash
sudo apt-get update
sudo apt-get install apt-transport-https
sudo sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
sudo sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt-get update
sudo apt-get install dart
# optionally adding dart tools to PATH
export PATH="$PATH:/usr/lib/dart/bin"
```
B. MacOS
```sh
brew tap dart-lang/dart
brew install dart
```
C. Windows 
Installation Instructions: https://dart.dev/get-dart

### Running the code.
To run the source code  you can go the assignment directory and run the `dart run main.dart` followed by the sequence of numbers as arguments:
```bash
# for JIT Compilation (slow)
dart run main.dart 4 2 1 5 3

# for AOT Compilation (fast)
dart compile exe main.dart
./main.exe 4 2 1 5 3
```

You can also pass the list of numbers by saving it in a file, say `input.txt`:
```txt
5
4
1
2
3
```
and replacing the sequence of arguments with `$(cat input.txt)`. example
```bash
dart compile exe main.dart
./main.exe $(cat input.txt)
```

#### Logging Trasferred messages.
You can optionally add the argument `-DDEBUG=true` to the `dart run` or `dart compile exe` command.  
Example
```bash
# for JIT Compilation (slow)
dart run main.dart -DDEBUG=true 4 2 1 5 3

# for AOT Compilation (fast)
dart compile exe -DDEBUG=true main.dart
./main.exe $(cat input.txt)
```
