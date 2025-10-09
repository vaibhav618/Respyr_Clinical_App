import 'dart:collection';

class TaskQueueManager {
  final Queue<Future<void> Function()> _queue = Queue();
  bool _isProcessing = false;

  void add(Future<void> Function() task) {
    _queue.add(task);
    _processQueue();
  }

  void _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final task = _queue.removeFirst();
      try {
        await task(); // 👈 Each task runs and finishes before the next starts
      } catch (e) {
        print("Error: $e");
      }
    }

    _isProcessing = false;
  }
}