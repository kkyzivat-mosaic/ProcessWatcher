using System;
using WMI.Win32;

class MainProgram
{
    static void procWatcher_ProcessCreated(WMI.Win32.Win32_Process process)
    {
        Console.Write("Created " + process.Name + " " + process.ProcessId +"  "+ "DateTime:"+DateTime.Now + "\n");
    }

    static void procWatcher_ProcessDeleted(WMI.Win32.Win32_Process process)
    {
        Console.Write("Deleted " + process.Name + " " + process.ProcessId +"  "+ "DateTime:"+DateTime.Now + "\n");
    }

    static void procWatcher_ProcessModified(WMI.Win32.Win32_Process process)
    {
        Console.Write("Modified " + process.Name + " " + process.ProcessId +"  "+ "DateTime:"+DateTime.Now + "\n");
    }

    static void Main()
    {
        Console.WriteLine("Process Watcher");
        string[] processesToWatch = {"lightroom.exe", "notepad.exe", "mspaint.exe"};
        MultiProcessWatcher processWatcher = new MultiProcessWatcher( processesToWatch );

        processWatcher.RegisterProcessCreated(new ProcessEventHandler(procWatcher_ProcessCreated));
        processWatcher.RegisterProcessDeleted(new ProcessEventHandler(procWatcher_ProcessDeleted));
        processWatcher.RegisterProcessModified(new ProcessEventHandler(procWatcher_ProcessModified));
        processWatcher.Start();

        bool shuttingDown = false;
        while ( !shuttingDown )
        {
            ConsoleKeyInfo cki = Console.ReadKey();
            shuttingDown = cki.Key == ConsoleKey.Escape;
        }

        processWatcher.Stop();
    }
}
