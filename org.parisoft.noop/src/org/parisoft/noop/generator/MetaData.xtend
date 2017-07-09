package org.parisoft.noop.generator

import java.util.Map
import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.Variable
import java.util.concurrent.atomic.AtomicInteger

class MetaData {

	@Accessors val Variable header
	@Accessors val classes = <NoopClass>newHashSet()
	@Accessors val constants = <Variable>newHashSet()
	@Accessors val singletons = <NoopClass>newHashSet()
	@Accessors val prgRoms = <Variable>newHashSet()
	@Accessors val chrRoms = <Variable>newHashSet()
	@Accessors val variables = <Method, Map<Variable, MemChunk>>newHashMap()
	@Accessors val pointers = <Method, Map<Variable, MemChunk>>newHashMap()

	@Accessors val ptrCounter = new AtomicInteger(0x0000)
	@Accessors val varCounter = new AtomicInteger(0x0400)
	@Accessors val tmpCounter = new AtomicInteger(0)

	new(Variable header) {
		this.header = header
	}

	def chunkForPointer() {
		new MemChunk(ptrCounter.getAndAdd(2))
	}

	def chunkForVar(int size) {
		new MemChunk(varCounter.getAndAdd(size), size)
	}
}
