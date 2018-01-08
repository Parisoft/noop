package org.parisoft.noop.ui.rename

import org.eclipse.xtext.ide.refactoring.IResourceRelocationStrategy
import org.eclipse.xtext.ide.refactoring.ResourceRelocationContext
import org.parisoft.noop.noop.NoopClass
import org.eclipse.xtext.ide.refactoring.ResourceRelocationContext.ChangeType

class NoopResourceRelocationStrategy implements IResourceRelocationStrategy {

	override applyChange(ResourceRelocationContext context) {
		if (context.changeType == ChangeType::RENAME) {
			context.changes.filter[fromURI.fileExtension == 'noop'].forEach [ change |
				context.addModification(change) [ resource |
					val obj = resource.contents.head

					if (obj instanceof NoopClass) {
						obj.name = change.toURI.trimFileExtension.lastSegment
					}
				]
			]
		}
	}

}
