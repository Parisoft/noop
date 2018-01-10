package org.parisoft.noop.preferences;

import org.eclipse.core.runtime.preferences.IEclipsePreferences;
import org.eclipse.core.runtime.preferences.InstanceScope;

/**
 * Constant definitions for plug-in preferences
 */
public class NoopPreferences {

	public static final String P_PATH_TO_EMULATOR = "P_PATH_TO_EMULATOR";

	public static String getPathToEmulator() {
		return getPreferenceStore().get(P_PATH_TO_EMULATOR, "");
	}
	
	public static IEclipsePreferences getPreferenceStore() {
		return InstanceScope.INSTANCE.getNode("org.parisoft.noop");
	}
}
