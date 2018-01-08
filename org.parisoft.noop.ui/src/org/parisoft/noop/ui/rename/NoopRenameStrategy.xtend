package org.parisoft.noop.ui.rename

import org.eclipse.core.runtime.Path
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.ltk.core.refactoring.resource.RenameResourceChange
import org.eclipse.xtext.ui.refactoring.IChangeRedirector
import org.eclipse.xtext.ui.refactoring.IRefactoringUpdateAcceptor
import org.eclipse.xtext.ui.refactoring.impl.DefaultRenameStrategy
import org.eclipse.xtext.ui.refactoring.impl.RefactoringException
import org.eclipse.xtext.ui.refactoring.ui.IRenameElementContext
import org.parisoft.noop.noop.NoopClass

import static extension org.eclipse.xtext.EcoreUtil2.*

class NoopRenameStrategy extends DefaultRenameStrategy {

	private IRenameElementContext context;

	override initialize(EObject targetElement, IRenameElementContext context) {
		this.context = context
		super.initialize(targetElement, context)
	}

	override createDeclarationUpdates(String newName, ResourceSet resourceSet, IRefactoringUpdateAcceptor acceptor) {
		super.createDeclarationUpdates(newName, resourceSet, acceptor)

		val path = getPathToRename(targetElementOriginalURI, resourceSet)

		if (path?.lastSegment == originalName + '.noop') {
			acceptor.accept(targetElementOriginalURI.trimFragment,
				new RenameResourceChange(path, '''«newName».«path.fileExtension»'''))
		}
	}

	def getPathToRename(URI elementURI, ResourceSet resourceSet) {
		val targetObject = resourceSet.getEObject(elementURI, false)

		if (targetObject instanceof NoopClass) {
			val resourceURI = targetObject.platformResourceOrNormalizedURI.trimFragment

			if (!resourceURI.isPlatformResource) {
				throw new RefactoringException("Renamed type does not reside in the workspace")
			}

			val path = new Path(resourceURI.toPlatformString(true))

			if (context instanceof IChangeRedirector.Aware) {
				if (context.changeRedirector.getRedirectedPath(path) != path) {
					return null
				}
			}

			return path
		}

		return null
	}

}
