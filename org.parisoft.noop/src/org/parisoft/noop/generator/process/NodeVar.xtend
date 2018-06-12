package org.parisoft.noop.generator.process

import org.eclipse.xtend.lib.annotations.Accessors

class NodeVar implements Node {

	@Accessors var String varName
	@Accessors var String type
	@Accessors var Integer qty = 1
	@Accessors var boolean ptr = false
	@Accessors var boolean tmp = false
}
