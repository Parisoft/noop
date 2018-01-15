package utils

import org.eclipse.swt.graphics.Color
import org.eclipse.swt.widgets.Display
import org.eclipse.ui.console.ConsolePlugin
import org.eclipse.ui.console.MessageConsole
import com.google.inject.Singleton
import org.parisoft.noop.consoles.Console

@Singleton
class NoopConsole implements Console {

	def getConsole() {
		val consoleManager = ConsolePlugin::^default.consoleManager
		consoleManager.consoles.filter(MessageConsole).findFirst[name == 'NOOP'] ?: (new MessageConsole('NOOP', null) =>
			[consoleManager.addConsoles(newArrayList(it))])
	}

	override newErrStream() {
		console.newMessageStream => [color = new Color(Display::current ?: Display::^default, 255, 0, 0)]
	}

	override newOutStream() {
		console.newMessageStream
	}

}
