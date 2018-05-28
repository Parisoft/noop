package org.parisoft.noop.^extension

import com.google.inject.Inject
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.resource.XtextResourceSet
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.NoopFactory
import org.parisoft.noop.scoping.NoopIndex

import static extension org.eclipse.emf.ecore.util.EcoreUtil.*

class TypeSystem {

	public static val LIB_PACKAGE = 'org.parisoft.noop'
	public static val LIB_OBJECT = 'Object' // LIB_PACKAGE + '.Object'
	public static val LIB_PRIMITIVE = 'Primitive'
	public static val LIB_INT = 'Int' // LIB_PACKAGE + '.Int'
	public static val LIB_UINT = 'UInt' // LIB_PACKAGE + '.UInt'
	public static val LIB_SBYTE = 'SByte' // LIB_PACKAGE + '.Byte'
	public static val LIB_BYTE = 'Byte' // LIB_PACKAGE + '.Char'
	public static val LIB_BOOL = 'Bool' // LIB_PACKAGE + '.Bool'
	public static val LIB_VOID = 'Void' // LIB_PACKAGE + '.Void'
	public static val LIB_MATH = 'Math'
	public static val LIB_NES_HEADER = 'INESHeader'
	public static val LIB_GAME = 'Game'

	public static val LIB_NUMBERS = newArrayList(LIB_BYTE, LIB_SBYTE, LIB_INT, LIB_UINT)
	public static val LIB_PRIMITIVES = newArrayList(LIB_PRIMITIVE, LIB_BOOL) + LIB_NUMBERS

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
	public static val TYPE_INT = NoopFactory::eINSTANCE.createNoopClass => [
		name = LIB_INT
		superClass = TYPE_PRIMITIVE
	]
	public static val TYPE_UINT = NoopFactory::eINSTANCE.createNoopClass => [
		name = LIB_UINT
		superClass = TYPE_PRIMITIVE
	]
	public static val TYPE_SBYTE = NoopFactory::eINSTANCE.createNoopClass => [
		name = LIB_SBYTE
		superClass = TYPE_PRIMITIVE
	]
	public static val TYPE_BYTE = NoopFactory::eINSTANCE.createNoopClass => [
		name = LIB_BYTE
		superClass = TYPE_PRIMITIVE
	]
	public static val TYPE_BOOL = NoopFactory::eINSTANCE.createNoopClass => [
		name = LIB_BOOL
		superClass = TYPE_PRIMITIVE
	]
	public static val TYPE_MATH = NoopFactory::eINSTANCE.createNoopClass => [
		name = LIB_MATH
		superClass = TYPE_OBJECT
	]

	public static val context = new ThreadLocal<NoopClass>

	@Inject extension IQualifiedNameProvider
	@Inject extension NoopIndex

	@Inject XtextResourceSet resourceSet

	def resolve(EObject o) {
		try {
			resourceSet.getEObject(o.URI, true) as NoopClass ?: o.resolveAsLib
		} catch (Exception e) {
			o.resolveAsLib
		}
	}

	private def resolveAsLib(EObject c) {
		val i = c.URI.toString.indexOf(LIB_PACKAGE)

		if (i > -1) {
			val uri = URI::createURI(c.URI.trimFragment.toString.substring(i + LIB_PACKAGE.length))
			val obj = try {
					resourceSet.getEObject(uri.appendFragment(c.URI.fragment), false) as NoopClass
				} catch (Exception e) {
					null
				}

			if (obj !== null) {
				obj as NoopClass
			} else {
				val stream = class.classLoader.getResourceAsStream(uri.toString)
				resourceSet.createResource(uri) => [load(stream, resourceSet.loadOptions)]
				resourceSet.getEObject(uri.appendFragment(c.URI.fragment), true) as NoopClass
			}
		}
	}

	def toObjectClass(EObject context) {
		toClassOrDefault(context, LIB_OBJECT, TYPE_OBJECT)
	}

	def toMathClass(EObject context) {
		toClassOrDefault(context, LIB_MATH, TYPE_MATH)
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
		try {
			if (context.fullyQualifiedName == type && context instanceof NoopClass) {
				return context as NoopClass;
			}

			val desc = context.visibleClassesDescriptions.findFirst[qualifiedName.toString == type]
			var obj = desc.EObjectOrProxy

			if (obj.eIsProxy) {
				obj = context.eResource.resourceSet.getEObject(desc.EObjectURI, true)
			}

			obj as NoopClass ?: type.toClassOrDefault(^default)
		} catch (Exception exception) {
			type.toClassOrDefault(^default)
		}
	}

	private def toClassOrDefault(String type, NoopClass ^default) {
		try {
			val context = TypeSystem::context.get

			if (context.fullyQualifiedName == type && context instanceof NoopClass) {
				return context as NoopClass;
			}

			val desc = context.visibleClassesDescriptions.findFirst[qualifiedName.toString == type]
			var obj = desc.EObjectOrProxy

			if (obj.eIsProxy) {
				obj = context.eResource.resourceSet.getEObject(desc.EObjectURI, true)
			}

			obj as NoopClass ?: ^default
		} catch (Exception exception) {
			^default
		}
	}
}
