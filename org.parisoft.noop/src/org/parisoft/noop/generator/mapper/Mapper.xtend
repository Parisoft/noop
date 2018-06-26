package org.parisoft.noop.generator.mapper

import org.parisoft.noop.generator.alloc.AllocContext
import org.parisoft.noop.generator.process.ProcessContext

abstract class Mapper {

	def CharSequence compile(ProcessContext ctx)
	
	def CharSequence compile(AllocContext ctx)

	protected def toHexString(int value) {
		value.toHexString(2)
	}

	protected def toHexString(int value, int len) {
		var string = Integer.toHexString(value).toUpperCase

		while (string.length < len) {
			string = '0' + string
		}

		return '$' + string
	}

	protected def void noop() {
	}

}
