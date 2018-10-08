program SysTalkC;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, SCNFEdit, CustApp
  { you can add units after this };

type

  { TSystemTalkSubtitlesEditorConsoleApplication }

  TSystemTalkSubtitlesEditorConsoleApplication = class(TCustomApplication)
  private
    procedure Execute;
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHeader;
    procedure WriteHelp; virtual;
  end;

{ TSystemTalkSubtitlesEditorApplication }

procedure TSystemTalkSubtitlesEditorConsoleApplication.Execute;
var
  CommandSwitch: Char;
  SCNFEditor: TSCNFEditor;
  InputFile, OutputFile, Path: TFileName;
  i, SectionID: Integer;

begin
  if ParamCount > 1 then
  begin
    CommandSwitch := UpCase(ParamStr(1)[1]);
    InputFile := ExpandFileName(ParamStr(2));
    Path := IncludeTrailingPathDelimiter(ExtractFilePath(InputFile));

    if ParamCount > 2 then
      OutputFile := ParamStr(3)
    else
      OutputFile := '';

    SCNFEditor := TSCNFEditor.Create;
    try
      SCNFEditor.LoadFromFile(InputFile);

      case CommandSwitch of

        // List sections
        'L':
          begin
            WriteLn('Content of ', ExtractFileName(InputFile), ':');
            for i := 0 to SCNFEditor.Sections.Count - 1 do begin
              WriteLn('  #', i, ': ', SCNFEditor.Sections[i].CharID, ' (',
                SCNFEditor.Sections[i].Subtitles.Count, ' subtitles)');
            end;
          end;

        // Extract the section id specified
        'E':
          begin
            SectionID := StrToInt(ParamStr(1)[3]);
            if OutputFile = '' then
              OutputFile := Path + IntToStr(SectionID) + '_' + SCNFEditor.Sections[SectionID].CharID + '.xml';
            Write('Exporting SCNF section #', SectionID, ' to ', OutputFile, '...');
            SCNFEditor.Sections[SectionID].Subtitles.ExportToFile(OutputFile);
            WriteLn('Done !');
          end;

        // Import the section id specified
        'I':
          begin
            SectionID := StrToInt(ParamStr(1)[3]);
            if OutputFile = '' then
              OutputFile := Path + IntToStr(SectionID) + '_' + SCNFEditor.Sections[SectionID].CharID + '.xml';
            if FileExists(OutputFile) then begin
              Write('Importing SCNF section #', SectionID, ' from ', OutputFile, '...');
              SCNFEditor.Sections[SectionID].Subtitles.ImportFromFile(OutputFile);
              SCNFEditor.Save;
              WriteLn('Done !');
            end else
              WriteLn('File not found: "', OutputFile, '"');
          end;

          // Export all sections
          'X':
            begin
              WriteLn('Exporting all SCNF sections...');
              for i := 0 to SCNFEditor.Sections.Count - 1 do begin
                Write('  #', i, ': ', SCNFEditor.Sections[i].CharID, '...');
                OutputFile := Path + IntToStr(i) + '_' + SCNFEditor.Sections[i].CharID + '.xml';
                SCNFEditor.Sections[i].Subtitles.ExportToFile(OutputFile);
                WriteLn('OK !');
              end;
              WriteLn('Done !');
            end;

          // Import all sections
          'P':
            begin
              WriteLn('Importing all SCNF sections...');
              for i := 0 to SCNFEditor.Sections.Count - 1 do begin
                Write('  #', i, ': ', SCNFEditor.Sections[i].CharID, '...');
                OutputFile := Path + IntToStr(i) + '_' + SCNFEditor.Sections[i].CharID + '.xml';
                if FileExists(OutputFile) then begin
                  SCNFEditor.Sections[i].Subtitles.ImportFromFile(OutputFile);
                  WriteLn('OK !');
                end else
                  WriteLn('FAILED !');
              end;
              SCNFEditor.Save;
              WriteLn('Done !');
            end;
      end;

    finally
      SCNFEditor.Free;
    end;

  end;
end;

procedure TSystemTalkSubtitlesEditorConsoleApplication.DoRun;
var
  ErrorMsg: String;

begin
  WriteHeader;

  // quick check parameters
  ErrorMsg := CheckOptions('h', 'help');
  if ErrorMsg <> '' then
  begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h', 'help') then
  begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  Execute;

  // stop program loop
  Terminate;
end;

constructor TSystemTalkSubtitlesEditorConsoleApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TSystemTalkSubtitlesEditorConsoleApplication.Destroy;
begin
  inherited Destroy;
end;

procedure TSystemTalkSubtitlesEditorConsoleApplication.WriteHeader;
const GetApplicationVersion = 'x.x-lazarus';
begin
  WriteLn(
      'Shenmue System Talk Subtitles Editor - v', GetApplicationVersion, ' - Console Version', sLineBreak,
      'Written by the Shentrad Team', sLineBreak
    );
end;

procedure TSystemTalkSubtitlesEditorConsoleApplication.WriteHelp;
begin
  WriteLn(
    'Usage: ', sLineBreak,
    '  ', ExeName, ' <command[=section_id]> <systalk.bin> [target.xml]', sLineBreak,
    sLineBreak,
    'Commands:', sLineBreak,
    '  l: List all SCNF sections from <systalk.bin>', sLineBreak,
    '  e: Export from [section_id] of <systalk.bin> to [target.xml]', sLineBreak,
    '  i: Import to [section_id] of <systalk.bin> from [target.xml]', sLineBreak,
    '  x: Export all SCNF sections from <systalk.bin> to <autofiles.xml>', sLineBreak,
    '  p: Import all SCNF sections from <autofiles.xml> to <systalk.bin>', sLineBreak,
    sLineBreak,
    'Example: ', sLineBreak,
    '  ', ExeName, ' e=3 systalk.bin', sLineBreak,
    '    Export the content of the third section of systalk.bin to ****.xml where', sLineBreak,
    '    ****.xml file name is calculated from the section name.'
  );
end;

var
  Application: TSystemTalkSubtitlesEditorConsoleApplication;

begin
  Application := TSystemTalkSubtitlesEditorConsoleApplication.Create(nil);
  try
    Application.Title := 'System Talk Subtitles Editor';
    Application.Run;
  finally
    Application.Free;
  end;
end.

