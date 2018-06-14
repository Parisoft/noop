package org.parisoft.noop.generator.process

import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.^extension.Datas

class NodeVar implements Node {

	@Accessors var String varName
	@Accessors var String type
	@Accessors var Integer page = Datas::VAR_PAGE
	@Accessors var Integer qty = 1
	@Accessors var boolean ptr = false
	@Accessors var boolean tmp = false
	
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
	
}
