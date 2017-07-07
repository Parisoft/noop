package org.parisoft.noop.generator

import org.eclipse.xtend.lib.annotations.Accessors

class PtrMemOverlapException extends Exception {
	
	@Accessors val MemChunk chunk
	
	new(MemChunk chunk) {
		super()
		this.chunk = chunk
	}
	
}