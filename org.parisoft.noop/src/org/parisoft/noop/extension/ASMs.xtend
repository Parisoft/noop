package org.parisoft.noop.^extension

import org.parisoft.noop.generator.CompileData
import com.google.inject.Inject
import org.parisoft.noop.noop.NoopClass

import static extension java.lang.Integer.*
import java.util.concurrent.atomic.AtomicInteger

class ASMs {

	@Inject extension Classes
	@Inject extension Members
	@Inject extension Values
	@Inject extension Statements
	@Inject extension TypeSystem
	@Inject extension Collections

	val loopThreshold = 16
	val labelCounter = new AtomicInteger

	def copyTo(CompileData orig, CompileData dest) '''
		«IF orig.immediate !== null»
			«IF dest.absolute !== null»
				«orig.copyImmediateToAbsolute(dest)»
			«ELSEIF dest.indirect !== null»
				«orig.copyImmediateToIndirect(dest)»
			«ELSEIF dest.register !== null»
				«orig.copyImmediateToRegister(dest)»
			«ENDIF»
		«ELSEIF orig.absolute !== null»
			«IF dest.absolute !== null»
				«orig.copyAbsoluteToAbsolute(dest)»
			«ELSEIF dest.indirect !== null»
				«orig.copyAbsoluteToIndirect(dest)»
			«ELSEIF dest.register !== null»
				«orig.copyAbsoluteToRegister(dest)»
			«ENDIF»
		«ELSEIF orig.indirect !== null»
			«IF dest.absolute !== null»
				«orig.copyIndirectToAbsolute(dest)»
			«ELSEIF dest.indirect !== null»
				«orig.copyIndirectToIndirect(dest)»
			«ELSEIF dest.register !== null»
				«orig.copyIndirectToRegister(dest)»
			«ENDIF»
		«ENDIF»
	'''

	private def copyImmediateToAbsolute(CompileData orig, CompileData dest) '''
		«IF dest.isIndexed»
			«noop»
				LDX «dest.index»
		«ENDIF»
		«noop»
			LDA #<(«orig.immediate»)
			STA «dest.absolute»«IF dest.isIndexed», X«ENDIF»
		«IF dest.type.sizeOf > 1»
			«IF orig.type.sizeOf > 1»
				«noop»
					LDA #>(«orig.immediate»)
			«ELSEIF orig.type.isSigned»
				«val signLabel = labelForSignedComplementEnd»
					ORA #$7F
					BMI +«signLabel»
					LDA #$00
				+«signLabel»
			«ELSE»
				«noop»
					LDA #$00
			«ENDIF»
			«noop»
				STA «dest.absolute» + 1«IF dest.isIndexed», X«ENDIF»
		«ENDIF»
	'''

	private def copyImmediateToIndirect(CompileData orig, CompileData dest) '''
		«IF dest.isIndexed»
			«noop»
				LDY «dest.index»
		«ENDIF»
		«noop»
			LDA #<(«orig.immediate»)
			STA («dest.indirect»)«IF dest.isIndexed», Y«ENDIF»
		«IF dest.type.sizeOf > 1»
			«IF orig.type.sizeOf > 1»
				«noop»
					LDA #>(«orig.immediate»)
			«ELSEIF orig.type.isSigned»
				«val signLabel = labelForSignedComplementEnd»
					ORA #$7F
					BMI +«signLabel»
					LDA #$00
				+«signLabel»
			«ELSE»
				«noop»
					LDA #$00
			«ENDIF»
			«IF dest.isIndexed»
				INY
			«ELSE»
				LDY #$01
			«ENDIF»
			«noop»
				STA «dest.indirect», Y
		«ENDIF»
	'''

	private def copyImmediateToRegister(CompileData orig, CompileData dest) '''
		«noop»
			LD«dest.register» #<(«orig.immediate»)
	'''

