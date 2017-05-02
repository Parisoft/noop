package org.parisoft.noop.exception

import org.parisoft.noop.noop.Expression

class NonConstantExpressionException extends IllegalArgumentException {
	
	val Expression expression
	
	new(Expression expression) {
		this.expression = expression
	}
	
}