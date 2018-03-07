package org.parisoft.noop.generator.mapper

import com.google.inject.Inject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Collections
import org.parisoft.noop.^extension.Expressions
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.^extension.Statements
import org.parisoft.noop.generator.AllocContext
import org.parisoft.noop.generator.CompileContext

class Unrom extends Mapper {

	@Inject extension Classes
	@Inject extension Members
	@Inject extension Statements
	@Inject extension Collections
	@Inject extension Expressions
	@Inject extension IQualifiedNameProvider

	override compile(AllocContext ctx) '''
		«val inesPrg = ctx.constants.values.findFirst[INesPrg]?.valueOf as Integer ?: 32»
		«val banks = inesPrg / 16»
		«val defaultBank = banks - 1»
		«FOR bank : 0 ..< banks»
			;----------------------------------------------------------------
			; PRG-ROM Bank #«bank»«IF bank == defaultBank» FIXED«ENDIF»
			;----------------------------------------------------------------
				.base «IF bank == defaultBank»$C000«ELSE»$8000«ENDIF» 
			
			«FOR rom : ctx.prgRoms.values.filter[nonDMC].filter[(storageOf ?: defaultBank) == bank]»
				«rom.compile(new CompileContext)»
			«ENDFOR»
			«IF ctx.methods.values.exists[objectSize] && ctx.constructors.size > 0 && bank == defaultBank»
				Object.$sizes:
					.db «ctx.constructors.values.sortBy[type.name].map[type.rawSizeOf].join(', ', [toHexString])»
			«ENDIF»
			«val methods = ctx.methods.values.filter[(storageOf ?: defaultBank) == bank].sortBy[fullyQualifiedName]»
			«IF methods.isNotEmpty»
				«noop»
				
				;-- Methods -----------------------------------------------------
				«FOR method : methods»
					«method.compile(new CompileContext => [allocation = ctx])»
					
				«ENDFOR»
			«ENDIF»
			«IF bank == defaultBank»
				«val constructors = ctx.constructors.values.sortBy[type.name]»
				«IF constructors.isNotEmpty»
					;-- Constructors ------------------------------------------------
					«FOR constructor : constructors»
						«constructor.compile(null)»
						
					«ENDFOR»
				«ENDIF»
			«ENDIF»
			«val dmcList = ctx.prgRoms.values.filter[DMC].filter[(storageOf ?: defaultBank) == bank].toList»
			«IF dmcList.isNotEmpty»
				;-- DMC sound data-----------------------------------------------
					.org «Members::FT_DPCM_OFF»
				«FOR dmcRom : dmcList»
					«dmcRom.compile(new CompileContext)»
				«ENDFOR»
			«ENDIF»
			«IF bank != defaultBank»
				«noop»
					.org $C000
			«ENDIF»
		«ENDFOR»
		
		;----------------------------------------------------------------
		; Interrupt vectors
		;----------------------------------------------------------------
			.org $FFFA     
		
		 	.dw «ctx.methods.values.findFirst[nmi]?.nameOf ?: 0»
		 	.dw «ctx.methods.values.findFirst[reset]?.nameOf ?: 0»
		 	.dw «ctx.methods.values.findFirst[irq]?.nameOf ?: 0»
	'''

}
