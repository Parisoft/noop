package org.parisoft.noop.generator.exception

import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.generator.alloc.MemChunk

class PtrMemOverlapException extends Exception {
	
	@Accessors val MemChunk chunk
	
	new(MemChunk chunk) {
		super()
		this.chunk = chunk
	}
	
}
