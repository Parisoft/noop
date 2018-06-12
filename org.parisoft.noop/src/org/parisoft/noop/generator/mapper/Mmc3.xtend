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
import org.parisoft.noop.noop.StorageType
import org.parisoft.noop.noop.Variable
import org.parisoft.noop.^extension.Variables
import org.parisoft.noop.^extension.Methods

class Mmc3 extends Mapper {

	@Inject extension Classes
	@Inject extension Members
	@Inject extension Methods
	@Inject extension Variables
	@Inject extension Statements
	@Inject extension Collections
	@Inject extension Expressions
	@Inject extension IQualifiedNameProvider

	override compile(AllocContext ctx) '''
		«val inesPrg = ctx.constants.values.findFirst[INesPrg]?.valueOf as Integer ?: 32»
		«val inesChr = ctx.constants.values.findFirst[INesChr]?.valueOf as Integer ?: 32»
		«val prgBanks = inesPrg / 8»
		«val chrBanks = inesChr / 8»
		«val mode = (ctx.constants.values.findFirst[MMC3Config]?.valueOf as Integer ?: 0).bitwiseAnd(64)»
		«val fixedBank0 = prgBanks - 2»
		«val fixedBank1 = prgBanks - 1»
		«val evenAddr = if (mode == 0) '$8000' else '$C000'»
		«val oddAddr = '$A000'»
		«val fixedAddr0 = if (mode == 0) '$C000' else '$8000'»
		«val fixedAddr1 = '$E000'»
		«FOR bank : 0 ..< prgBanks»
			«val base = if (bank == fixedBank1) {
				fixedAddr1
			}else if (bank == fixedBank0){
				fixedAddr0
			}else if( bank % 2 == 0){
				evenAddr
			}else{
				oddAddr
			}»
			;----------------------------------------------------------------
			; PRG-ROM Bank #«bank»«IF bank == fixedBank0 || bank == fixedBank1» FIXED«ENDIF»
			;----------------------------------------------------------------
				.base «base» 
			
			«val dmcList = ctx.prgRoms.values.filter[DMC].filter[(storageOf ?: fixedBank1) == bank].toList»
			«IF dmcList.isNotEmpty»
				;-- DMC sound data-----------------------------------------------
				«FOR dmcRom : dmcList»
					«dmcRom.compile(new CompileContext)»
				«ENDFOR»
			«ENDIF»
			«FOR rom : ctx.prgRoms.values.filter[nonDMC].filter[(storageOf ?: fixedBank1) == bank]»
				«rom.compile(new CompileContext)»
			«ENDFOR»
			«IF ctx.methods.values.exists[objectSize] && ctx.constructors.size > 0 && bank == fixedBank1»
				Object.$sizes:
					.db «ctx.constructors.values.sortBy[type.name].map[type.rawSizeOf].join(', ', [toHexString])»
			«ENDIF»
			«val methods = ctx.methods.values.filter[(storageOf ?: fixedBank1) == bank].sortBy[fullyQualifiedName]»
			«IF methods.isNotEmpty»
				«noop»
				;-- Methods -----------------------------------------------------
				«FOR method : methods»
					«method.compile(new CompileContext => [allocation = ctx])»
					
				«ENDFOR»
			«ENDIF»
			«IF bank == fixedBank1»
				«val constructors = ctx.constructors.values.sortBy[type.name]»
				«IF constructors.isNotEmpty»
					;-- Constructors ------------------------------------------------
					«FOR constructor : constructors»
						«constructor.compile(null)»
						
					«ENDFOR»
				«ENDIF»
			«ELSEIF base == '$8000'»
				«noop»
					.org $A000
			«ELSEIF base == '$A000'»
				«noop»
					.org $C000
			«ELSEIF base == '$C000'»
				«noop»
					.org $E000
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
			«val bank0 = bank * 8»
			«var roms = ctx.chrRoms.values.filter[(storageOf ?: 0) == bank0]»
			«IF roms.isNotEmpty»
				;----------------------------------------------------------------
				; CHR-ROM bank #«bank0»
				;----------------------------------------------------------------
					.base $0000
				«FOR rom : roms»
					«rom.compile(new CompileContext)»
				«ENDFOR»
			«ENDIF»
			«val bank2 = bank0 + 2»
			«IF (roms = ctx.chrRoms.values.filter[(storageOf ?: 0) == bank2]).isNotEmpty»
				;----------------------------------------------------------------
				; CHR-ROM bank #«bank2»
				;----------------------------------------------------------------
					.base $0800
				«FOR rom : roms»
					«rom.compile(new CompileContext)»
				«ENDFOR»
			«ENDIF»
			«val bank4 = bank2 + 2»
			«IF (roms = ctx.chrRoms.values.filter[(storageOf ?: 0) == bank4]).isNotEmpty»
				;----------------------------------------------------------------
				; CHR-ROM bank #«bank4»
				;----------------------------------------------------------------
					.base $1000
				«FOR rom : roms»
					«rom.compile(new CompileContext)»
				«ENDFOR»
			«ENDIF»
			«val bank5 = bank4 + 1»
			«IF (roms = ctx.chrRoms.values.filter[(storageOf ?: 0) == bank5]).isNotEmpty»
				;----------------------------------------------------------------
				; CHR-ROM bank #«bank5»
				;----------------------------------------------------------------
					.base $1400
				«FOR rom : roms»
					«rom.compile(new CompileContext)»
				«ENDFOR»
			«ENDIF»
			«val bank6 = bank5 + 1»
			«IF (roms = ctx.chrRoms.values.filter[(storageOf ?: 0) == bank6]).isNotEmpty»
				;----------------------------------------------------------------
				; CHR-ROM bank #«bank6»
				;----------------------------------------------------------------
					.base $1800
				«FOR rom : roms»
					«rom.compile(new CompileContext)»
				«ENDFOR»
			«ENDIF»
			«val bank7 = bank6 + 1»
			«IF (roms = ctx.chrRoms.values.filter[(storageOf ?: 0) == bank7]).isNotEmpty»
				;----------------------------------------------------------------
				; CHR-ROM bank #«bank7»
				;----------------------------------------------------------------
					.base $1C00
				«FOR rom : roms»
					«rom.compile(new CompileContext)»
				«ENDFOR»
			«ENDIF»
		«ENDFOR»
	'''

	private def isMMC3Config(Variable variable) {
		variable.storage?.type == StorageType::MMC3CFG
	}
}
