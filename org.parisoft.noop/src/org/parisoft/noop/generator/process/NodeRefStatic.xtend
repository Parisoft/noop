package org.parisoft.noop.generator.process

import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.generator.alloc.AllocContext

class NodeRefStatic implements Node {

	@Accessors var String staticName

	override toString() '''
		NodeRefStatic{
			const : «staticName»
		}
	'''

	override process(ProcessContext ctx) {
		ctx.statics.add(staticName)
	}

	override alloc(AllocContext ctx) {
	}

}
