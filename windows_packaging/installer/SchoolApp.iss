; Inno Setup script for School App (portable -> installer)
#define AppName "School App"
#define AppVersion "1.0.0"
#define AppPublisher "Your School"
#define AppExeName "flutter_app.exe"

[Setup]
AppId={{A0E34F05-3DB9-4DD0-9C22-0E7E90D690A5}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
; Install into user-local folder to avoid write permission issues for SQLite
DefaultDirName={localappdata}\{#AppName}
DefaultGroupName={#AppName}
OutputDir=..\dist
OutputBaseFilename=SchoolApp_Setup
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
DisableProgramGroupPage=yes
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "..\dist\SchoolApp_Portable\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\start.bat"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\start.bat"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked
