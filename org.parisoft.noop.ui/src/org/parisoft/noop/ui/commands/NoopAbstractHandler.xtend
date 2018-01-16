package org.parisoft.noop.ui.commands

import org.eclipse.core.commands.AbstractHandler
import org.eclipse.core.commands.ExecutionEvent
import utils.IResources

abstract class NoopAbstractHandler extends AbstractHandler {

	def getIResource(ExecutionEvent event) {
		IResources::getIResource(event)
	}
}
