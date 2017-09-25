package org.parisoft.noop.^extension

import java.util.Collection
import org.parisoft.noop.generator.MemChunk

class Collections {
	
	def isNotEmpty(Collection<?> collection) {
		!collection.isEmpty
	}
	
	def void disoverlap(Iterable<MemChunk> chunks, String methodName) {
		println('--------------------------------')
		println('''disoverlaping «methodName» chunks «chunks»''')
		
		chunks.forEach [ chunk, index |
			if (chunk.variable.startsWith(methodName)) {
				chunks.drop(index).reject [
					it.variable.startsWith(methodName)
				].forEach [ outer |
					if (chunk.overlap(outer)) {
						println('''«chunk» overlaps «outer»''')
						
						val delta = chunk.deltaFrom(outer)
		
						chunks.drop(index).filter [
							it.variable.startsWith(methodName)
						].forEach [ inner |
							println('''«inner» shift to «delta»''')
							
							inner.shiftTo(delta)
						]
					}
				]
			}
		]
		
		println('''disoverlapped «methodName» to «chunks»''')
		println('--------------------------------')
	}
	
}