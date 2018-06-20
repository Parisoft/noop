package org.parisoft.noop.generator.process

import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.generator.alloc.AllocContext
import static extension org.parisoft.noop.^extension.Datas.*

class NodeCall implements Node {

	@Accessors var String methodName

	override toString() '''
		NodeCall{
			method : «methodName»
		}
	'''

	override process(ProcessContext ctx) {
		ctx.methods.add(methodName)
		ctx.ast.get(methodName)?.forEach[process(ctx)]
	}

	override alloc(AllocContext ctx) {
		val snapshot = ctx.snapshot
		val chunks = ctx.process.ast.get(methodName)?.map[alloc(ctx)].flatten ?: emptyList
		chunks.disoverlap(methodName)
		ctx.restoreTo(snapshot)
		chunks.toList
	}

}
