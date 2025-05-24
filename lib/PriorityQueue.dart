class PriorityQueue<T> {
  final Comparator<T> _comparator;
  final List<T> _queue = [];

  PriorityQueue(this._comparator);

  bool get isEmpty => _queue.isEmpty;

  void add(T value) {
    _queue.add(value);
    _siftUp(_queue.length - 1);
  }

  T remove() {
    if (_queue.isEmpty) {
      throw StateError('Queue is empty');
    }
    final value = _queue.first;
    final last = _queue.removeLast();
    if (_queue.isNotEmpty) {
      _queue[0] = last;
      _siftDown(0);
    }
    return value;
  }

  void _siftUp(int index) {
    while (index > 0) {
      final parent = (index - 1) ~/ 2;
      if (_comparator(_queue[index], _queue[parent]) >= 0) {
        break;
      }
      _swap(index, parent);
      index = parent;
    }
  }

  void _siftDown(int index) {
    while (true) {
      final left = 2 * index + 1;
      final right = 2 * index + 2;
      int smallest = index;
      if (left < _queue.length &&
          _comparator(_queue[left], _queue[smallest]) < 0) {
        smallest = left;
      }
      if (right < _queue.length &&
          _comparator(_queue[right], _queue[smallest]) < 0) {
        smallest = right;
      }
      if (smallest == index) {
        break;
      }
      _swap(index, smallest);
      index = smallest;
    }
  }

  void _swap(int i, int j) {
    final temp = _queue[i];
    _queue[i] = _queue[j];
    _queue[j] = temp;
  }
}
