package org.parisoft.noop.generator.process

import org.eclipse.xtend.lib.annotations.Accessors

class NodeNew implements Node {
	
	@Accessors var String type
	
	override toString()'''
		NodeNew{
			type : «type»
		}
	'''
	
}