package utils

import org.eclipse.ui.console.ConsolePlugin
import org.eclipse.ui.console.MessageConsole
import org.eclipse.ui.console.IOConsoleOutputStream
import org.eclipse.swt.graphics.Color
import org.eclipse.swt.widgets.Display

class Consoles {

	static var IOConsoleOutputStream defaultOutputStream
	static var IOConsoleOutputStream defaultErrorStream

	static def getDefaultOutputStream() {
		if (defaultOutputStream === null) {
			synchronized (Consoles) {
				if (defaultOutputStream === null) {
					defaultOutputStream = instance.newOutputStream
				}
			}
		}

		defaultOutputStream
	}

	static def getDefaultErrorStream() {
		if (defaultErrorStream === null) {
			synchronized (Consoles) {
				if (defaultErrorStream === null) {
					defaultErrorStream = instance.newOutputStream => [
						color = new Color(Display::current ?: Display::^default, 255, 0, 0)
					]
				}
			}
		}

		defaultErrorStream
	}

	static def getInstance() {
		val consoleManager = ConsolePlugin::^default.consoleManager
		consoleManager.consoles.filter(MessageConsole).findFirst[name == 'NOOP'] ?: (new MessageConsole('NOOP', null) =>
			[consoleManager.addConsoles(newArrayList(it))])
	}
}
