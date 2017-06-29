package org.parisoft.noop.^extension

import java.util.List
import java.util.Collections

class Values {

	def parseInt(String string) {
		if (string === null || string.isEmpty()) {
			throw new IllegalArgumentException("Invalid value")
		}

		var value = 0;

		if (string.startsWith("$")) {
			value = Integer.parseInt(string.substring(1), 16)
		} else if (string.startsWith("%")) {
			value = Integer.parseInt(string.substring(1), 2)
		} else if (string.startsWith("'") && string.endsWith("'")) {
			value = string.charAt(1)
		} else {
			value = Integer.parseInt(string);
		}

		if (value > TypeSystem::MAX_UINT) {
			return value.bitwiseAnd(TypeSystem::MAX_UINT)
		} else if (value < TypeSystem::MIN_INT) {
			return value as short
		}

		return value;
	}
	
	def <T> subListFrom(List<T> list, int index) {
		list.subList(index, list.size)
	}
	
	def List<Integer> dimensionOf(List<?> list) {
		if (list.isEmpty) {
			Collections.emptyList
		} else {
			val dimension = newArrayList(list.size)
			dimension.addAll(list.head.dimensionOf)
			dimension
		}
	}
	
	def dimensionOf(Object object) {
		if (object instanceof List<?>) {
			object.dimensionOf
		} else {
			Collections.emptyList
		}
	}
}
