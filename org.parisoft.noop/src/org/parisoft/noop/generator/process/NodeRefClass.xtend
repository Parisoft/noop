package org.parisoft.noop.generator.process

import org.eclipse.xtend.lib.annotations.Accessors

class NodeRefClass implements Node {
	
	@Accessors var String className
	
	override toString() '''
		NodeRefClass{
			class : «className»
		}
	'''
	
}