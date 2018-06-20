package org.parisoft.noop.generator.process

import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.generator.alloc.AllocContext

class NodeRefConst implements Node {

	@Accessors var String constName

	override toString() '''
		NodeRefConst{
			const : «constName»
		}
	'''
	
	override process(ProcessContext ctx) {
		ctx.constants.add(constName)
	}
	
	override alloc(AllocContext ctx) {
		emptyList
	}

}
