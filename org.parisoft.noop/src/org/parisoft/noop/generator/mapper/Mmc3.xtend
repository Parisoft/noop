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
import org.parisoft.noop.noop.StorageType
import org.parisoft.noop.noop.Variable
import org.parisoft.noop.generator.process.ProcessContext
import java.util.LinkedHashMap
import java.util.HashMap

class Mmc3 extends Mapper {

	@Inject extension Classes
	@Inject extension Members
	@Inject extension Statements
	@Inject extension Collections
	@Inject extension Expressions
	@Inject extension IQualifiedNameProvider

	override compile(ProcessContext ctx) '''
		«val inesPrg = ctx.headers.get(StorageType::INESPRG) as Integer ?: 32»
		«val inesChr = ctx.headers.get(StorageType::INESCHR) as Integer ?: 32»
		«val prgBanks = inesPrg / 8»
		«val chrBanks = inesChr / 8»
		«val mode = (ctx.headers.get(StorageType::MMC3CFG) as Integer ?: 0).bitwiseAnd(64)»
		«val fixedBank0 = prgBanks - 2»
		«val fixedBank1 = prgBanks - 1»
		«val evenAddr = if (mode == 0) '$8000' else '$C000'»
		«val oddAddr = '$A000'»
		«val fixedAddr0 = if (mode == 0) '$C000' else '$8000'»
		«val fixedAddr1 = '$E000'»
		«ctx.prepareRoms(fixedBank1)»
		;----------------------------------------------------------------
		; Macros
		;----------------------------------------------------------------
		enable_irq = 1
		«FOR directive : ctx.directives»
			«directive»
		«ENDFOR»
		«FOR macro : ctx.macros.entrySet»
			«noop»
				.macro «macro.key»
				«macro.value»
				.endm
		«ENDFOR»
		
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
			
			«val dmcList = ctx.dmcRoms.get(bank)?.values ?: emptyList»
			«IF dmcList.isNotEmpty»
				;-- DMC sound data-----------------------------------------------
				«FOR dmcRom : dmcList»
					«dmcRom»
				«ENDFOR»
				
			«ENDIF»
			«FOR rom : ctx.prgRoms.get(bank)?.values ?: emptyList»
				«rom»
			«ENDFOR»
			
			«val methods = ctx.methodsByBank.get(bank)?.entrySet?.sortBy[key] ?: emptySet»
			«IF methods.isNotEmpty»
				;-- Methods -----------------------------------------------------
				«FOR method : methods»
					«method.value»
					
				«ENDFOR»
			«ENDIF»
			«IF bank == fixedBank1»
				«val classes = ctx.metaClasses.values.filter[ctx.constructors.contains(name)].sortBy[name]»
				«IF classes.isNotEmpty»
					;-- Constructors ------------------------------------------------
					«FOR clazz : classes»
						«clazz.constructor»
						
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
		
		 	.dw «ctx.ast.vectors.get('nmi') ?: 0»
		 	.dw «ctx.ast.vectors.get('reset') ?: 0»
		 	.dw «ctx.ast.vectors.get('irq') ?: 0»
		
		«FOR bank : 0 ..< chrBanks»
			«val bank0 = bank * 8»
			«var roms = ctx.chrRoms.get(bank0)?.values ?: emptyList»
			«IF roms.isNotEmpty»
				;----------------------------------------------------------------
				; CHR-ROM bank #«bank0»
				;----------------------------------------------------------------
					.base $0000
				«FOR rom : roms»
					«rom»
				«ENDFOR»
			«ENDIF»
			«val bank2 = bank0 + 2»
			«IF (roms = ctx.chrRoms.get(bank2)?.values ?: emptyList).isNotEmpty»
				;----------------------------------------------------------------
				; CHR-ROM bank #«bank2»
				;----------------------------------------------------------------
					.base $0800
				«FOR rom : roms»
					«rom»
				«ENDFOR»
			«ENDIF»
			«val bank4 = bank2 + 2»
			«IF (roms = ctx.chrRoms.get(bank4)?.values ?: emptyList).isNotEmpty»
				;----------------------------------------------------------------
				; CHR-ROM bank #«bank4»
				;----------------------------------------------------------------
					.base $1000
				«FOR rom : roms»
					«rom»
				«ENDFOR»
			«ENDIF»
			«val bank5 = bank4 + 1»
			«IF (roms = ctx.chrRoms.get(bank5)?.values ?: emptyList).isNotEmpty»
				;----------------------------------------------------------------
				; CHR-ROM bank #«bank5»
				;----------------------------------------------------------------
					.base $1400
				«FOR rom : roms»
					«rom»
				«ENDFOR»
			«ENDIF»
			«val bank6 = bank5 + 1»
			«IF (roms = ctx.chrRoms.get(bank6)?.values ?: emptyList).isNotEmpty»
				;----------------------------------------------------------------
				; CHR-ROM bank #«bank6»
				;----------------------------------------------------------------
					.base $1800
				«FOR rom : roms»
					«rom»
				«ENDFOR»
			«ENDIF»
			«val bank7 = bank6 + 1»
			«IF (roms = ctx.chrRoms.get(bank7)?.values ?: emptyList).isNotEmpty»
				;----------------------------------------------------------------
				; CHR-ROM bank #«bank7»
				;----------------------------------------------------------------
					.base $1C00
				«FOR rom : roms»
					«rom»
				«ENDFOR»
			«ENDIF»
		«ENDFOR»
	'''

	private def void prepareRoms(ProcessContext ctx, int fixedBank) {
		ctx.prgRoms.computeIfAbsent(fixedBank, [new LinkedHashMap]).putAll(ctx.prgRoms.remove(null) ?: emptyMap)
		ctx.dmcRoms.computeIfAbsent(fixedBank, [new LinkedHashMap]).putAll(ctx.dmcRoms.remove(null) ?: emptyMap)
		ctx.chrRoms.computeIfAbsent(0, [new LinkedHashMap]).putAll(ctx.chrRoms.remove(null) ?: emptyMap)
		ctx.methodsByBank.computeIfAbsent(fixedBank, [new HashMap]).putAll(ctx.methodsByBank.remove(null) ?: emptyMap)
	}

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
