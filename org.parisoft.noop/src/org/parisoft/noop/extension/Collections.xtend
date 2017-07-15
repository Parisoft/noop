package org.parisoft.noop.^extension

import java.util.Collection
import org.parisoft.noop.generator.MemChunk

class Collections {
	
	def isNotEmpty(Collection<?> collection) {
		!collection.isEmpty
	}
	
	def void disjoint(Iterable<MemChunk> innerChunks, Iterable<MemChunk> outerChunks) {
		for (outerChunk : outerChunks) {
			var delta = 0

			for (innerChunk : innerChunks) {
				if (delta != 0) {
					innerChunk.shiftTo(delta)
				} else if (innerChunk.overlap(outerChunk)) {
					delta = innerChunk.shiftTo(outerChunk)
				}
			}
		}
	}
}