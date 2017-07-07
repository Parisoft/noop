package org.parisoft.noop.generator

import com.google.inject.Inject
import java.util.concurrent.atomic.AtomicInteger
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.noop.Variable

class MetaDataCompiler {

	@Inject extension Classes
	@Inject extension Members
	@Inject extension IQualifiedNameProvider

	def compile(MetaData data) '''
		;----------------------------------------------------------------
		; Class Metadata
		;----------------------------------------------------------------
		«var classCount = 0»
		«FOR noopClass : data.classes.filter[nonPrimitive]»
			«noopClass.name».class = «classCount++»
			«var fieldOffset = 0»
			«FOR field : noopClass.inheritedFields.filter[nonConstant]»
				«field.fullyQualifiedName.toString» = «fieldOffset += field.sizeOf»
			«ENDFOR»
			
		«ENDFOR»
		;----------------------------------------------------------------
		; Constants
		;----------------------------------------------------------------
		«FOR cons : data.constants.sortBy[fullyQualifiedName]»
			«cons.fullyQualifiedName.toString» = «cons.valueOf.toString»
		«ENDFOR»
		
		;----------------------------------------------------------------
		; Singletons
		;----------------------------------------------------------------
		«val addr = new AtomicInteger(0x0400)»
		«FOR singleton : data.singletons»
			_«singleton.name.toLowerCase» = «addr.getAndAdd(singleton.sizeOf).toHexString(4)»
		«ENDFOR»
		
		;----------------------------------------------------------------
		; Variables
		;----------------------------------------------------------------
		«FOR entry : data.variables.entrySet.filter[value.isPointer].sortBy[value.firstPtrAddr + key.fullyQualifiedName.toString]»
			«entry.key.fullyQualifiedName» = «entry.value.firstPtrAddr.toHexString(4)»
		«ENDFOR»
		
		«FOR entry : data.variables.entrySet.filter[value.isVariable].sortBy[value.firstVarAddr + key.fullyQualifiedName.toString]»
			«IF entry.value.isPointer»
				«var iCount = 0»
				«FOR i : entry.key.dimensionOf»
					«entry.key.fullyQualifiedName».len«iCount++» = «entry.value.firstVarAddr.toHexString(4)» ; FIXME
				«ENDFOR»
			«ELSE»
				«entry.key.fullyQualifiedName» = «entry.value.firstVarAddr.toHexString(4)»
			«ENDIF»
		«ENDFOR»
		
		«var tmpCount = 0»
		«FOR entry : data.temps.entrySet.sortBy[value.firstVarAddr]»
			«entry.key».tmp«tmpCount++» = «entry.value.firstVarAddr.toHexString(4)»
		«ENDFOR»
		
		;----------------------------------------------------------------
		; iNES Header
		;----------------------------------------------------------------
			.db 'NES', $1A ;identification of the iNES header
			.db «(data.header.fieldValue('prgRomPages') as Integer).toHexString» ;number of 16KB PRG-ROM pages
			.db «(data.header.fieldValue('chrRomPages') as Integer).toHexString» ;number of 8KB CHR-ROM pages
			.db «(data.header.fieldValue('mapper') as Integer).toHexString» | «(data.header.fieldValue('mirroring') as Integer).toHexString»
			.dsb 9, $00 ;clear the remaining bytes
			
		;----------------------------------------------------------------
		; PRG-ROM Bank(s)
		;----------------------------------------------------------------
			.base $10000 - («(data.header.fieldValue('prgRomPages') as Integer).toHexString» * $4000) 
				 
	'''

	private def toHexString(int value) {
		value.toHexString(2)
	}

	private def toHexString(int value, int len) {
		var string = Integer.toHexString(value).toUpperCase

		while (string.length < len) {
			string = '0' + string
		}

		return '$' + string
	}

	private def fieldValue(Variable variable, String fieldname) {
		(variable.valueOf as NoopInstance).fields.findFirst[name == fieldname]?.valueOf
	}

}