	private def copyAbsoluteToAbsolute(CompileData orig, CompileData dest) '''
		«IF dest.type.sizeOf < loopThreshold»
			«FOR i : 0 ..< Math::min(orig.type.sizeOf, dest.type.sizeOf)»
				«noop»
					«IF orig.isIndexed»
						LDY «orig.index»
					«ENDIF»
					«IF dest.isIndexed»
						LDX «dest.index»
					«ENDIF»
					LDA «orig.absolute»«IF i > 0» + «i»«ENDIF»«IF orig.isIndexed», Y«ENDIF»
					STA «dest.absolute»«IF i > 0» + «i»«ENDIF»«IF dest.isIndexed», X«ENDIF»
			«ENDFOR»
			«IF orig.type.sizeOf < dest.type.sizeOf»
				«IF orig.type.isSigned»
					«val signLabel = labelForSignedComplementEnd»
						ORA #$7F
						BMI +«signLabel»
						LDA #$00
					+«signLabel»
				«ELSE»
					«noop»
						LDA #$00
				«ENDIF»
			«ENDIF»
			«FOR i : orig.type.sizeOf ..< dest.type.sizeOf»
				«noop»
					STA «dest.absolute»«IF i > 0» + «i»«ENDIF»«IF dest.isIndexed», X«ENDIF»
			«ENDFOR»
		«ELSE»
			«val minSize = '''#«Math::min(orig.type.sizeOf, dest.type.sizeOf).toHex»'''»
			«val copyLoop = labelForCopyLoop»
			«IF orig.isIndexed && dest.isIndexed»
				«noop»
					CLC
					LDA «orig.index»
					ADC «minSize»
					TAY «orig.index»
					CLC
					LDA «dest.index»
					ADC «minSize»
					TAX «dest.index»
				-«copyLoop»
					DEY
					DEX
					LDA «orig.absolute», Y
					STA «dest.absolute», X
					CPY «orig.index»
					BNE -«copyLoop»
			«ELSEIF orig.isIndexed || dest.isIndexed»
				«noop»
					CLC
					LDA «IF orig.isIndexed»«orig.index»«ELSE»«dest.index»«ENDIF»
					ADC «minSize» - 1
					TAY
					LDX «minSize» - 1
				-«copyLoop»
					LDA «orig.absolute»«IF orig.isIndexed», Y«ELSE», X«ENDIF»
					STA «dest.absolute»«IF dest.isIndexed», Y«ELSE», X«ENDIF»
					DEY
					DEX
					BPL -«copyLoop»
			«ELSE»
				«noop»
					LDX «minSize» - 1
				-«copyLoop»
					LDA «orig.absolute», X
					STA «dest.absolute», X
					DEX
					BPL -«copyLoop»
			«ENDIF»
		«ENDIF»
	'''

	private def copyAbsoluteToIndirect(CompileData orig, CompileData dest) '''
		«IF dest.type.sizeOf < loopThreshold»
			«FOR i : 0 ..< Math::min(orig.type.sizeOf, dest.type.sizeOf)»
				«noop»
					«IF orig.isIndexed»
						LDX «orig.index»
					«ENDIF»
					«IF dest.isIndexed»
						LDY «dest.index»
					«ENDIF»
					LDA «orig.absolute»«IF i > 0» + «i»«ENDIF»«IF orig.isIndexed», X«ENDIF»
					STA («dest.indirect»)«IF dest.isIndexed», Y«ENDIF»
					«IF dest.isIndexed»
						INY
					«ENDIF»
			«ENDFOR»
			«IF orig.type.sizeOf < dest.type.sizeOf»
				«IF orig.type.isSigned»
					«val signLabel = labelForSignedComplementEnd»
						ORA #$7F
						BMI +«signLabel»
						LDA #$00
					+«signLabel»
				«ELSE»
					«noop»
						LDA #$00
				«ENDIF»
			«ENDIF»
			«FOR i : orig.type.sizeOf ..< dest.type.sizeOf»
				«noop»
					STA («dest.indirect»)«IF dest.isIndexed», Y«ENDIF»
					«IF dest.isIndexed»
						INY
					«ENDIF»
			«ENDFOR»
		«ELSE»
			«val minSize = '''#«Math::min(orig.type.sizeOf, dest.type.sizeOf).toHex»'''»
			«val copyLoop = labelForCopyLoop»
			«IF orig.isIndexed && dest.isIndexed»
				«noop»
					CLC
					LDA «orig.index»
					ADC «minSize»
					TAX «orig.index»
					CLC
					LDA «dest.index»
					ADC «minSize»
					TAY «dest.index»
				-«copyLoop»
					DEY
					DEX
					LDA «orig.absolute», X
					STA («dest.indirect»), Y
					CPX «orig.index»
					BNE -«copyLoop»
			«ELSEIF orig.isIndexed || dest.isIndexed»
				«noop»
					CLC
					LDA «IF orig.isIndexed»«orig.index»«ELSE»«dest.index»«ENDIF»
					ADC «minSize» - 1
					TAX
					LDY «minSize» - 1
				-«copyLoop»
					LDA «orig.absolute»«IF orig.isIndexed», X«ELSE», Y«ENDIF»
					STA («dest.indirect»«IF dest.isIndexed», X)«ELSE»), Y«ENDIF»
					DEX
					DEY
					BPL -«copyLoop»
			«ELSE»
				«noop»
					LDY «minSize» - 1
				-«copyLoop»
					LDA «orig.absolute», Y
					STA («dest.indirect»), Y
					DEY
					BPL -«copyLoop»
			«ENDIF»
		«ENDIF»
	'''

	private def copyAbsoluteToRegister(CompileData orig, CompileData dest) '''
		«noop»
			«IF orig.isIndexed»
				LDX «orig.index»
				LDA «orig.absolute», X
				«IF dest.register != 'A'»
					TA«dest.register»
				«ENDIF»
			«ELSE»
				LD«dest.register» «orig.absolute»
			«ENDIF»
	'''

	private def copyIndirectToAbsolute(CompileData orig, CompileData dest) '''
		«IF dest.type.sizeOf < loopThreshold»
			«FOR i : 0 ..< Math::min(orig.type.sizeOf, dest.type.sizeOf)»
				«noop»
					«IF orig.isIndexed»
						LDY «orig.index»
					«ENDIF»
					«IF dest.isIndexed»
						LDX «dest.index»
					«ENDIF»
					LDA («orig.indirect»)«IF orig.isIndexed», Y«ENDIF»
					STA «dest.absolute»«IF i > 0» + «i»«ENDIF»«IF dest.isIndexed», X«ENDIF»
					«IF orig.isIndexed»
						INY
					«ENDIF»
			«ENDFOR»
			«IF orig.type.sizeOf < dest.type.sizeOf»
				«IF orig.type.isSigned»
					«val signLabel = labelForSignedComplementEnd»
						ORA #$7F
						BMI +«signLabel»
						LDA #$00
					+«signLabel»
				«ELSE»
					«noop»
						LDA #$00
				«ENDIF»
			«ENDIF»
			«FOR i : orig.type.sizeOf ..< dest.type.sizeOf»
				«noop»
					STA «dest.absolute»«IF i > 0» + «i»«ENDIF»«IF dest.isIndexed», X«ENDIF»
			«ENDFOR»
		«ELSE»
			«val minSize = '''#«Math::min(orig.type.sizeOf, dest.type.sizeOf).toHex»'''»
			«val copyLoop = labelForCopyLoop»
			«IF orig.isIndexed && dest.isIndexed»
				«noop»
					CLC
					LDA «orig.index»
					ADC «minSize»
					TAY «orig.index»
					CLC
					LDA «dest.index»
					ADC «minSize»
					TAX «dest.index»
				-«copyLoop»
					DEY
					DEX
					LDA («orig.indirect»), Y
					STA «dest.absolute», X
					CPY «orig.index»
					BNE -«copyLoop»
			«ELSEIF orig.isIndexed || dest.isIndexed»
				«noop»
					CLC
					LDA «IF orig.isIndexed»«orig.index»«ELSE»«dest.index»«ENDIF»
					ADC «minSize» - 1
					TAX
					LDY «minSize» - 1
				-«copyLoop»
					LDA («orig.indirect»«IF orig.isIndexed», X)«ELSE»), Y«ENDIF»
					STA «dest.absolute»«IF dest.isIndexed», X«ELSE», Y«ENDIF»
					DEX
					DEY
					BPL -«copyLoop»
			«ELSE»
				«noop»
					LDY «minSize» - 1
				-«copyLoop»
					LDA («orig.indirect»), Y
					STA «dest.absolute», Y
					DEY
					BPL -«copyLoop»
			«ENDIF»
		«ENDIF»
	'''

	private def copyIndirectToIndirect(CompileData orig, CompileData dest) '''
		«IF dest.type.sizeOf < loopThreshold»
			«FOR i : 0 ..< Math::min(orig.type.sizeOf, dest.type.sizeOf)»
				«noop»
					«IF orig.isIndexed»
						LDX «orig.index»
					«ENDIF»
					«IF dest.isIndexed»
						LDY «dest.index»
					«ENDIF»
					LDA («orig.indirect»«IF orig.isIndexed», X«ENDIF»)
					STA («dest.indirect»)«IF dest.isIndexed», Y«ENDIF»
					«IF orig.isIndexed»
						INX
					«ENDIF»
					«IF dest.isIndexed»
						INY
					«ENDIF»
			«ENDFOR»
			«IF orig.type.sizeOf < dest.type.sizeOf»
				«IF orig.type.isSigned»
					«val signLabel = labelForSignedComplementEnd»
						ORA #$7F
						BMI +«signLabel»
						LDA #$00
					+«signLabel»
				«ELSE»
					«noop»
						LDA #$00
				«ENDIF»
			«ENDIF»
			«FOR i : orig.type.sizeOf ..< dest.type.sizeOf»
				«noop»
					STA («dest.indirect»)«IF dest.isIndexed», Y«ENDIF»
					«IF dest.isIndexed»
						INY
					«ENDIF»
			«ENDFOR»
		«ELSE»
			«val minSize = '''#«Math::min(orig.type.sizeOf, dest.type.sizeOf).toHex»'''»
			«val copyLoop = labelForCopyLoop»
			«IF orig.isIndexed && dest.isIndexed»
				«noop»
					CLC
					LDA «orig.index»
					ADC «minSize»
					TAX «orig.index»
					CLC
					LDA «dest.index»
					ADC «minSize»
					TAY «dest.index»
				-«copyLoop»
					DEY
					DEX
					LDA («orig.indirect», X)
					STA («dest.indirect»), Y
					CPX «orig.index»
					BNE -«copyLoop»
			«ELSEIF orig.isIndexed || dest.isIndexed»
				«noop»
					CLC
					LDA «IF orig.isIndexed»«orig.index»«ELSE»«dest.index»«ENDIF»
					ADC «minSize» - 1
					TAX
					LDY «minSize» - 1
				-«copyLoop»
					LDA («orig.indirect»«IF orig.isIndexed», X)«ELSE»), Y«ENDIF»
					STA («dest.indirect»«IF dest.isIndexed», X)«ELSE»), Y«ENDIF»
					DEX
					DEY
					BPL -«copyLoop»
			«ELSE»
				«noop»
					LDY «minSize» - 1
				-«copyLoop»
					LDA («orig.indirect»), Y
					STA («dest.indirect»), Y
					DEY
					BPL -«copyLoop»
			«ENDIF»
		«ENDIF»
	'''

	private def copyIndirectToRegister(CompileData orig, CompileData dest) '''
		«noop»
			«IF orig.isIndexed»
				LDY «orig.index»
			«ENDIF»
			LDA («orig.indirect»)«IF orig.isIndexed», Y«ENDIF»
			«IF dest.register != 'A'»
				TA«dest.register»
			«ENDIF»
	'''

	def pointTo(CompileData orig, CompileData dest) '''
		«IF orig.absolute !== null && dest.indirect !== null»
			«orig.pointAbsoluteToIndirect(dest)»
		«ELSEIF orig.indirect !== null && dest.indirect !== null»
			«orig.pointIndirectToIndirect(dest)»
		«ENDIF»
	'''

	private def pointAbsoluteToIndirect(CompileData orig, CompileData dest) '''
		«noop»
			LDA #<(«orig.absolute»)
			«IF orig.isIndexed»
				CLC
				ADC «orig.index»
			«ENDIF»
			STA «dest.indirect»
			LDA #>(«orig.absolute»)
			«IF orig.isIndexed»
				ADC #$00
			«ENDIF»
			STA «dest.indirect» + 1
	'''

	private def pointIndirectToIndirect(CompileData orig, CompileData dest) '''
		«noop»
			LDA «orig.indirect»
			«IF orig.isIndexed»
				CLC
				ADC «orig.index»
			«ENDIF»
			STA «dest.indirect»
			LDA «orig.indirect» + 1
			«IF orig.isIndexed»
				ADC #$00
			«ENDIF»
			STA «dest.indirect» + 1
	'''

	private def labelForSignedComplementEnd() {
		'''signedComplementEnd«labelCounter.andIncrement»:'''
	}

	private def labelForCopyLoop() {
		'''copyLoop«labelCounter.andIncrement»:'''
	}

	private def noop() {
	}
}
