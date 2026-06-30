extension ListExtensions<E> on List<E> {
  List<E> operator -(List<E> elements) => where((element) => !elements.contains(element)).toList();

  List<E> get sorted => List.of(this)..sort();
}
