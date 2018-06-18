package org.parisoft.noop.generator.process

import org.eclipse.xtend.lib.annotations.Accessors

class NodeBeginStmt implements Node {
	
	@Accessors var String statementName
	
	override toString() '''
		NodeBeginStmt{
			stmt : «statementName»
		}
	'''
	
}