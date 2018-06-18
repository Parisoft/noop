package org.parisoft.noop.generator

class ASM {
	
	val String asmFilename;
	val String binFilename;
	val String lstFilename;
	val String content;
	
	new(String name, String content) {
		this.asmFilename = '''«name».asm'''
		this.binFilename = '''«name».nes'''
		this.lstFilename = '''«name».lst'''
		this.content = content
	}
	
	def getAsmFileName() {
		asmFilename
	}
	
	def getBinFileName() {
		binFilename
	}
	
	def getLstFileName() {
		lstFilename
	}
	
	def getContent() {
		content
	}
}