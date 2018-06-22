package org.parisoft.noop.generator.process

import java.util.ArrayList
import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.generator.alloc.AllocContext

import static extension org.parisoft.noop.^extension.Datas.*

class NodeBeginStmt implements Node {
	
	@Accessors var String statementName
	
	override toString() '''
		NodeBeginStmt{
			stmt : «statementName»
		}
	'''
	
	override process(ProcessContext ctx) {
		ctx.ast.get(statementName)?.forEach[process(ctx)]
	}
	
	override alloc(AllocContext ctx) {
		val snapshot = ctx.snapshot
		val chunks = new ArrayList
		
		for (node : ctx.ast.get(statementName) ?: emptyList) {
			chunks += node.alloc(ctx)
		}
		
		chunks.disoverlap(statementName)
		ctx.restoreTo(snapshot)
		chunks
	}
	
}