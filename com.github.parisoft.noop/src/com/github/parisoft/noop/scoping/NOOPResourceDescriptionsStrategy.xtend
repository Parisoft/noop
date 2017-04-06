package com.github.parisoft.noop.scoping

import com.github.parisoft.noop.nOOP.SJBlock
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.resource.impl.DefaultResourceDescriptionStrategy
import org.eclipse.xtext.util.IAcceptor
import com.google.inject.Singleton

@Singleton
class NOOPResourceDescriptionsStrategy extends DefaultResourceDescriptionStrategy {

	override createEObjectDescriptions(EObject e, IAcceptor<IEObjectDescription> acceptor) {
		if (e instanceof SJBlock) {
			false
		} else {
			super.createEObjectDescriptions(e, acceptor)
		}
	}
}
