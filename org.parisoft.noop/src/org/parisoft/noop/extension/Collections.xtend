package org.parisoft.noop.^extension

import java.util.Collection
import org.parisoft.noop.generator.AllocData
import org.parisoft.noop.generator.MemChunk

class Collections {

	def isNotEmpty(Collection<?> collection) {
		!collection.isEmpty
	}

	def void disoverlap(Iterable<MemChunk> chunks, String methodName) {
		println('--------------------------------')
		println('''disoverlaping «methodName» chunks «chunks»''')

		chunks.forEach [ chunk, index |
			if (chunk.variable.startsWith(methodName) && chunk.isNonDisposed) {
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

	def computePtr(AllocData data, String varName) {
		data.pointers.compute(varName, [ name, value |
			var chunks = value

			if (chunks === null) {
				chunks = newArrayList(data.chunkForPtr(name))
			} else if (data.ptrCounter.get < chunks.last.hi) {
				data.ptrCounter.set(chunks.last.hi + 1)
			}

			return chunks
		])
	}
	
	def computeZP(AllocData data, String varName, int size) {
		data.pointers.compute(varName, [ name, value |
			var chunks = value

			if (chunks === null) {
				chunks = newArrayList(data.chunkForZP(name, size))
			} else if (data.ptrCounter.get < chunks.last.hi) {
				data.ptrCounter.set(chunks.last.hi + 1)
			}

			return chunks
		])
	}

	def computeVar(AllocData data, String varName, int size) {
		data.variables.compute(varName, [ name, value |
			var chunks = value

			if (chunks === null) {
				chunks = newArrayList(data.chunkForVar(name, size))
			} else if (data.varCounter.get < chunks.last.hi) {
				data.varCounter.set(chunks.last.hi + 1)
			}

			return chunks
		])
	}

	def computeTmp(AllocData data, String varName, int size) {
		if (size > 2) {
			data.computeVar(varName, size)
		} else {
			data.computeZP(varName, size)
		}
	}

}
