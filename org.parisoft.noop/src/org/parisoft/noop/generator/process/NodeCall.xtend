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
		if (ctx.processing.add(methodName)) {
			try {
				ctx.methods.add(methodName)
				ctx.ast.get(methodName)?.forEach[process(ctx)]
			} finally {
				ctx.processing.remove(methodName)
			}
		}
	}

	override alloc(AllocContext ctx) {
		if (ctx.allocating.add(methodName)) {
			try {
				ctx.methodChunks.computeIfAbsent(methodName, [
					val snapshot = ctx.snapshot
					val chunks = ctx.process.ast.get(methodName)?.map[alloc(ctx)].filterNull.flatten ?: emptyList
					chunks.disoverlap(methodName)
					ctx.restoreTo(snapshot)
					chunks.toList
				])
			} finally {
				ctx.allocating.remove(methodName)
			}
		} else {
			emptyList
		}
	}

}
