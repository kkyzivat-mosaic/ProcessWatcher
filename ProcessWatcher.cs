/* ------------ Using WMI to monitor process creation, deletion and modification in .NET ------------ */
/* ----------------- http://weblogs.asp.net/whaggard/archive/2006/02/11/438006.aspx ----------------- */
/* Run csc Main.cs Process.cs ProcessWatcher.cs , then run Main.exe */

using System;
using System.ComponentModel;
using System.Collections;
using System.Globalization;
using System.Management;
using System.Collections.Generic;

namespace WMI.Win32
{
    public class MultiProcessWatcher
    {
        public List<ProcessWatcher> mProcessWatchers;

        public MultiProcessWatcher(string[] processNames)
        {
            mProcessWatchers = new List<ProcessWatcher>();
            foreach (string processName in processNames)
            {
                ProcessWatcher watcher = new ProcessWatcher(processName);
                mProcessWatchers.Add(watcher);
            }
        }

        public void RegisterProcessCreated(ProcessEventHandler handler)
        {
            foreach (ProcessWatcher watcher in mProcessWatchers)
            {
                watcher.ProcessCreated += handler;
            }
        }

        public void RegisterProcessDeleted(ProcessEventHandler handler)
        {
            foreach (ProcessWatcher watcher in mProcessWatchers)
            {
                watcher.ProcessDeleted += handler;
            }
        }

        public void RegisterProcessModified(ProcessEventHandler handler)
        {
            foreach (ProcessWatcher watcher in mProcessWatchers)
            {
                watcher.ProcessModified += handler;
            }
        }

        public void Start()
        {
            foreach (ProcessWatcher watcher in mProcessWatchers)
            {
                watcher.Start();
            }
        }

        public void Stop()
        {
            foreach (ProcessWatcher watcher in mProcessWatchers)
            {
                watcher.Stop();
            }
        }
    }

    public delegate void ProcessEventHandler(Win32_Process proc);
    public class ProcessWatcher : ManagementEventWatcher
    {
        // Process Events
        public event ProcessEventHandler ProcessCreated;
        public event ProcessEventHandler ProcessDeleted;
        public event ProcessEventHandler ProcessModified;

        // WMI WQL process query strings
        static readonly string WMI_OPER_EVENT_QUERY = @"SELECT * FROM 
__InstanceOperationEvent WITHIN 1 WHERE TargetInstance ISA 'Win32_Process'";
        static readonly string WMI_OPER_EVENT_QUERY_WITH_PROC =
            WMI_OPER_EVENT_QUERY + " and TargetInstance.Name = '{0}'";

        public ProcessWatcher()
        {
            Init(string.Empty);
        }
        public ProcessWatcher(string processName)
        {
            Init(processName);
        }
        private void Init(string processName)
        {
            this.Query.QueryLanguage = "WQL";
            if (string.IsNullOrEmpty(processName))
            {
                this.Query.QueryString = WMI_OPER_EVENT_QUERY;
            }
            else
            {
                this.Query.QueryString =
                    string.Format(WMI_OPER_EVENT_QUERY_WITH_PROC, processName);
            }

            this.EventArrived += new EventArrivedEventHandler(watcher_EventArrived);
        }
        private void watcher_EventArrived(object sender, EventArrivedEventArgs e)
        {
            string eventType = e.NewEvent.ClassPath.ClassName;
            Win32_Process proc = new 
                Win32_Process(e.NewEvent["TargetInstance"] as ManagementBaseObject);

            switch (eventType)
            {
                case "__InstanceCreationEvent":
                    if (ProcessCreated != null) ProcessCreated(proc); break;
                case "__InstanceDeletionEvent":
                    if (ProcessDeleted != null) ProcessDeleted(proc); break;
                case "__InstanceModificationEvent":
                    if (ProcessModified != null) ProcessModified(proc); break;
            }
        }

    }

    // Auto-Generated running: mgmtclassgen Win32_Process /n root\cimv2 /o WMI.Win32
    // Renaming the class from Process to Win32_Process
    //public class Win32_Process { ... }
}

/*
// Sample Usage
ProcessWatcher procWatcher = new ProcessWatcher("notepad.exe");
procWatcher.ProcessCreated += new ProcessEventHandler(procWatcher_ProcessCreated);
procWatcher.ProcessDeleted += new ProcessEventHandler(procWatcher_ProcessDeleted);
procWatcher.ProcessModified += new ProcessEventHandler(procWatcher_ProcessModified);
procWatcher.Start();

// Do Work

procWatcher.Stop();
*/
