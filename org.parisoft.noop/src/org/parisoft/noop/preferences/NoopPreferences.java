package org.parisoft.noop.preferences;

import org.eclipse.core.runtime.preferences.IEclipsePreferences;
import org.eclipse.core.runtime.preferences.InstanceScope;

/**
 * Constant definitions for plug-in preferences
 */
public class NoopPreferences {

	public static final String P_EMULATOR_PATH = "P_EMULATOR_PATH";
	public static final String P_EMULATOR_OPTS = "P_EMULATOR_OPTS";

	public static String getEmulatorPath() {
		return getPreferenceStore().get(P_EMULATOR_PATH, "");
	}
	
	public static String getEmulatorOptions() {
		return getPreferenceStore().get(P_EMULATOR_OPTS, "");
	}
	
	public static IEclipsePreferences getPreferenceStore() {
		return InstanceScope.INSTANCE.getNode("org.parisoft.noop");
	}
}
