package org.parisoft.noop.^extension

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.NoopFactory
import org.parisoft.noop.scoping.NoopIndex

class TypeSystem {

	private static val typeCache = <String, NoopClass>newHashMap()

	public static val LIB_PACKAGE = "noop.lang"
	public static val LIB_OBJECT = "Object" // LIB_PACKAGE + ".Object"
	public static val LIB_INT = "Int" // LIB_PACKAGE + ".Int"
	public static val LIB_UINT = "UInt" // LIB_PACKAGE + ".UInt"
	public static val LIB_SBYTE = "SByte" // LIB_PACKAGE + ".Byte"
	public static val LIB_BYTE = "Byte" // LIB_PACKAGE + ".Char"
	public static val LIB_BOOL = "Bool" // LIB_PACKAGE + ".Bool"
	public static val LIB_VOID = "Void" // LIB_PACKAGE + ".Void"
	public static val LIB_PRIMITIVE = "Primitive"
	public static val LIB_NES_HEADER = "INESHeader"
	public static val LIB_GAME = "Game"
	
	public static val MIN_INT = -32768
	public static val MAX_INT = 32767
	public static val MIN_UINT = 0
	public static val MAX_UINT = 65535
	public static val MIN_SBYTE = -128
	public static val MAX_SBYTE = 127
	public static val MIN_BYTE = 0
	public static val MAX_BYTE = 255
	
	public static val TYPE_VOID = NoopFactory::eINSTANCE.createNoopClass => [name = LIB_VOID]
	public static val TYPE_OBJECT = NoopFactory::eINSTANCE.createNoopClass => [name = LIB_OBJECT]
	public static val TYPE_PRIMITIVE = NoopFactory::eINSTANCE.createNoopClass => [name = LIB_PRIMITIVE]
	public static val TYPE_INT = NoopFactory::eINSTANCE.createNoopClass => [name = LIB_INT superClass = TYPE_PRIMITIVE]
	public static val TYPE_UINT = NoopFactory::eINSTANCE.createNoopClass => [name = LIB_UINT superClass = TYPE_INT]
	public static val TYPE_SBYTE = NoopFactory::eINSTANCE.createNoopClass => [name = LIB_SBYTE superClass = TYPE_INT]
	public static val TYPE_BYTE = NoopFactory::eINSTANCE.createNoopClass => [name = LIB_BYTE superClass = TYPE_INT]
	public static val TYPE_BOOL = NoopFactory::eINSTANCE.createNoopClass => [name = LIB_BOOL superClass = TYPE_PRIMITIVE]

	@Inject extension IQualifiedNameProvider
	@Inject extension NoopIndex

	def toObjectClass(EObject context) {
		toClassOrDefault(context, LIB_OBJECT, TYPE_OBJECT)
	}

	def toIntClass(EObject context) {
		toClassOrDefault(context, LIB_INT, TYPE_INT)
	}

	def toUIntClass(EObject context) {
		toClassOrDefault(context, LIB_UINT, TYPE_UINT)
	}

	def toSByteClass(EObject context) {
		toClassOrDefault(context, LIB_SBYTE, TYPE_SBYTE)
	}

	def toByteClass(EObject context) {
		toClassOrDefault(context, LIB_BYTE, TYPE_BYTE)
	}

	def toBoolClass(EObject context) {
		toClassOrDefault(context, LIB_BOOL, TYPE_BOOL)
	}

	def toVoidClass(EObject context) {
		toClassOrDefault(context, LIB_VOID, TYPE_VOID)
	}

	def toClassOrDefault(EObject context, String type, NoopClass ^default) {
		typeCache.computeIfAbsent(type, [
			if (context.fullyQualifiedName == type && context instanceof NoopClass) {
				return context as NoopClass;
			}

			val desc = context.getVisibleClassesDescriptions.findFirst[qualifiedName.toString == type]

			if (desc === null) {
				return null
			}

			var o = desc.EObjectOrProxy

			if (o.eIsProxy) {
				o = context.eResource.resourceSet.getEObject(desc.EObjectURI, true)
			}

			o as NoopClass
		]) ?: ^default
	}
}
