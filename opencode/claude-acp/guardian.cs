using System;
using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class ACPJobGuardian
{
    [StructLayout(LayoutKind.Sequential)]
    private struct BasicLimits
    {
        public long ProcessTime, JobTime;
        public uint Flags;
        public UIntPtr MinWorkingSet, MaxWorkingSet;
        public uint ActiveProcessLimit;
        public UIntPtr Affinity;
        public uint PriorityClass, SchedulingClass;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct IoCounters
    {
        public ulong ReadOperations, WriteOperations, OtherOperations, ReadBytes, WriteBytes, OtherBytes;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct ExtendedLimits
    {
        public BasicLimits Basic;
        public IoCounters Io;
        public UIntPtr ProcessMemory, JobMemory, PeakProcessMemory, PeakJobMemory;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct Accounting
    {
        public long UserTime, KernelTime, PeriodUserTime, PeriodKernelTime;
        public uint PageFaults, TotalProcesses, ActiveProcesses, TerminatedProcesses;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct StartupInfo
    {
        public uint Size;
        public string Reserved, Desktop, Title;
        public uint X, Y, XSize, YSize, XChars, YChars, Fill, Flags;
        public ushort ShowWindow, ReservedSize;
        public IntPtr ReservedData, Input, Output, Error;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct ProcessInfo
    {
        public IntPtr Process, Thread;
        public uint ProcessId, ThreadId;
    }

    [DllImport("kernel32.dll", SetLastError = true)] private static extern IntPtr CreateJobObject(IntPtr attributes, string name);
    [DllImport("kernel32.dll", SetLastError = true)] private static extern bool SetInformationJobObject(IntPtr job, int kind, ref ExtendedLimits info, uint size);
    [DllImport("kernel32.dll", SetLastError = true)] private static extern bool QueryInformationJobObject(IntPtr job, int kind, out Accounting info, uint size, IntPtr returned);
    [DllImport("kernel32.dll", SetLastError = true)] private static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);
    [DllImport("kernel32.dll", SetLastError = true)] private static extern bool TerminateJobObject(IntPtr job, uint code);
    [DllImport("kernel32.dll", SetLastError = true)] private static extern bool TerminateProcess(IntPtr process, uint code);
    [DllImport("kernel32.dll", SetLastError = true)] private static extern uint ResumeThread(IntPtr thread);
    [DllImport("kernel32.dll", SetLastError = true)] private static extern uint WaitForSingleObject(IntPtr handle, uint timeout);
    [DllImport("kernel32.dll", SetLastError = true)] private static extern IntPtr OpenProcess(uint access, bool inherit, uint processId);
    [DllImport("kernel32.dll", SetLastError = true)] private static extern uint WaitForMultipleObjects(uint count, IntPtr[] handles, bool waitAll, uint timeout);
    [DllImport("kernel32.dll", SetLastError = true)] private static extern bool GetExitCodeProcess(IntPtr process, out uint code);
    [DllImport("kernel32.dll", SetLastError = true)] private static extern bool CloseHandle(IntPtr handle);
    [DllImport("kernel32.dll")] private static extern IntPtr GetCurrentProcess();
    [DllImport("kernel32.dll")] private static extern IntPtr GetStdHandle(int kind);
    [DllImport("kernel32.dll", SetLastError = true)] private static extern bool DuplicateHandle(IntPtr source, IntPtr handle, IntPtr target, out IntPtr copy, uint access, bool inherit, uint options);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CreateProcess(string application, StringBuilder commandLine, IntPtr processAttributes, IntPtr threadAttributes, bool inheritHandles, uint flags, IntPtr environment, string cwd, ref StartupInfo startup, out ProcessInfo process);

    private static void Check(bool success, string operation)
    {
        if (!success) throw new Win32Exception(Marshal.GetLastWin32Error(), operation);
    }

    private static IntPtr Inherit(int kind)
    {
        IntPtr result;
        var current = GetCurrentProcess();
        Check(DuplicateHandle(current, GetStdHandle(kind), current, out result, 0, true, 2), "Duplicate stdio handle");
        return result;
    }

    public static int Run(string commandLine, string cwd, uint parentPid)
    {
        IntPtr job = IntPtr.Zero;
        IntPtr parent = IntPtr.Zero;
        var process = new ProcessInfo();
        var startup = new StartupInfo();
        bool assigned = false;
        try
        {
            parent = OpenProcess(0x00100000, false, parentPid); // SYNCHRONIZE
            Check(parent != IntPtr.Zero, "OpenProcess owning parent");
            uint parentState = WaitForSingleObject(parent, 0);
            Check(parentState == 0 || parentState == 258, "Check owning parent lifetime");
            if (parentState == 0) return 1;
            job = CreateJobObject(IntPtr.Zero, null);
            Check(job != IntPtr.Zero, "CreateJobObject");
            var limits = new ExtendedLimits();
            limits.Basic.Flags = 0x2000; // JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
            Check(SetInformationJobObject(job, 9, ref limits, (uint)Marshal.SizeOf(limits)), "SetInformationJobObject");
            startup.Size = (uint)Marshal.SizeOf(startup);
            startup.Flags = 0x100;
            startup.Input = Inherit(-10);
            startup.Output = Inherit(-11);
            startup.Error = Inherit(-12);
            // No adapter code runs until ownership is assigned. The job handle
            // is not inheritable: only this guardian keeps the lifetime open.
            Check(CreateProcess(null, new StringBuilder(commandLine), IntPtr.Zero, IntPtr.Zero, true, 0x08000004, IntPtr.Zero, cwd, ref startup, out process), "CreateProcess suspended");
            Check(AssignProcessToJobObject(job, process.Process), "AssignProcessToJobObject");
            assigned = true;
            Check(ResumeThread(process.Thread) != uint.MaxValue, "ResumeThread");
            uint completed = WaitForMultipleObjects(2, new IntPtr[] { process.Process, parent }, false, uint.MaxValue);
            Check(completed == 0 || completed == 1, "WaitForMultipleObjects adapter or owning parent");
            uint exitCode = 1;
            if (completed == 0) Check(GetExitCodeProcess(process.Process, out exitCode), "GetExitCodeProcess");
            Check(TerminateJobObject(job, 1), "TerminateJobObject descendants");
            var deadline = Stopwatch.StartNew();
            while (true)
            {
                Accounting accounting;
                Check(QueryInformationJobObject(job, 1, out accounting, (uint)Marshal.SizeOf(typeof(Accounting)), IntPtr.Zero), "QueryInformationJobObject");
                if (accounting.ActiveProcesses == 0) break;
                if (deadline.ElapsedMilliseconds > 3000) throw new Exception("Owned job did not become empty");
                Thread.Sleep(10);
            }
            return unchecked((int)exitCode);
        }
        finally
        {
            if (!assigned && process.Process != IntPtr.Zero) TerminateProcess(process.Process, 126);
            if (job != IntPtr.Zero) CloseHandle(job);
            if (parent != IntPtr.Zero) CloseHandle(parent);
            if (process.Thread != IntPtr.Zero) CloseHandle(process.Thread);
            if (process.Process != IntPtr.Zero) CloseHandle(process.Process);
            if (startup.Input != IntPtr.Zero) CloseHandle(startup.Input);
            if (startup.Output != IntPtr.Zero) CloseHandle(startup.Output);
            if (startup.Error != IntPtr.Zero) CloseHandle(startup.Error);
        }
    }
}
