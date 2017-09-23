package org.parisoft.noop.^extension

import java.util.List
import org.parisoft.noop.noop.ArrayLiteral
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.NoopFactory
import org.parisoft.noop.noop.StringLiteral

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
			java.util.Collections.emptyList
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
			emptyList
		}
	}

	def List<Byte> toBytes(Object obj) {
		switch (obj) {
			Integer:
				newArrayList(obj.bitwiseAnd(0xFF).byteValue, (obj >> 8).byteValue)
			Boolean:
				if (obj) {
					newArrayList(1.byteValue)
				} else {
					newArrayList(0.byteValue)
				}
			String:
				obj.bytes
			List<?>:
				obj.map[toBytes].flatten.toList
			default:
				emptyList
		}
	}

	def List<Expression> flatList(ArrayLiteral array) {
		array.values.map [
			if (it instanceof ArrayLiteral) {
				it.flatList
			} else if (it instanceof StringLiteral) {
				it.value.bytes.map[b | NoopFactory::eINSTANCE.createByteLiteral => [value = b.intValue]]
			} else {
				newArrayList(it)
			}
		].flatten.toList
	}

	def toHex(Byte b) '''$«IF b < 0x10»0«ENDIF»«Integer::toHexString(b).toUpperCase»'''

	def toHex(Integer i) '''$«Integer::toHexString(i).toUpperCase»'''

}
