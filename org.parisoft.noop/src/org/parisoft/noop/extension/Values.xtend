package org.parisoft.noop.^extension

import java.util.List
import org.parisoft.noop.noop.ArrayLiteral
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.NoopFactory
import org.parisoft.noop.noop.StringLiteral
import java.io.File

class Values {

	def parseInt(String string) {
		if (string === null || string.isEmpty()) {
			throw new IllegalArgumentException('Invalid value')
		}

		var value = 0;

		if (string.startsWith('0x')) {
			value = string.substring(2).hexToInt
		} else if (string.startsWith('$')) {
			value = string.substring(1).hexToInt
		} else if (string.startsWith('0b')) {
			value = string.substring(2).binToInt
		} else if (string.startsWith('%')) {
			value = string.substring(1).binToInt
		} else if (string.startsWith("'") && string.endsWith("'")) {
			value = string.charAt(1)
		} else {
			value = Integer::parseInt(string);
		}

		if (value > TypeSystem::MAX_UINT) {
			return value.bitwiseAnd(TypeSystem::MAX_UINT)
		} else if (value < TypeSystem::MIN_INT) {
			return value as short
		}

		return value;
	}
	
	private def hexToInt(String hex) {
		if (hex.length > 4) {
			Integer::parseInt(hex.substring(hex.length - 4), 16)
		} else {
			Integer::parseInt(hex, 16)
		}
	}
	
	private def binToInt(String bin) {
		if (bin.length > 16) {
			Integer::parseInt(bin.substring(bin.length - 16), 2)
		} else {
			Integer::parseInt(bin, 2)
		}
	}

	def List<Integer> dimensionOf(List<?> list) {
		if (list.isEmpty) {
			emptyList
		} else {
			val dimension = newArrayList(list.size)
			dimension.addAll(list.head.dimensionOf)
			dimension
		}
	}

	def dimensionOf(Object object) {
		if (object instanceof List<?>) {
			object.dimensionOf
		} else if (object instanceof File) {
			newArrayList(object.length as int)
		} else {
			emptyList
		}
	}

	def List<Integer> toBytes(Object obj) {
		switch (obj) {
			Integer:
				if (obj > TypeSystem::MAX_BYTE || obj < TypeSystem::MIN_SBYTE) {
					newArrayList(obj.bitwiseAnd(0xFF), (obj >> 8))
				} else {
					newArrayList(obj.bitwiseAnd(0xFF))
				}
			Boolean:
				if (obj) {
					newArrayList(1)
				} else {
					newArrayList(0)
				}
			String:
				obj.bytes.map[intValue]
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
				it.value.bytes.map[b|NoopFactory::eINSTANCE.createByteLiteral => [value = b.intValue]]
			} else {
				newArrayList(it)
			}
		].flatten.toList
	}

	def toHex(Integer i) '''$«IF i < 0x10 || (i > 0xFF && i < 0x1000)»0«ENDIF»«Integer::toHexString(i).toUpperCase»'''

}
