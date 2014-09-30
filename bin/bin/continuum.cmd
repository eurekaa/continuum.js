@IF EXIST "%~dp0\node.exe" (
  "%~dp0\node.exe"  "%~dp0continuum" %*
) ELSE (
  node  "%~dp0continuum" %*
)