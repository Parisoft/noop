package org.parisoft.noop.^extension

import java.util.Collection
import org.parisoft.noop.generator.MemChunk

class Collections {
	
	def isNotEmpty(Collection<?> collection) {
		!collection.isEmpty
	}
	
	def void disoverlap(Iterable<MemChunk> chunks, String methodName) {
		chunks.forEach [ chunk, index |
			if (chunk.variable.startsWith(methodName)) {
				chunks.drop(index).reject [
					it.variable.startsWith(methodName)
				].forEach [ outer |
					if (chunk.overlap(outer)) {
						val delta = chunk.deltaFrom(outer)
		
						chunks.drop(index).filter [
							it.variable.startsWith(methodName)
						].forEach [ inner |
							inner.shiftTo(delta)
						]
					}
				]
			}
		]
	}
	
}