package org.parisoft.noop.generator.process

import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.generator.alloc.AllocContext

class NodeNew implements Node {
	
	@Accessors var String type
	
	override toString()'''
		NodeNew{
			type : «type»
		}
	'''
	
	override process(ProcessContext ctx) {
		ctx.constructors.add(type)
	}
	
	override alloc(AllocContext ctx) {
		emptyList
	}
	
}