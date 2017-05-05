package org.parisoft.noop.exception

import org.parisoft.noop.noop.Expression

class InvalidExpressionException extends ExpressionException {
	
	val Expression expression
	
	new(Expression expression) {
		this.expression = expression
	}
	
}