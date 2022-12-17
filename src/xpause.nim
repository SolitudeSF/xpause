import std/[strformat, strutils, posix]
import xcb/xcb

type
  ProcessStatus = enum
    Running, Stopped, Defunct, UninterruptibleSleep, InterruptibleSleep, Dead

const
  activeWindowAtomName = "_NET_ACTIVE_WINDOW"
  windowPidAtomName = "_NET_WM_PID"

func parseProcessStatus(c: char): ProcessStatus =
  case c
  of 'R': Running
  of 'T': Stopped
  of 'Z': Defunct
  of 'D': UninterruptibleSleep
  of 'S': InterruptibleSleep
  of 'X': Dead
  else: raise newException(ValueError, &"Unknown process status: {c}")

proc getPidStatus(pid: uint32): ProcessStatus =
  let
    statusText = readFile &"/proc/{pid}/status"
    stateIdx = statusText.find("\nState:") + 8

  result = statusText[stateIdx].parseProcessStatus

let
  conn = xcbConnect(nil, nil)
  screen = conn.getSetup.rootsIterator.data[0].addr
  window = screen.root
  activeWindowAtom = conn.reply(conn.internAtom(true, activeWindowAtomName.len, activeWindowAtomName), nil).atom
  activeWindowReply = conn.reply(conn.getProperty(0, window, activeWindowAtom, xcbAtomWindow.XcbAtom, 0, 1), nil)
  activeWindow = cast[ptr XcbWindow](activeWindowReply.value)[]
  pidAtom = conn.reply(conn.internAtom(true, windowPidAtomName.len, windowPidAtomName), nil).atom
  pidReply = conn.reply(conn.getProperty(0, activeWindow, pidAtom, xcbAtomCardinal.XcbAtom, 0, 1), nil)
  pid = cast[ptr uint32](pidReply.value)[]
  pidStatus = getPidStatus pid

case pidStatus
of Running, InterruptibleSleep:
  discard kill(pid.Pid, SIGSTOP)
of Stopped:
  discard kill(pid.Pid, SIGCONT)
else:
  discard
