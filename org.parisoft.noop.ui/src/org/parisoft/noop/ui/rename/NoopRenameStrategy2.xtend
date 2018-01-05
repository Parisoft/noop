package org.parisoft.noop.ui.rename

import com.google.inject.Inject
import org.eclipse.core.runtime.Path
import org.eclipse.emf.ecore.EObject
import org.eclipse.ltk.core.refactoring.resource.RenameResourceChange
import org.eclipse.xtext.ide.refactoring.IRenameStrategy2
import org.eclipse.xtext.ide.refactoring.RenameChange
import org.eclipse.xtext.ide.refactoring.RenameContext
import org.eclipse.xtext.ui.refactoring.IRefactoringUpdateAcceptor
import org.parisoft.noop.noop.NoopClass

import static extension org.eclipse.emf.ecore.util.EcoreUtil.*

class NoopRenameStrategy2 extends IRenameStrategy2.DefaultImpl {

	@Inject IRefactoringUpdateAcceptor acceptor

	override protected doRename(EObject target, RenameChange change, RenameContext context) {
		if (target instanceof NoopClass) {
			val uri = target.URI
			val path = new Path(target.URI.path)
			acceptor.accept(uri.trimFragment, new RenameResourceChange(path, '''«change.newName».«path.fileExtension»'''.toString))
		}
		
		super.doRename(target, change, context)
	}

}
