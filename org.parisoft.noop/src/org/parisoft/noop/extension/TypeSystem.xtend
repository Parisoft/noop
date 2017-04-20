package org.parisoft.noop.^extension

import org.parisoft.noop.noop.NoopFactory

class TypeSystem {

	public static val TYPE_OBJECT = NoopFactory::eINSTANCE.createNoopClass => [name = 'Object']
	public static val TYPE_INT = NoopFactory::eINSTANCE.createNoopClass => [name = 'Int']
	public static val TYPE_UINT = NoopFactory::eINSTANCE.createNoopClass => [name = 'UInt' superClass = TYPE_INT]
	public static val TYPE_BYTE = NoopFactory::eINSTANCE.createNoopClass => [name = 'Byte' superClass = TYPE_INT]
	public static val TYPE_CHAR = NoopFactory::eINSTANCE.createNoopClass => [name = 'Char' superClass = TYPE_INT]
	public static val TYPE_BOOL = NoopFactory::eINSTANCE.createNoopClass => [name = 'Bool']
	public static val TYPE_VOID = NoopFactory::eINSTANCE.createNoopClass => [name = 'Void']

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

}
