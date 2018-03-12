package org.parisoft.noop.generator.mapper

import org.parisoft.noop.generator.AllocContext
import com.google.inject.Inject
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.^extension.Statements
import org.parisoft.noop.^extension.Collections
import org.parisoft.noop.^extension.Expressions
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.generator.CompileContext

class Mmc3 extends Mapper {

	@Inject extension Classes
	@Inject extension Members
	@Inject extension Statements
	@Inject extension Collections
	@Inject extension Expressions
	@Inject extension IQualifiedNameProvider

	override compile(AllocContext ctx) '''
		«val inesPrg = ctx.constants.values.findFirst[INesPrg]?.valueOf as Integer ?: 32»
		«val inesChr = ctx.constants.values.findFirst[INesChr]?.valueOf as Integer ?: 32»
		«val prgBanks = inesPrg / 8 - 1»
		«val chrBanks = inesChr / 8»
		«val fixedBank = prgBanks - 1»
		«FOR bank : 0 ..< prgBanks»
			;----------------------------------------------------------------
			; PRG-ROM Bank #«bank»«IF bank >= fixedBank» FIXED«ENDIF»
			;----------------------------------------------------------------
				.base «IF bank == fixedBank»$C000«ELSEIF bank % 2 != 0»$A000«ELSE»$8000«ENDIF» 
			
			«FOR rom : ctx.prgRoms.values.filter[nonDMC].filter[(storageOf ?: fixedBank) == bank]»
				«rom.compile(new CompileContext)»
			«ENDFOR»
			«IF ctx.methods.values.exists[objectSize] && ctx.constructors.size > 0 && bank == fixedBank»
				Object.$sizes:
					.db «ctx.constructors.values.sortBy[type.name].map[type.rawSizeOf].join(', ', [toHexString])»
			«ENDIF»
			«val methods = ctx.methods.values.filter[(storageOf ?: fixedBank) == bank].sortBy[fullyQualifiedName]»
			«IF methods.isNotEmpty»
				«noop»
				
				;-- Methods -----------------------------------------------------
				«FOR method : methods»
					«method.compile(new CompileContext => [allocation = ctx])»
					
				«ENDFOR»
			«ENDIF»
			«IF bank == fixedBank»
				«val constructors = ctx.constructors.values.sortBy[type.name]»
				«IF constructors.isNotEmpty»
					;-- Constructors ------------------------------------------------
					«FOR constructor : constructors»
						«constructor.compile(null)»
						
					«ENDFOR»
				«ENDIF»
			«ENDIF»
			«val dmcList = ctx.prgRoms.values.filter[DMC].filter[(storageOf ?: fixedBank) == bank].toList»
			«IF dmcList.isNotEmpty»
				;-- DMC sound data-----------------------------------------------
					.org «Members::FT_DPCM_OFF»
				«FOR dmcRom : dmcList»
					«dmcRom.compile(new CompileContext)»
				«ENDFOR»
			«ENDIF»
			«noop»
				«IF bank != fixedBank && bank % 2 != 0»
					.org $C000
				«ELSEIF bank != fixedBank»
					.org $A000
				«ENDIF»
		«ENDFOR»
		
		;----------------------------------------------------------------
		; Interrupt vectors
		;----------------------------------------------------------------
			.org $FFFA     
		
		 	.dw «ctx.methods.values.findFirst[nmi]?.nameOf ?: 0»
		 	.dw «ctx.methods.values.findFirst[reset]?.nameOf ?: 0»
		 	.dw «ctx.methods.values.findFirst[irq]?.nameOf ?: 0»
		
		«FOR bank : 0 ..< chrBanks»
			;----------------------------------------------------------------
			; CHR-ROM bank #«bank * 6»
			;----------------------------------------------------------------
				.base $0000
			«FOR rom : ctx.chrRoms.values.filter[(storageOf ?: 0) == bank * 6]»
				«rom.compile(new CompileContext)»
			«ENDFOR»
			;----------------------------------------------------------------
			; CHR-ROM bank #«bank * 6 + 1»
			;----------------------------------------------------------------
				.base $0800
			«FOR rom : ctx.chrRoms.values.filter[(storageOf ?: 0) == bank * 6 + 1]»
				«rom.compile(new CompileContext)»
			«ENDFOR»
			;----------------------------------------------------------------
			; CHR-ROM bank #«bank * 6 + 2»
			;----------------------------------------------------------------
				.base $1000
			«FOR rom : ctx.chrRoms.values.filter[(storageOf ?: 0) == bank * 6 + 2]»
				«rom.compile(new CompileContext)»
			«ENDFOR»
			;----------------------------------------------------------------
			; CHR-ROM bank #«bank * 6 + 3»
			;----------------------------------------------------------------
				.base $1400
			«FOR rom : ctx.chrRoms.values.filter[(storageOf ?: 0) == bank * 6 + 3]»
				«rom.compile(new CompileContext)»
			«ENDFOR»
			;----------------------------------------------------------------
			; CHR-ROM bank #«bank * 6 + 4»
			;----------------------------------------------------------------
				.base $1800
			«FOR rom : ctx.chrRoms.values.filter[(storageOf ?: 0) == bank * 6 + 4]»
				«rom.compile(new CompileContext)»
			«ENDFOR»
			;----------------------------------------------------------------
			; CHR-ROM bank #«bank * 6 + 5»
			;----------------------------------------------------------------
				.base $1C00
			«FOR rom : ctx.chrRoms.values.filter[(storageOf ?: 0) == bank * 6 + 5]»
				«rom.compile(new CompileContext)»
			«ENDFOR»
		«ENDFOR»
	'''

}
