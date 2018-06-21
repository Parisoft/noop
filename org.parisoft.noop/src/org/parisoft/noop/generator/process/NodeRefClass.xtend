package org.parisoft.noop.generator.process

import java.util.ArrayList
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
		if (ctx.classes.add(className)) {
			val supers = new ArrayList
			var supr = className

			do {
				supr = ctx.metaClasses.get(supr)?.superClass
			} while (supr !== null && !supers.contains(supr) && supers.add(supr))

			ctx.superClasses.put(className, supers)
		}
	}

	override alloc(AllocContext ctx) {
		emptyList
	}

}
