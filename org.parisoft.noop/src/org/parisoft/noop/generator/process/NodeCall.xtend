package org.parisoft.noop.generator.process

import org.eclipse.xtend.lib.annotations.Accessors

class NodeCall implements Node {
	
	@Accessors var String containerClass
	@Accessors var String methodName
	
	override toString()'''
		NodeCall{
			method : «methodName»
		}
	'''
	
}