Option Explicit

Dim arguments
Dim command
Dim currentDirectory
Dim exitCode
Dim i
Dim shell
Dim startIndex

Set arguments = WScript.Arguments
Set shell = CreateObject("WScript.Shell")

If arguments.Count = 0 Then
  WScript.Quit 64
End If

currentDirectory = ""
startIndex = 0

If arguments.Count >= 3 Then
  If LCase(arguments(0)) = "--cwd" Then
    currentDirectory = arguments(1)
    startIndex = 2
  End If
End If

If startIndex >= arguments.Count Then
  WScript.Quit 64
End If

If currentDirectory <> "" Then
  shell.CurrentDirectory = currentDirectory
End If

command = ""

For i = startIndex To arguments.Count - 1
  If command <> "" Then
    command = command & " "
  End If

  command = command & QuoteArgument(arguments(i))
Next

exitCode = shell.Run(command, 0, True)
WScript.Quit exitCode

Function QuoteArgument(ByVal value)
  Dim backslashes
  Dim character
  Dim quoted
  Dim position

  backslashes = 0
  quoted = Chr(34)

  For position = 1 To Len(value)
    character = Mid(value, position, 1)

    If character = "\" Then
      backslashes = backslashes + 1
    ElseIf character = Chr(34) Then
      quoted = quoted & String(backslashes * 2 + 1, "\") & Chr(34)
      backslashes = 0
    Else
      If backslashes > 0 Then
        quoted = quoted & String(backslashes, "\")
        backslashes = 0
      End If

      quoted = quoted & character
    End If
  Next

  If backslashes > 0 Then
    quoted = quoted & String(backslashes * 2, "\")
  End If

  QuoteArgument = quoted & Chr(34)
End Function
