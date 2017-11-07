package org.parisoft.noop.generator

import java.util.List
import java.util.concurrent.atomic.AtomicInteger
import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NewInstance
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.Variable

class AllocContext {

	@Accessors var NewInstance header
	@Accessors val classes = <NoopClass>newLinkedHashSet
	@Accessors val statics = <Variable>newLinkedHashSet
	@Accessors val constants = <Variable>newLinkedHashSet
	@Accessors val prgRoms = <Variable>newLinkedHashSet
	@Accessors val chrRoms = <Variable>newLinkedHashSet
	@Accessors val variables = <String, List<MemChunk>>newHashMap
	@Accessors val pointers = <String, List<MemChunk>>newHashMap
	@Accessors val methods = <Method>newHashSet
	@Accessors val constructors = <NewInstance>newTreeSet[n1, n2|n1.type.name.compareTo(n2.type.name)]

	@Accessors val counters = newArrayList(new AtomicInteger(0x0000), new AtomicInteger(0x0100), new AtomicInteger(0x0200), new AtomicInteger(0x0300),
		new AtomicInteger(0x0400), new AtomicInteger(0x0500), new AtomicInteger(0x0600), new AtomicInteger(0x0700))
	@Accessors var String container
	@Accessors var boolean allocStatic = false

	def resetCounter(int page) {
		counters.get(page).set(page * 256)
		counters.get(page).get
	}
		
	def chunkFor(int page, String variable, int size) {
		new MemChunk(variable, counters.get(page).getAndAdd(size), size)
	}

	def snapshot() {
		val src = this

		new AllocContext => [
			counters.forEach[counter, page| counter.set(src.counters.get(page).get)]
			container = src.container
			allocStatic = src.allocStatic
		]
	}

	def restoreTo(AllocContext snapshot) {
		counters.forEach[counter, page| counter.set(snapshot.counters.get(page).get)]
		container = snapshot.container
		allocStatic = snapshot.allocStatic
	}

	override toString() '''
		MetaData{
			«FOR i : 0..< counters.size»
				counter«i» : «Integer.toHexString(counters.get(i).get)»
			«ENDFOR»
			container : «container»
		}
	'''

}
