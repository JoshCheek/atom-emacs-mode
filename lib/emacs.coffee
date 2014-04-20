{Range, Point} = require 'atom'
SwitchBufferView = require './switch-buffer-view'
FindFileView = require './find-file-view.coffee'
EmacsMark = require './mark'


module.exports =
  activate: (state) ->
    atom.workspaceView.command 'emacs:find-file', => @findFile()
    atom.workspaceView.command 'emacs:hide-tabs', (event, value) => @hideTabs(value)
    atom.workspaceView.command 'emacs:hide-sidebar', (event, value) => @hideSidebar(value)
    atom.workspaceView.command 'emacs:use-emacs-cursor', (event, value) => @useEmacsCursor(value)

    require './config'
    require './init-kill-ring'

    atom.workspaceView.eachEditorView (editorView) =>
      new EmacsMark(editorView)

      editorView.command 'emacs:switch-buffer', => @switchBuffer()

      editorView.command 'emacs:open-line', => @openLine(editorView)
      editorView.command 'emacs:forward-word', => @forwardWord(editorView)
      editorView.command 'emacs:backward-word', => @backwardWord(editorView)
      editorView.command 'emacs:recenter', => @recenter(editorView)
      editorView.command 'emacs:clear-selection', => @clearSelection(editorView)

      editorView.on 'core:cancel', => editorView.trigger('emacs:clear-selection')

  deactivate: ->

  serialize: ->

  switchBuffer: ->
    new SwitchBufferView()

  findFile: ->
    new FindFileView()

  openLine: (editorView) ->
    editor = editorView.getEditor()
    pos = editor.getCursorBufferPosition()
    editor.insertNewline()
    editor.setCursorBufferPosition(pos)

  clearSelection: (editorView) ->
    editor = editorView.getEditor()
    sel.clear() for sel in editor.getSelections()

  _getChar: (editor, row, col) ->
    editor.getTextInBufferRange(
      new Range(new Point(row, col), new Point(row, col + 1)))

  forwardWord: (editorView) ->
    editor = editorView.getEditor()
    cursors = editor.getCursors()
    for cursor in cursors
      while (true)
        before = cursor.getBufferPosition()
        cursor.moveToEndOfWord()
        pos = cursor.getBufferPosition()

        break if before.isEqual pos
        break if @_getChar(editor, pos.row, pos.column - 1).match(/[0-9a-zA-Z]/)

  backwardWord: (editorView) ->
    editor = editorView.getEditor()
    cursors = editor.getCursors()
    for cursor in cursors
      while (true)
        before = cursor.getBufferPosition()
        cursor.moveToBeginningOfWord()
        pos = cursor.getBufferPosition()

        break if before.isEqual pos
        break if @_getChar(editor, pos.row, pos.column).match(/[0-9a-zA-Z]/)

  hideTabs: (isHide) ->
    (if isHide then pane.find('.tab-bar').hide() else pane.find('.tab-bar').show()) for pane in atom.workspaceView.getPanes()

  hideSidebar: (isHide) ->
    panel = atom.workspaceView.parent().find('.tool-panel')
    if isHide then panel.hide() else panel.show()

  useEmacsCursor: (useEmacs) ->
    atom.workspaceView.eachEditorView (editorView) ->
      if useEmacs
        editorView.addClass 'emacs-cursor'
      else
        editorView.removeClass 'emacs-cursor'

  recenter: (editorView) ->
    cursorPos = editorView.getEditor().getCursorScreenPosition()
    rows = editorView.getPageRows()

    topRow = cursorPos.row - parseInt(rows / 2)
    topPos = editorView.getEditor().clipScreenPosition [topRow, 0]

    pix = editorView.pixelPositionForScreenPosition topPos
    editorView.scrollTop(pix.top)
