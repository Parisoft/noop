package org.parisoft.noop.^extension

import java.util.List

class Collections {

	def isNotEmpty(Iterable<?> collection) {
		collection !== null && !collection.isEmpty
	}

	def <T> put(List<T> list, T element) {
		list.add(0, element)
	}
	
	def <T> pop(List<T> list) {
		list.remove(0)
	}
}
