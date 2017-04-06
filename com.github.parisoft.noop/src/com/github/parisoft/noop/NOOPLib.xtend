package com.github.parisoft.noop

import com.github.parisoft.noop.nOOP.SJClass
import com.github.parisoft.noop.scoping.NOOPIndex
import com.google.inject.Inject
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.ResourceSet

class NOOPLib {
	@Inject extension NOOPIndex

	public val static MAIN_LIB = "noop/lang/mainlib.noop"

	public val static LIB_PACKAGE = "noop.lang"
	public val static LIB_OBJECT = LIB_PACKAGE + ".Object"
	public val static LIB_STRING = LIB_PACKAGE + ".String"
	public val static LIB_INTEGER = LIB_PACKAGE + ".Integer"
	public val static LIB_BOOLEAN = LIB_PACKAGE + ".Boolean"

	def loadLib(ResourceSet resourceSet) {
		val url = getClass().getClassLoader().getResource(MAIN_LIB)
		val stream = url.openStream
		val urlPath = url.path
		val resource = resourceSet.createResource(URI.createFileURI(urlPath))
		resource.load(stream, resourceSet.getLoadOptions())
	}

	def getNoopObjectClass(EObject context) {
		val desc = context.getVisibleClassesDescriptions.findFirst[qualifiedName.toString == LIB_OBJECT]
		if (desc === null) {
			return null
		}

		var o = desc.EObjectOrProxy

		if (o.eIsProxy)
			o = context.eResource.resourceSet.getEObject(desc.EObjectURI, true)
		o as SJClass
	}
}
