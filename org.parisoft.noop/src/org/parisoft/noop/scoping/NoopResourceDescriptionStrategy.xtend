package org.parisoft.noop.scoping

import com.google.inject.Inject
import com.google.inject.Singleton
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.resource.EObjectDescription
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.resource.impl.DefaultResourceDescriptionStrategy
import org.eclipse.xtext.util.IAcceptor
import org.parisoft.noop.noop.NoopClass

@Singleton
class NoopResourceDescriptionStrategy extends DefaultResourceDescriptionStrategy {

	@Inject extension IQualifiedNameProvider

	override createEObjectDescriptions(EObject eObject, IAcceptor<IEObjectDescription> acceptor) {
		if (eObject instanceof NoopClass) {
			val fullyQualifiedName = eObject.fullyQualifiedName

			if (fullyQualifiedName !== null) {
				acceptor.accept(EObjectDescription::create(fullyQualifiedName, eObject))
			}

			true
		} else {
			false
		}
	}
}
