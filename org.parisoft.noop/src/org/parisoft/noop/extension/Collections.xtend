package org.parisoft.noop.^extension

import java.util.List
import java.util.Map
import java.util.function.Supplier
import com.google.common.collect.Table

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
	
	def <K, V> get(Map<K, V> map, K key, Supplier<V> supplier) {
		map.get(key) ?: {
			val value = supplier.get
			
			map.put(key, value)
			
			value
		}
	}
	
	def <R, C, V> get(Table<R, C, V> map, R row, C col, Supplier<V> supplier) {
		map.get(row, col) ?: {
			val value = supplier.get
			
			map.put(row, col, value)
			
			value
		}
	}
}
