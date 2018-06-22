package org.parisoft.noop.generator.process

import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.^extension.Datas
import org.parisoft.noop.generator.alloc.AllocContext

import static extension org.parisoft.noop.^extension.Datas.*

class NodeVar implements Node {

	@Accessors var String varName
	@Accessors var String type
	@Accessors var Integer page = Datas::VAR_PAGE
	@Accessors var Integer qty = 1
	@Accessors var boolean ptr = false
	@Accessors var boolean tmp = false
	@Accessors var boolean param = false
	
	override toString() '''
		NodeVar{
			name : «varName»,
			type : «type»,
			page : «page»,
			qty : «qty»,
			ptr : «ptr»,
			tmp : «tmp»
		}
	'''
	
	override process(ProcessContext ctx) {
	}
	
	override alloc(AllocContext ctx) {
		if (ctx.variables.containsKey(varName)) {
			return ctx.variables.get(varName) 
		}
		
		if (ptr) {
			ctx.computePtr(varName)
		} else if (tmp) {
			ctx.computeTmp(varName, size(ctx))
		} else {
			ctx.computeVar(varName, page, size(ctx))
		}
	}
	
	private def int size(AllocContext ctx) {
		qty * (ctx.sizeOfClasses.get(type) ?: 1)
	}
	
}
