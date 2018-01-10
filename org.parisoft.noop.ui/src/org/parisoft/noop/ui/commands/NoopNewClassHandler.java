package org.parisoft.noop.ui.commands;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.commands.IHandler;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.jface.wizard.WizardDialog;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.ui.IWorkbenchWindow;
import org.eclipse.ui.handlers.HandlerUtil;
import org.parisoft.noop.ui.wizards.NoopNewClassWizard;

public class NoopNewClassHandler extends AbstractHandler implements IHandler {

	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		// MessageDialog.openInformation(HandlerUtil.getActiveWorkbenchWindow(event).getShell(),
		// "Info", "Info for you");

		Shell activeShell = HandlerUtil.getActiveShell(event);
		ISelection selection = HandlerUtil.getCurrentSelection(event);
		IWorkbenchWindow workbench = HandlerUtil.getActiveWorkbenchWindow(event);
		NoopNewClassWizard wizard = new NoopNewClassWizard();
		
		if (selection instanceof IStructuredSelection && workbench != null) {
			wizard.init(workbench.getWorkbench(), (IStructuredSelection) selection);
		}
		
		new WizardDialog(activeShell, wizard).open();

		return null;
	}

}
