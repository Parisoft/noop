package org.parisoft.noop.generator.process

import java.util.ArrayList
import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.generator.alloc.AllocContext

import static extension org.parisoft.noop.^extension.Datas.*

class NodeNew implements Node {

	@Accessors var String type

	override toString() '''
		NodeNew{
			type : «type»
		}
	'''

	override process(ProcessContext ctx) {
		if (ctx.constructors.add(type)) {
			ctx.ast.get(constructor)?.forEach[process(ctx)]
		}
	}

	override alloc(AllocContext ctx) {
		val snapshot = ctx.snapshot
		val chunks = new ArrayList

		for (node : ctx.ast.get(constructor) ?: emptyList) {
			chunks += node.alloc(ctx)
		}

		chunks.disoverlap(constructor)
		ctx.restoreTo(snapshot)
		chunks
	}

	private def String constructor() {
		'''«type».new'''
	}

}
