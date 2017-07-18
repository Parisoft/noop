package org.parisoft.noop.generator

import java.util.concurrent.atomic.AtomicInteger
import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.Variable
import java.util.List

class MetaData {

	@Accessors var Variable header
	@Accessors val classes = <NoopClass>newHashSet
	@Accessors val singletons = <NoopClass>newHashSet
	@Accessors val constants = <Variable>newHashSet
	@Accessors val prgRoms = <Variable>newHashSet
	@Accessors val chrRoms = <Variable>newHashSet
	@Accessors val variables = <String, List<MemChunk>>newHashMap
	@Accessors val pointers = <String, List<MemChunk>>newHashMap

	@Accessors val ptrCounter = new AtomicInteger(0x0000)
	@Accessors val varCounter = new AtomicInteger(0x0400)
	@Accessors var String container

	def resetVarCounter() {
		varCounter.set(0x0400)
		varCounter.get
	}

	def chunkForPointer(String variable) {
		new MemChunk(variable, ptrCounter.getAndAdd(2))
	}

	def chunkForVar(String variable, int size) {
		new MemChunk(variable, varCounter.getAndAdd(size), size)
	}

	def snapshot() {
		val src = this

		new MetaData => [
			ptrCounter.set(src.ptrCounter.get)
			varCounter.set(src.varCounter.get)
			container = src.container
		]
	}

	def restoreTo(MetaData snapshot) {
		ptrCounter.set(snapshot.ptrCounter.get)
		varCounter.set(snapshot.varCounter.get)
		container = snapshot.container
	}

	override toString() '''
		MetaData{
			ptrCounter : «Integer.toHexString(ptrCounter.get)»,
			varCounter : «Integer.toHexString(varCounter.get)»,
			container : «container»
		}
	'''

}
