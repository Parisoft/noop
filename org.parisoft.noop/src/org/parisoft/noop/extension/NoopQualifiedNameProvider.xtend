package org.parisoft.noop.^extension

import org.eclipse.xtext.naming.DefaultDeclarativeQualifiedNameProvider
import org.eclipse.emf.ecore.EObject
import com.google.inject.Inject

class NoopQualifiedNameProvider extends DefaultDeclarativeQualifiedNameProvider {

	@Inject extension TypeSystem

	override getFullyQualifiedName(EObject obj) {
		super.getFullyQualifiedName(obj) ?: if (obj?.eIsProxy) {
			obj.resolve?.fullyQualifiedName
		}
	}

}
