/**
 * Copyright 2013, Mosaic Storage Systems Inc
 */
package com.mosaic.daemon;

import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

import org.apache.log4j.Logger;

import com.google.common.collect.ImmutableMap;
import com.google.common.collect.Maps;

/**
 * An "Active Object" (POSA2) that monitors a process
 *
 * @author Keith Kyzivat (kkyzivat@mosaicarchive.com)
 */
public class LightroomProcessMonitor
{
    private static final LightroomProcessMonitor singleInstance = new LightroomProcessMonitor();

    private static final Logger log = Logger.getLogger(LightroomProcessMonitor.class);
    private List<LightroomProcessMonitorListener> listeners = new CopyOnWriteArrayList<LightroomProcessMonitorListener>();

    public static boolean isRunning(LightroomVersion lrVersion)
    {
        return nativeProcessIsRunning(lrVersion.toString());
    }

    // Enforce singleton.
    private LightroomProcessMonitor()
    {
        System.loadLibrary("lightroomprocessmonitor");
        nativeMonitorProcess();
    }

    public static LightroomProcessMonitor getInstance()
    {
        return singleInstance;
    }

    public void addProcessMonitorListener(LightroomProcessMonitorListener l)
    {
        listeners.add(l);
    }

    /**
     * Called by native code when the process is recognized as having started.
     */
    protected void processStarted(String lrVersion)
    {
        LightroomVersion version = LightroomVersion.getEnum(lrVersion);
        log.info("Process " + version + " is RUNNING");

        // Notify listeners
        for (LightroomProcessMonitorListener l : listeners)
        {
            l.processStarted(version);
        }
    }

    /**
     * Called by native code when the process is recognized as having ended
     */
    protected void processStopped(String lrVersion)
    {
        LightroomVersion version = LightroomVersion.getEnum(lrVersion);
        log.info("Process " + version + " has STOPPED");

        // Notify listeners
        for (LightroomProcessMonitorListener l : listeners)
        {
            l.processStopped(version);
        }
    }

    // On non-MacOS platforms, this string will be looked up in a table to determine
    // the platform-specific lightroom process name.
    public enum LightroomVersion
    {
        Lightroom_v3("com.adobe.Lightroom3"), Lightroom_v4("com.adobe.Lightroom4"), Lightroom_v5(
                "com.adobe.Lightroom5");

        private final String string;

        private LightroomVersion(String string)
        {
            this.string = string;
        }

        @Override
        public String toString()
        {
            return string;
        }

        public static LightroomVersion getEnum(String string)
        {
            if (!strValMap.containsKey(string))
            {
                throw new IllegalArgumentException("Unknown String Value: " + string);
            }
            return strValMap.get(string);
        }

        private static final Map<String, LightroomVersion> strValMap;
        static
        {
            final Map<String, LightroomVersion> tmpMap = Maps.newHashMap();
            for (final LightroomVersion en : LightroomVersion.values())
            {
                tmpMap.put(en.string, en);
            }
            strValMap = ImmutableMap.copyOf(tmpMap);
        }
    }

    /**
     * Native method that monitors lightroom processes for started/stopped.
     */
    private native void nativeMonitorProcess();

    /**
     * Native method that returns if specific lightroom process is running
     */
    private static native boolean nativeProcessIsRunning(String lrVersion);

    static
    {
    }
}
