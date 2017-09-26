package org.parisoft.noop.^extension

import java.util.Collection

class Collections {

	def isNotEmpty(Collection<?> collection) {
		!collection.isEmpty
	}

}
