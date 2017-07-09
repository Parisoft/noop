package org.parisoft.noop.generator

import com.google.inject.Inject
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
		«FOR singleton : data.singletons»
			_«singleton.name.toLowerCase» = «data.varCounter.getAndAdd(singleton.sizeOf).toHexString(4)»
		«ENDFOR»
		
		;----------------------------------------------------------------
		; Variables
		;----------------------------------------------------------------
		«FOR method : data.pointers.entrySet»
			«FOR entry : method.value.entrySet.sortBy[value.low]»
				«entry.key.fullyQualifiedName» = «entry.value.low.toHexString(4)»
			«ENDFOR»
		«ENDFOR»
		
		«FOR method : data.variables.entrySet»
			«FOR entry : method.value.entrySet.sortBy[value.low]»
				«entry.key.fullyQualifiedName» = «entry.value.low.toHexString(4)»
			«ENDFOR»
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
