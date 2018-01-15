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
		val stream = console.newMessageStream
		val display = Display::current ?: Display::^default

		display.asyncExec [
			stream.color = new Color(display, 255, 0, 0)
		]

		stream
	}

	override newOutStream() {
		console.newMessageStream
	}

}
