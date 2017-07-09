package org.parisoft.noop.generator

import org.eclipse.xtend.lib.annotations.Accessors

class MemChunk {

	@Accessors var Integer low
	@Accessors var Integer high

	new(int addr) {
		low = addr
		high = low + 1
	}

	new(int addr, int size) {
		low = addr
		high = addr + size - 1
	}

}
