package org.parisoft.noop.scoping

import com.google.inject.Inject
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.resource.IContainer
import org.eclipse.xtext.resource.impl.ResourceDescriptionsProvider
import org.parisoft.noop.noop.NoopPackage

class NoopIndex {

	@Inject ResourceDescriptionsProvider rdp
	@Inject IContainer.Manager cm

	def getVisibleEObjectDescriptions(EObject o) {
		o.getVisibleContainers.map [ container |
			container.getExportedObjects
		].flatten
	}

	def getVisibleEObjectDescriptions(EObject o, EClass type) {
		o.getVisibleContainers.map [ container |
			container.getExportedObjectsByType(type)
		].flatten
	}

	def getVisibleClassesDescriptions(EObject o) {
		o.getVisibleEObjectDescriptions(NoopPackage::eINSTANCE.noopClass)
	}

	def getVisibleContainers(EObject o) {
		val resource = o.eResource

		if (resource === null) {
			return emptyList
		}

		val index = rdp.getResourceDescriptions(resource)
		val rd = index.getResourceDescription(resource.URI)

		if (rd === null) {
			return emptyList
		}

		return cm.getVisibleContainers(rd, index)
	}

	def getResourceDescription(EObject o) {
		val index = rdp.getResourceDescriptions(o.eResource)
		index.getResourceDescription(o.eResource.URI)
	}

	def getExportedEObjectDescriptions(EObject o) {
		o.getResourceDescription.getExportedObjects
	}
}
