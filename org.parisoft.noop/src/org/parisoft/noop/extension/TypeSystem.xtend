package org.parisoft.noop.^extension

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.NoopFactory
import org.parisoft.noop.scoping.NoopIndex

class TypeSystem {

	@Inject extension IQualifiedNameProvider
	@Inject extension NoopIndex

	public static val TYPE_OBJECT = NoopFactory::eINSTANCE.createNoopClass => [name = 'Object']
	public static val TYPE_INT = NoopFactory::eINSTANCE.createNoopClass => [name = 'Int' superClass = TYPE_OBJECT]
	public static val TYPE_UINT = NoopFactory::eINSTANCE.createNoopClass => [name = 'UInt' superClass = TYPE_INT]
	public static val TYPE_BYTE = NoopFactory::eINSTANCE.createNoopClass => [name = 'Byte' superClass = TYPE_INT]
	public static val TYPE_CHAR = NoopFactory::eINSTANCE.createNoopClass => [name = 'Char' superClass = TYPE_INT]
//	public static val TYPE_BOOL = NoopFactory::eINSTANCE.createNoopClass => [name = 'Bool' superClass = TYPE_OBJECT]
	public static val TYPE_VOID = NoopFactory::eINSTANCE.createNoopClass => [name = 'Void' superClass = TYPE_OBJECT]

	public static val LIB_PACKAGE = "noop.lang"
	public static val LIB_OBJECT = LIB_PACKAGE + ".Object"
	public static val LIB_INT = LIB_PACKAGE + ".Int"
	public static val LIB_UINT = LIB_PACKAGE + ".UInt"
	public static val LIB_BYTE = LIB_PACKAGE + ".Byte"
	public static val LIB_CHAR = LIB_PACKAGE + ".Char"
	public static val LIB_BOOL = LIB_PACKAGE + ".Bool"
	public static val LIB_VOID = LIB_PACKAGE + ".Void"

	public static val MIN_INT = -32768
	public static val MAX_INT = 32767
	public static val MIN_UINT = 0
	public static val MAX_UINT = 65535
	public static val MIN_BYTE = -128
	public static val MAX_BYTE = 127
	public static val MIN_CHAR = 0
	public static val MAX_CHAR = 255

	def getBoolType(EObject context) {
		if (context.fullyQualifiedName == LIB_BOOL) {
			return context as NoopClass;
		}

		val desc = context.getVisibleClassesDescriptions.findFirst[qualifiedName.toString == LIB_BOOL]

		if (desc === null) {
			return null
		}

		var o = desc.EObjectOrProxy

		if (o.eIsProxy) {
			o = context.eResource.resourceSet.getEObject(desc.EObjectURI, true)
		}

		o as NoopClass
	}

}
