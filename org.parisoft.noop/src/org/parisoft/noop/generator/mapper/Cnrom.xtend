package org.parisoft.noop.generator.mapper

import com.google.inject.Inject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Collections
import org.parisoft.noop.^extension.Expressions
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.^extension.Statements
import org.parisoft.noop.generator.alloc.AllocContext
import org.parisoft.noop.generator.compile.CompileContext
import org.parisoft.noop.generator.process.ProcessContext

class Cnrom extends Mapper {

	@Inject extension Classes
	@Inject extension Members
	@Inject extension Statements
	@Inject extension Collections
	@Inject extension Expressions
	@Inject extension IQualifiedNameProvider

	override compile(ProcessContext ctx) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override compile(AllocContext ctx) '''
		«val inesPrg = ctx.constants.values.findFirst[INesPrg]?.valueOf as Integer ?: 32»
		«val inesChr = ctx.constants.values.findFirst[INesChr]?.valueOf as Integer ?: 32»
		«val chrBanks = inesChr / 8»
		;----------------------------------------------------------------
		; PRG-ROM Bank(s)
		;----------------------------------------------------------------
			.base $10000 - («(inesPrg / 16).toHexString» * $4000) 
		
		«FOR rom : ctx.prgRoms.values.filter[nonDMC]»
			«rom.compile(new CompileContext)»
		«ENDFOR»
		«IF ctx.methods.values.exists[objectSize] && ctx.constructors.size > 0»
			Object.$sizes:
				.db «ctx.constructors.values.sortBy[type.name].map[type.rawSizeOf].join(', ', [toHexString])»
		«ENDIF»
		
		;-- Methods -----------------------------------------------------
		«FOR method : ctx.methods.values.sortBy[fullyQualifiedName]»
			«method.compile(new CompileContext => [allocation = ctx])»
			
		«ENDFOR»
		;-- Constructors ------------------------------------------------
		«FOR constructor : ctx.constructors.values.sortBy[type.name]»
			«constructor.compile(null)»
			
		«ENDFOR»
		«val dmcList = ctx.prgRoms.values.filter[DMC].toList»
		«IF dmcList.isNotEmpty»
			;-- DMC sound data-----------------------------------------------
				.org «Members::FT_DPCM_OFF»
			«FOR dmcRom : dmcList»
				«dmcRom.compile(new CompileContext)»
			«ENDFOR»
		«ENDIF»
		
		;----------------------------------------------------------------
		; Interrupt vectors
		;----------------------------------------------------------------
			.org $FFFA     
		
			.dw «ctx.methods.values.findFirst[nmi]?.nameOf ?: 0»
			.dw «ctx.methods.values.findFirst[reset]?.nameOf ?: 0»
			.dw «ctx.methods.values.findFirst[irq]?.nameOf ?: 0»
		
		«FOR bank : 0 ..< chrBanks»
			;----------------------------------------------------------------
			; CHR-ROM bank #«bank»
			;----------------------------------------------------------------
				.base $0000
			«FOR rom : ctx.chrRoms.values.filter[(storageOf ?: 0) == bank]»
				«rom.compile(new CompileContext)»
			«ENDFOR»
		«ENDFOR»
	'''

}
