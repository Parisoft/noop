package org.parisoft.noop.generator

import java.util.concurrent.atomic.AtomicInteger
import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.Variable
import java.util.List
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NewInstance

class AllocData {

	@Accessors var NewInstance header
	@Accessors val classes = <NoopClass>newLinkedHashSet
	@Accessors val statics = <Variable>newLinkedHashSet
	@Accessors val constants = <Variable>newLinkedHashSet
	@Accessors val prgRoms = <Variable>newLinkedHashSet
	@Accessors val chrRoms = <Variable>newLinkedHashSet
	@Accessors val variables = <String, List<MemChunk>>newHashMap
	@Accessors val pointers = <String, List<MemChunk>>newHashMap
	@Accessors val methods = <Method>newHashSet
	@Accessors val constructors = <NewInstance>newHashSet

	@Accessors val ptrCounter = new AtomicInteger(0x0000)
	@Accessors val varCounter = new AtomicInteger(0x0400)
	@Accessors var String container
	@Accessors var boolean allocStatic = false

	def resetVarCounter() {
		varCounter.set(0x0400)
		varCounter.get
	}

	def chunkForPtr(String variable) {
		new MemChunk(variable, ptrCounter.getAndAdd(2))
	}
	
	def chunkForZP(String variable, int size) {
		new MemChunk(variable, ptrCounter.getAndAdd(size), size)
	}

	def chunkForVar(String variable, int size) {
		new MemChunk(variable, varCounter.getAndAdd(size), size)
	}
	
	def snapshot() {
		val src = this

		new AllocData => [
			ptrCounter.set(src.ptrCounter.get)
			varCounter.set(src.varCounter.get)
			container = src.container
			allocStatic = src.allocStatic
		]
	}

	def restoreTo(AllocData snapshot) {
		ptrCounter.set(snapshot.ptrCounter.get)
		varCounter.set(snapshot.varCounter.get)
		container = snapshot.container
		allocStatic = snapshot.allocStatic
	}

	override toString() '''
		MetaData{
			ptrCounter : «Integer.toHexString(ptrCounter.get)»,
			varCounter : «Integer.toHexString(varCounter.get)»,
			container : «container»
		}
	'''

}
