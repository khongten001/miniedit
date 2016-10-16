unit mneLuaProjectFrames;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynEdit, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, EditorEngine, SelectFiles, mneLuaClasses;

type

  { TLuaProjectFrame }

  TLuaProjectFrame = class(TFrame, IEditorOptions, IEditorProjectFrame)
    ExpandPathsChk1: TCheckBox;
    ExpandPathsChk2: TCheckBox;
  private
    Options: TLuaProjectOptions;
  protected
    function GetProject: TEditorProject;
  public
    FProject: TEditorProject;
    procedure Apply;
    procedure Retrieve;
  end;

implementation

{$R *.lfm}

{ TLuaProjectFrame }

function TLuaProjectFrame.GetProject: TEditorProject;
begin
  Result := FProject;
end;

procedure TLuaProjectFrame.Apply;
begin
end;

procedure TLuaProjectFrame.Retrieve;
begin
  Options := (FProject.Options as TLuaProjectOptions);
end;

end.
