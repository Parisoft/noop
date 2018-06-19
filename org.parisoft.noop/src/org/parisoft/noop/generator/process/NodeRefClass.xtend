package org.parisoft.noop.generator.process

import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors

class NodeRefClass implements Node {

	@Accessors var String className

	override toString() '''
		NodeRefClass{
			class : «className»
		}
	'''

	override process(ProcessContext ctx) {
		className.process(ctx)
	}

	private def List<String> process(String clazz, ProcessContext ctx) {
		if (ctx.classes.contains(clazz)) {
			return ctx.superClasses.get(clazz)
		}
		
		val supers = newArrayList(clazz) => [
				it += ctx.metaClasses.get(clazz)?.superClass?.process(ctx) ?: emptyList
		]

		ctx.superClasses.put(className, supers.drop(1).toList)
		ctx.classes.add(className)

		supers.toList
	}

}
