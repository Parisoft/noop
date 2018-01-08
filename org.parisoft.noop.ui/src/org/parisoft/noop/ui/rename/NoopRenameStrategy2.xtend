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
import org.parisoft.noop.^extension.Files

class NoopRenameStrategy2 extends IRenameStrategy2.DefaultImpl {

	@Inject extension Files
	
	@Inject IRefactoringUpdateAcceptor acceptor

	override protected doRename(EObject target, RenameChange change, RenameContext context) {
		if (target instanceof NoopClass) {
			val uri = target.URI
			val path = new Path(target.URI.path)
//			acceptor.accept(uri.trimFragment, new RenameResourceChange(path, '''«change.newName».«path.fileExtension»'''.toString))
			val oldFile = uri.toFile
			var newFile = target.URI.trimFragment.trimFileExtension.trimSegments(1).appendSegment(change.newName).appendFileExtension(uri.fileExtension).appendFragment(uri.fragment).toFile
			oldFile.renameTo(newFile)
		}
		
		super.doRename(target, change, context)
	}

}
