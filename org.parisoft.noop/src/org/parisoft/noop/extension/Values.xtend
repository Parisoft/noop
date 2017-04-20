package org.parisoft.noop.^extension

class Values {

	def parseInt(String string) {
		if (string === null || string.isEmpty()) {
			throw new IllegalArgumentException("Invalid value");
		}

		var value = 0;

		if (string.startsWith("$")) {
			value = Integer.parseInt(string.substring(1), 16);
		} else if (string.startsWith("%")) {
			value = Integer.parseInt(string.substring(1), 2);
		} else {
			value = Integer.parseInt(string);
		}

		if (value > TypeSystem::MAX_UINT) {
			return value.bitwiseAnd(TypeSystem::MAX_UINT);
		} else if (value < TypeSystem::MIN_INT) {
			return value as short;
		}

		return value;
	}
}
