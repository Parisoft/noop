package org.parisoft.noop.generator.process

import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.generator.alloc.AllocContext

class NodeRefClass implements Node {

	@Accessors var String className

	override toString() '''
		NodeRefClass{
			class : «className»
		}
	'''

	override process(ProcessContext ctx) {
		ctx.classes.add(className)
	}

	override alloc(AllocContext ctx) {
		emptyList
	}

}
