package org.parisoft.noop.generator.alloc

import java.util.List
import java.util.concurrent.atomic.AtomicInteger
import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.generator.process.ProcessContext
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NewInstance
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.Variable

class AllocContext {

	@Accessors val classes = <String, NoopClass>newLinkedHashMap
	@Accessors val statics = <String, Variable>newLinkedHashMap
	@Accessors val constants = <String, Variable>newLinkedHashMap
	@Accessors val prgRoms = <String, Variable>newLinkedHashMap
	@Accessors val chrRoms = <String, Variable>newLinkedHashMap
	@Accessors val variables = <String, List<MemChunk>>newHashMap
	@Accessors val pointers = <String, List<MemChunk>>newHashMap
	@Accessors val methods = <String, Method>newLinkedHashMap
	@Accessors val constructors = <String, NewInstance>newLinkedHashMap

	@Accessors val counters = newArrayList(new AtomicInteger(0x0000), new AtomicInteger(0x0100),
		new AtomicInteger(0x0200), new AtomicInteger(0x0300), new AtomicInteger(0x0400), new AtomicInteger(0x0500),
		new AtomicInteger(0x0600), new AtomicInteger(0x0700))
	@Accessors var String container
	@Accessors val types = <NoopClass>newArrayList
	
	@Accessors var ProcessContext process
	
	def resetCounter(int page) {
		counters.get(page).set(page * 0x0100)
		counters.get(page).get
	}

	def chunkFor(int page, String variable, int size) {
		new MemChunk(variable, counters.get(page).getAndAdd(size), size)
	}

	def snapshot() {
		val src = this

		new AllocContext => [
			counters.forEach[counter, page|counter.set(src.counters.get(page).get)]
			container = src.container
		]
	}

	def restoreTo(AllocContext snapshot) {
		counters.forEach[counter, page|counter.set(snapshot.counters.get(page).get)]
		container = snapshot.container
	}

	override toString() '''
		AllocContext{
			«FOR i : 0..< counters.size»
				counter«i» : «Integer.toHexString(counters.get(i).get)»
			«ENDFOR»
			container : «container»
		}
	'''

}
